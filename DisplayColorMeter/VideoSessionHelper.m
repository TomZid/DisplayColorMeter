//
//  VideoSessionHelper.m
//  DisplayColorMeter
//
//  Created by tom.zhu on 28/08/2017.
//  Copyright © 2017 TZ. All rights reserved.
//

#import "VideoSessionHelper.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoSessionHelper () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;
}
@end

@implementation VideoSessionHelper
- (void)configSessionWithPreviewLayerSuperLayer:(CALayer*)superLayer {
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
    
    {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [_previewLayer setFrame:[UIScreen mainScreen].bounds];
        [superLayer addSublayer:_previewLayer];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

@end
