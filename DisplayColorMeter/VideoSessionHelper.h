//
//  VideoSessionHelper.h
//  DisplayColorMeter
//
//  Created by tom.zhu on 28/08/2017.
//  Copyright © 2017 TZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger) {
    vs_effective_nonmal,
    vs_effective_inner,
}VideoSessionHelper_Effective;

@interface VideoSessionHelper : NSObject

- (void)configSessionWithPreviewLayerSuperView:(UIView*)superView option:(VideoSessionHelper_Effective)option;

@end
