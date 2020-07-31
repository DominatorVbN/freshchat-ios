//
//  FCCalendarBannerView.h
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 20/05/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCTemplateFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCCalendarBannerView : UIView
-(id)initWithURL:(NSURL *)url andTime:(NSTimeInterval) time;
-(void)updateViewWithTime:(NSTimeInterval)time andURL:(NSURL *) url;
@property(nonatomic, weak)id<FCLinkDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
