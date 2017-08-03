//
//  FDChannelUpdater.m
//  HotlineSDK
//
//  Created by user on 04/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDChannelUpdater.h"
#import "HLMessageServices.h"
#import "HLConstants.h"
#import "HLMacros.h"
#import "KonotorConversation.h"
#import "FCRemoteConfigUtil.h"

@implementation FDChannelUpdater

-(id)init{
    self = [super init];
    if (self) {
        [self useInterval:[FCRemoteConfigUtil setChannelsFetchIntervalLaidback]];
        [self useConfigKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_INTERVAL_TIME];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    if([FCRemoteConfigUtil isActiveInboxAndAccount]){
        [HLMessageServices fetchAllChannels:^(NSArray<HLChannel *> *channels, NSError *error) {
            ALog(@"Channels updated");
            if(completion) completion(error);
        }];
    }
}

@end
