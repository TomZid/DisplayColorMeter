    //
//  ViewController.m
//  DisplayColorMeter
//
//  Created by tom.zhu on 28/08/2017.
//  Copyright © 2017 TZ. All rights reserved.
//

#import "CameraViewController.h"
#import "VideoSessionHelper.h"
#import <GPUImage.h>

@interface CameraViewController ()
{
    __weak IBOutlet UIView      *_colorView;
    
    __weak IBOutlet UILabel     *_redLabel;
    __weak IBOutlet UILabel     *_greenLabel;
    __weak IBOutlet UILabel     *_blueLabel;
    __weak IBOutlet UIView     *_colorHub;
    
    CGPoint __block             _anchorPoint;
    
    GPUImageVideoCamera         *_videoCamera;
    GPUImageView                *_filteredVideoView;
    GPUImageRawDataOutput       *_videoRawData;
}

@end

@implementation CameraViewController
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view removeObserver:self forKeyPath:@"frame"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [[VideoSessionHelper new] configSessionWithPreviewLayerSuperView:self.view option:1];
    [self GPUConfiguer];
    [self addObserver];
}

- (void)GPUConfiguer {
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    _videoCamera.outputImageOrientation = ({
        UIInterfaceOrientation ori = [[UIApplication sharedApplication] statusBarOrientation];
        ori;
    });
    
    _filteredVideoView = [[GPUImageView alloc] initWithFrame:({
        CGRect rect = {CGPointZero, [UIScreen mainScreen].bounds.size};
        rect;
    })];
    _filteredVideoView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [self.view addSubview:_filteredVideoView];
    [self.view bringSubviewToFront:_colorView];
    [self.view bringSubviewToFront:_colorHub];
    
    _videoRawData = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(480.0, 640.0) resultsInBGRAFormat:YES];
    __weak typeof(_videoRawData) videoRawData_ws = _videoRawData;
    typeof(self) __weak ws = self;
    typeof(self) __strong ss = ws;
    _anchorPoint = CGPointMake(480 / 2, 640 / 2);
    [_videoRawData setNewFrameAvailableBlock:^{
        GPUByteColorVector colorVector = [videoRawData_ws colorAtLocation:_anchorPoint];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ss != nil) {
                ss->_redLabel.text = [@(colorVector.red) stringValue];
                ss->_greenLabel.text = [@(colorVector.green) stringValue];
                ss->_blueLabel.text = [@(colorVector.blue) stringValue];
                
                UIColor *color = [UIColor colorWithRed:colorVector.red / 255.0f green:colorVector.green / 255.0f blue:colorVector.blue / 255.0f alpha:1];
                ss->_colorView.backgroundColor = color;
            }
        });
    }];
    
    [_videoCamera addTarget:_filteredVideoView];
    [_videoCamera addTarget:_videoRawData];
    [_videoCamera startCameraCapture];
}

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj layoutSubviews];
    }];
}

- (void)orientation:(NSNotification*)notification {
    UIInterfaceOrientation newOrientation = [[[notification userInfo] valueForKey:@"new"] integerValue];
    _videoCamera.outputImageOrientation = newOrientation;
    if (newOrientation == UIInterfaceOrientationPortrait) {
        _anchorPoint = CGPointMake(480 / 2, 640 / 2);
    }else {
        _anchorPoint = CGPointMake(640 / 2, 480 / 2);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    CGRect new = [change[@"new"] CGRectValue];
}

@end
