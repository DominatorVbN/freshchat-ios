//
//  FCCalendarEmailViewController.h
//  FreshchatSDK
//
//  Created by Harish kumar on 23/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCMessages.h"

enum FCCalendarViewState {
    EmailView,
    LimitedSlotsView,
    AllSlotsView
};

@interface FCCalendarViewController : UIViewController

@property (nonatomic, strong) FCMessageData *message;
@property (nonatomic, strong) FCConversations *conversation;

@end

