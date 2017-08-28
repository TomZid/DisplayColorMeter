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
    [[VideoSessionHelper new] configSessionWithPreviewLayerSuperLayer:self.view.layer];
}

@end
