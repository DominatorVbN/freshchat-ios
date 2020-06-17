//
//  FCCalendarOptionsView.h
//  FreshchatSDK
//
//  Created by Harish kumar on 22/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCAgentMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCCalendarOptionsView : UIView

@property (nonatomic, weak) id<HLMessageCellDelegate> delegate;

- (id) initCalendarOptionsViewForMessage : (FCMessageData *) message;

@end

NS_ASSUME_NONNULL_END
