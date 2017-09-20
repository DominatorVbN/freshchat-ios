//
//  FDDeeplinkFragment.h
//  HotlineSDK
//
//  Created by user on 09/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Fragment.h"
#import "HLAgentMessageCell.h"

@interface FDDeeplinkFragment : UIButton
    -(id) initWithFragment: (FragmentData *) fragment;
    @property (nonatomic, weak) id<HLMessageCellDelegate> agentMessageDelegate;
    @property FragmentData *fragmentData;
@end
