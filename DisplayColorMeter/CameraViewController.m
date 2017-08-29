//
//  ViewController.m
//  DisplayColorMeter
//
//  Created by tom.zhu on 28/08/2017.
//  Copyright © 2017 TZ. All rights reserved.
//

#import "CameraViewController.h"
#import "VideoSessionHelper.h"

@interface CameraViewController ()

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[VideoSessionHelper new] configSessionWithPreviewLayerSuperView:self.view option:1];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj layoutSubviews];
    }];
}

@end
