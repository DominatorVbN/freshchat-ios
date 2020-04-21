//
//  FDImagePreviewController.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 04/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FCImagePreviewController : UIViewController<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

-(instancetype)initWithImageData:(NSData *)imageData;

-(void)presentOnController:(UIViewController *)controller;

@end
