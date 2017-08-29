//
//  VideoSessionHelper.m
//  DisplayColorMeter
//
//  Created by tom.zhu on 28/08/2017.
//  Copyright © 2017 TZ. All rights reserved.
//

#import "VideoSessionHelper.h"
#import <AVFoundation/AVFoundation.h>

@interface IntermediateView : UIView @end

@implementation IntermediateView

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.layer.sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.frame = self.superview.frame;
    }];
}

@end

static IntermediateView *_temV;

@interface VideoSessionHelper () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;
    
    VideoSessionHelper_Effective _option;
}
@end

@implementation VideoSessionHelper
- (void)configSessionWithPreviewLayerSuperView:(UIView*)superView option:(VideoSessionHelper_Effective)option {
    _option = option;
    
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPreset640x480;
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status != AVAuthorizationStatusAuthorized) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:@"" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:@"" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        return;
    }
    
    //get camera
    AVCaptureDevice *videoDevice = ({
        NSArray <AVCaptureDevice*>*devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].devices;
        AVCaptureDevice *device = devices.firstObject;
        for (AVCaptureDevice *dev in devices) {
            device = (dev.position == AVCaptureDevicePositionFront) ? dev : device;
        }
        device;
    });
    
    NSError *error;
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    [_session beginConfiguration];
    //add input
    if ([_session canAddInput:videoDeviceInput]) {
        [_session addInput:videoDeviceInput];
    }
    //add output
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("com.VideoOutputQueue", NULL);
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    videoDataOutput.videoSettings = @{
                                      (__bridge id)(kCVPixelBufferPixelFormatTypeKey) : @(kCVPixelFormatType_32BGRA)
                                      };
    //AVCaptureVideoDataOutputSampleBufferDelegate
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    if ([_session canAddOutput:videoDataOutput]) {
        [_session addOutput:videoDataOutput];
    }
    AVCaptureConnection *connection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [_session commitConfiguration];
    [_session startRunning];
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_previewLayer setFrame:[UIScreen mainScreen].bounds];
    _temV = [[IntermediateView alloc] initWithFrame:superView.bounds];
    [_temV.layer addSublayer:_previewLayer];
    [superView addSubview:_temV];
    
    /*
    [superView addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:_temV attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                                [NSLayoutConstraint constraintWithItem:_temV attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                                [NSLayoutConstraint constraintWithItem:_temV attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                                [NSLayoutConstraint constraintWithItem:_temV attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeRight multiplier:1 constant:0],
                                ]];
    */
}

- (void)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    //    NSLog(@"w: %zu h: %zu bytesPerRow:%zu", width, height, bytesPerRow);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little
                                                 | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    //    UIImage *image = [UIImage imageWithCGImage:quartzImage
    //                                         scale:1.0f
    //                                   orientation:UIImageOrientationRight];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
//    _previewLayer.contents = CFBridgingRelease(image.CGImage);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        
        if (_option == vs_effective_nonmal) {
            
        }else if (_option == vs_effective_inner){
            [self imageFromSampleBuffer:sampleBuffer];
        }
        
    }
}

@end
