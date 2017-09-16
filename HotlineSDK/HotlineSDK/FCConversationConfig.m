//
//  FCMiscFeatures.m
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCConversationConfig.h"
#import "HLUserDefaults.h"
#import "FCRefreshIntervals.h"

@implementation FCConversationConfig

-(instancetype)init{
    self = [super init];
    if (self) {
        self.agentAvatar                    = [self getAgentAvatar];
        self.launchDeeplinkFromNotification = [self getLaunchDeeplinkFromNotification];
        self.activeConvFetchBackoffRatio    = [self getActiveConvFetchBackoffRatio];
        self.activeConvWindow               = [self getActiveConvWindow];
    }
    return self;
}

- (BOOL) getLaunchDeeplinkFromNotification{
    if ([HLUserDefaults getObjectForKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED] != nil) {
        return (BOOL) [HLUserDefaults getObjectForKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED];
    }
    return YES;
}

- (int) getAgentAvatar{
    if ([HLUserDefaults getObjectForKey:CONFIG_RC_AGENT_AVATAR_TYPE] != nil) {
        return (BOOL) [HLUserDefaults getObjectForKey:CONFIG_RC_AGENT_AVATAR_TYPE];
    }
    return 1;
}

- (float) getActiveConvFetchBackoffRatio {
    if ([HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO] != nil) {
        return [HLUserDefaults getFloatForKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
    }
    return 1.25;
}

- (float) getActiveConvWindow {
    if ([HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_WINDOW] != nil) {
        return (long) [HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
    }
    return 3 * ONE_DAY_IN_MS;
}

- (void) setLaunchDeeplinkFromNotification :(BOOL) launchDeeplinkFromNotification {
    [HLUserDefaults setBool:launchDeeplinkFromNotification forKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED];
    self.launchDeeplinkFromNotification = launchDeeplinkFromNotification;
}

- (void) setAgentAvatar: (int) agentAvatar {
    [HLUserDefaults setIntegerValue:agentAvatar forKey:CONFIG_RC_AGENT_AVATAR_TYPE];
    self.agentAvatar = agentAvatar;
}

- (void) setActiveConvWindow:(long) activeConvWindow {
    [HLUserDefaults setLong:activeConvWindow forKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
    self.activeConvWindow = activeConvWindow;
}

- (void) setActiveConvFetchBackOffRatio:(float) activeConvFetchBackoffRatio {
    [HLUserDefaults setBool:activeConvFetchBackoffRatio forKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
    self.activeConvFetchBackoffRatio = activeConvFetchBackoffRatio;
}

- (void) updateConvConfig : (NSDictionary *) configDict {
    NSString* avatarType =  [configDict objectForKey:@"agentAvatars"];
    if([avatarType isEqualToString:@"REAL_AGENT_AVATAR"]){
        [self setAgentAvatar:1];
    }
    else if([avatarType isEqualToString:@"APP_ICON"]){
        [self setAgentAvatar:2];
    }
    else {
        [self setAgentAvatar:3];
    }
    [self setActiveConvWindow:[[configDict objectForKey:@"activeConvWindow"] longValue]];
    [self setActiveConvFetchBackOffRatio:[[configDict objectForKey:@"activeConvFetchBackoffRatio"] floatValue]];
    [self setLaunchDeeplinkFromNotification:[[configDict objectForKey:@"launchDeeplinkFromNotification"] boolValue]];
    
}

@end
