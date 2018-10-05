//
//  FCRemoteConfig.h
//  HotlineSDK
//
//  Created by user on 25/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCRefreshIntervals.h"
#import "FCEnabledFeatures.h"
#import "FCConversationConfig.h"
#import "FCCSatSettings.h"
#import "FCUserDefaults.h"

@interface FCRemoteConfig : NSObject

+(instancetype)sharedInstance;

@property (nonatomic, assign) BOOL accountActive;
@property (nonatomic, assign) long sessionTimeOutInterval;
@property (nonatomic, assign) float activeConvFetchBackoffRatio;
@property (nonatomic, assign) long activeConvWindow;
@property (nonatomic, assign) BOOL authJWTEnabled;

@property (nonatomic, strong) FCConversationConfig *conversationConfig;
@property (nonatomic, strong) FCRefreshIntervals *refreshIntervals;
@property (nonatomic, strong) FCEnabledFeatures *enabledFeatures;
@property (nonatomic, strong) FCCSatSettings *csatSettings;

- (void) updateRemoteConfig : (NSDictionary *) configDict;

- (BOOL) isActiveInboxAndAccount;
- (BOOL) isActiveFAQAndAccount;
- (BOOL) isActiveConvAvailable;

@end
