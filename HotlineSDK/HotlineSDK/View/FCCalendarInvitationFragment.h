//
//  FCCalendarInvitationFragment.h
//  FreshchatSDK
//
//  Created by Harish kumar on 23/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCUserMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCCalendarInvitationFragment : UIView

@property FragmentData *fragmentData;

-(id) initWithFragment: (FragmentData *) fragment uploadStatus:(BOOL)uploadStatus andInternalMeta:(NSString *) internalMeta;

@end

NS_ASSUME_NONNULL_END
