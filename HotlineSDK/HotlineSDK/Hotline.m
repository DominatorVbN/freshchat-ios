//
//  Hotline.m
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "Hotline.h"
#import "HLContainerController.h"
#import "HLCategoriesListController.h"
#import "HLCategoryGridViewController.h"
#import "FDReachabilityManager.h"
#import "HLChannelViewController.h"
#import "KonotorDataManager.h"
#import "FDMessageController.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "Konotor.h"
#import "HLCoreServices.h"
#import "FDUtilities.h"
#import "FDChannelUpdater.h"
#import "FDSolutionUpdater.h"
#import "FDMessagesUpdater.h"
#import "FDDAUUpdater.h"
#import "KonotorMessage.h"
#import "HLConstants.h"
#import "HLMessageServices.h"
#import "KonotorCustomProperty.h"
#import "KonotorUser.h"
#import "HLVersionConstants.h"
#import "HLNotificationHandler.h"

@interface Hotline ()

@property(nonatomic, strong, readwrite) HotlineConfig *config;
@property (nonatomic, assign) BOOL showChannelThumbnail;
@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, strong) HLNotificationHandler *notificationHandler;

@end

@interface HotlineUser ()

-(void)clearUserData;

@end

@implementation Hotline

+(instancetype)sharedInstance{
    static Hotline *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[Hotline alloc]init];
    });
    if(![sharedInstance checkPersistence]) {
        return nil;
    }
    return sharedInstance;
}

+(NSString *)SDKVersion{
    return HOTLINE_SDK_VERSION;
}

-(BOOL)checkPersistence {
    if(![KonotorDataManager sharedInstance].persistentStoreCoordinator){
        return false;
    }
    return true;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [[FDReachabilityManager sharedInstance] start];
    }
    return self;
}

-(void)initWithConfig:(HotlineConfig *)config{
    config.appID  = trimString(config.appID);
    config.appKey = trimString(config.appKey);
    config.domain = [self validateDomain: config.domain];

    self.config = config;
    
    if ([self hasUpdatedConfig:config]) {
        [self cleanUpData:^{
            [self initConfigAndUser:config];
        }];
    }
    else {
        [self initConfigAndUser:config];
    }
}

-(void)initConfigAndUser:(HotlineConfig *)config{
    [self updateConfig:config];
    [self registerUser];
    [self registerAppNotificationListeners];
    if(config.pollWhenAppActive){
        [self startPoller];
    }
}

-(void) registerAppNotificationListeners{
    [[NSNotificationCenter defaultCenter]
                    addObserver: self
                    selector: @selector(newSession:)
                    name: UIApplicationDidBecomeActiveNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
}

-(void)updateAppVersion{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *storedValue = [store objectForKey:HOTLINE_DEFAULTS_APP_VERSION];
    NSString *currentValue = [[[NSBundle bundleForClass:[self class]] infoDictionary]objectForKey:@"CFBundleShortVersionString"];
    if (storedValue && ![storedValue isEqualToString:currentValue]) {
        [KonotorCustomProperty createNewPropertyForKey:@"app_version" WithValue:currentValue isUserProperty:NO];
        [HLCoreServices uploadUnuploadedProperties];
    }
    [store setObject:currentValue forKey:HOTLINE_DEFAULTS_APP_VERSION];
}

-(void)updateSDKBuildNumber{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *storedValue = [store objectForKey:HOTLINE_DEFAULTS_SDK_BUILD_NUMBER];
    NSString *currentValue = HOTLINE_SDK_BUILD_NUMBER;
    if (![storedValue isEqualToString:currentValue]) {
        [[[HLCoreServices alloc]init]updateSDKBuildNumber:currentValue];
    }
}


-(void)cleanUpData:(void (^)())completion{
    KonotorDataManager *dataManager = [KonotorDataManager sharedInstance];
    [dataManager deleteAllSolutions:^(NSError *error) {
        FDLog(@"All solutions deleted");
        [dataManager deleteAllIndices:^(NSError *error) {
            FDLog(@"Index cleared");
            [self clearUserDataWithCompletion:completion andInit:false];
        }];
    }];
}

-(BOOL)hasUpdatedConfig:(HotlineConfig *)config{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *existingDomainName = [store objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    NSString *existingAppID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    if ((existingDomainName && ![existingDomainName isEqualToString:@""])&&(existingAppID && ![existingAppID isEqualToString:@""])) {
        return (![existingDomainName isEqualToString:config.domain] || ![existingAppID isEqualToString:config.appID]) ? YES : NO;
    }else{
        //This is first launch, do not treat this as config update.
        FDLog(@"First launch");
        return NO;
    }
}

-(void)updateConfig:(HotlineConfig *)config{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if (config) {
        [store setObject:config.appID forKey:HOTLINE_DEFAULTS_APP_ID];
        [store setObject:config.appKey forKey:HOTLINE_DEFAULTS_APP_KEY];
        [store setObject:config.domain forKey:HOTLINE_DEFAULTS_DOMAIN];
        [store setBoolValue:config.pictureMessagingEnabled forKey:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED];
        [store setBoolValue:config.voiceMessagingEnabled forKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];
        [store setBoolValue:config.displayFAQsAsGrid forKey:HOTLINE_DEFAULTS_DISPLAY_SOLUTION_AS_GRID];
        [store setBoolValue:config.cameraCaptureEnabled forKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
        [store setBoolValue:config.agentAvatarEnabled forKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
        [store setBoolValue:config.notificationSoundEnabled forKey:HOTLINE_DEFAULTS_NOTIFICATION_SOUND_ENABLED];
        [store setBoolValue:config.showNotificationBanner forKey:HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER];
        [store setBoolValue:YES forKey:HOTLINE_DEFAULTS_SHOW_CHANNEL_THUMBNAIL];
        [[HLTheme sharedInstance]setThemeName:config.themeName];
    }
}

-(void) updateConversationBannerMessage:(NSString *) message{
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    [store setObject:message forKey:HOTLINE_DEFAULTS_CONVERSATION_BANNER_MESSAGE];
}

-(void)updateUser:(HotlineUser *)user{
    [KonotorUser storeUserInfo:user];
    [HLCoreServices uploadUnuploadedProperties];
}


-(void)updateUserProperties:(NSDictionary*)props{
    [[KonotorDataManager sharedInstance].mainObjectContext performBlock:^{
        if(props){
            for(NSString *key in props){
                NSString *value = props[key];
                [KonotorCustomProperty createNewPropertyForKey:key WithValue:value isUserProperty:NO];
            }
        }
        [HLCoreServices uploadUnuploadedProperties];
    }];
}

-(void)updateUserPropertyforKey:(NSString *) key withValue:(NSString *)value{
    if (key && value) {
        [self updateUserProperties:@{ key : value}];
    }
}

-(void)registerUser{
    dispatch_async(dispatch_get_main_queue(),^{
        BOOL isUserRegistered = [FDUtilities isUserRegistered];
        if (!isUserRegistered) {
            [[[HLCoreServices alloc]init] registerUser:^(NSError *error) {
                if (!error) {
                    [self performPendingTasks];
                }
            }];
        }
    });
}

-(void)registerDeviceToken{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if([FDUtilities isUserRegistered]){
        BOOL isDeviceTokenRegistered = [store boolValueForKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
        if (!isDeviceTokenRegistered) {
            NSString *userAlias = [FDUtilities getUserAlias];
            NSString *token = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
            [[[HLCoreServices alloc]init] registerAppWithToken:token forUser:userAlias handler:nil];
        }
    }
    else {
        FDLog(@"WARNING: deviceToken is not being updated now");
    }
}


/*  This function is called during every launch &
    when the SDK's app is transitioned from background to foreground  */

-(void)newSession:(NSNotification *)notification{
    if(self.config.pollWhenAppActive){
        [self startPoller];
    }
    [self performPendingTasks];
}

-(void)handleEnteredBackground:(NSNotification *)notification{
    [self cancelPoller];
}

-(void)performPendingTasks{
    FDLog(@"Performing pending tasks");
    dispatch_async(dispatch_get_main_queue(),^{
        [[[FDSolutionUpdater alloc]init] fetch];
        [KonotorMessage uploadAllUnuploadedMessages];
        [HLMessageServices fetchChannelsAndMessages:nil];
        [[[FDDAUUpdater alloc]init] fetch];
        [self registerDeviceToken];
        [self updateAppVersion];
        [self updateSDKBuildNumber];
        [HLCoreServices uploadUnuploadedProperties];
    });
}

-(HLViewController *)getPreferredFAQsController{
    HLViewController *preferedController = nil;
    FDSecureStore *store = [FDSecureStore sharedInstance];
    BOOL isGridLayoutDisplayEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_DISPLAY_SOLUTION_AS_GRID];
    if (isGridLayoutDisplayEnabled) {
        preferedController = [[HLCategoryGridViewController alloc]init];
    }else{
        preferedController = [[HLCategoriesListController alloc]init];
    }
    return preferedController;
}

-(void)showFAQs:(UIViewController *)controller{
    HLViewController *preferredController = [self getPreferredFAQsController];
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:preferredController andEmbed:NO];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}

-(void)showConversations:(UIViewController *)controller{
    [[KonotorDataManager sharedInstance]fetchAllVisibleChannels:^(NSArray *channels, NSError *error) {
        if (!error) {
            HLContainerController *preferredController = nil;
            if (channels.count == 1) {
                FDMessageController *messageController = [[FDMessageController alloc]initWithChannel:channels.firstObject
                                                                                   andPresentModally:YES];
                preferredController = [[HLContainerController alloc]initWithController:messageController andEmbed:NO];
            }else{
                HLChannelViewController *channelViewController = [[HLChannelViewController alloc]init];
                preferredController = [[HLContainerController alloc]initWithController:channelViewController andEmbed:NO];
            }
            UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:preferredController];
            [controller presentViewController:navigationController animated:YES completion:nil];
        }
    }];
}

-(UIViewController *)getControllerForEmbed:(HLViewController*)controller{
    HLContainerController *preferredController =[[HLContainerController alloc]initWithController:controller andEmbed:YES];
    return preferredController;
}

-(UIViewController*) getFAQsControllerForEmbed{
    return [self getControllerForEmbed:[self getPreferredFAQsController]];
}

-(UIViewController*) getConversationsControllerForEmbed{
    HLViewController *controller;
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    request.predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
    NSArray *results = [context executeFetchRequest:request error:nil];
    
    if (results.count == 1){
        controller = [[FDMessageController alloc]initWithChannel:results.firstObject andPresentModally:NO];
    }else{
        controller = [[HLChannelViewController alloc]init];
    }

    return [self getControllerForEmbed:controller];
}

#pragma mark Push notifications

-(void)updateDeviceToken:(NSData *)deviceToken {
   
    NSString *deviceTokenString = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">"withString:@""] stringByReplacingOccurrencesOfString:@" "withString:@""];
    [self updateDeviceTokenInternal:deviceTokenString];
}

-(void) updateDeviceTokenInternal:(NSString *) deviceTokenString{
     FDSecureStore *store = [FDSecureStore sharedInstance];
    if (deviceTokenString && ![deviceTokenString isEqualToString:@""]) {
        NSString* storedDeviceToken = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
        if(![storedDeviceToken isEqualToString:deviceTokenString]){
            [store setObject:deviceTokenString forKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
            [store setBoolValue:NO forKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
        }
    }
    [self registerDeviceToken];
}

-(NSDictionary *)getPayloadFromNotificationInfo:(NSDictionary *)info{
    NSDictionary *payload = info;
    if (info[@"UIApplicationLaunchOptionsRemoteNotificationKey"]) {
        payload = info[@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    }
    return payload;
}

-(BOOL)isHotlineNotification:(NSDictionary *)info{
    NSDictionary *payload = [self getPayloadFromNotificationInfo:info];
    return ([payload[@"source"] isEqualToString:@"konotor"] || [payload[@"source"] isEqualToString:@"hotline"]);
}

-(void)handleRemoteNotification:(NSDictionary *)info andAppstate:(UIApplicationState)appState{
    if(![self isHotlineNotification:info]){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *payload = [self getPayloadFromNotificationInfo:info];
        FDLog(@"Push Recieved :%@", payload);
        
        [[[FDMessagesUpdater alloc]init]resetTime];
        
        NSNumber *channelID = @([payload[@"kon_c_ch_id"] integerValue]);
        NSString *message = [payload valueForKeyPath:@"aps.alert"];
        HLChannel *channel = [HLChannel getWithID:channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
        
        if (!channel){
            [[[FDChannelUpdater alloc] init]resetTime];
            [HLMessageServices fetchChannelsAndMessages:^(NSError *error){
                if(!error){
                    NSManagedObjectContext *mContext = [KonotorDataManager sharedInstance].mainObjectContext;
                    [mContext performBlock:^{
                        HLChannel *ch = [HLChannel getWithID:channelID inContext:mContext];
                        if(ch){
                            self.notificationHandler = [[HLNotificationHandler alloc] init];
                            [self.notificationHandler handleNotification:ch withMessage:message andState:appState];
                        }
                    }];
                }
            }];
        }
        else {
            [HLMessageServices fetchChannelsAndMessages:nil];
            self.notificationHandler = [[HLNotificationHandler alloc] init];
            [self.notificationHandler handleNotification:channel withMessage:message andState:appState];
        }
    });
}

-(void)clearUserData{
    [self clearUserDataWithCompletion:nil andInit:true];
}

-(void)clearUserDataWithCompletion:(void (^)())completion andInit:(BOOL)doInit{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HotlineConfig *config = [[HotlineConfig alloc] initWithAppID:[store objectForKey:HOTLINE_DEFAULTS_APP_ID]
                                                       andAppKey:[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    config.domain = [store objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    config.agentAvatarEnabled =[store objectForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
    config.domain = [store objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    config.voiceMessagingEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];
    config.pictureMessagingEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED];
    config.cameraCaptureEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
    config.displayFAQsAsGrid = [store boolValueForKey:HOTLINE_DEFAULTS_DISPLAY_SOLUTION_AS_GRID];
    config.showNotificationBanner = [store boolValueForKey:HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER];
    
    NSString* deviceToken = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
    
    [[HotlineUser sharedInstance]clearUserData];
    [[FDSecureStore persistedStoreInstance]clearStoreData];
    [[KonotorDataManager sharedInstance]deleteAllProperties:^(NSError *error) {
        FDLog(@"Deleted all meta properties");
        [[KonotorDataManager sharedInstance]deleteAllChannels:^(NSError *error) {
            // Initiate a init
            if(doInit){
                [self initWithConfig:config];
            }
            [self updateDeviceTokenInternal:deviceToken];
            if(completion){
                completion();
            }
        }];
    }];
    
}

-(void)clearUserDataWithCompletion:(void (^)())completion{
    [self clearUserDataWithCompletion:completion andInit:true];
}

-(NSInteger)unreadCount{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"KonotorMessage"];
    request.predicate = [NSPredicate predicateWithFormat:@"messageRead == NO"];
    NSArray *messages = [context executeFetchRequest:request error:nil];
    return messages.count;
}

-(void)unreadCountWithCompletion:(void (^)(NSInteger count))completion{
    [HLMessageServices fetchChannelsAndMessages:^(NSError *error) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                 completion([self unreadCount]);
            });
        }
    }];
}

- (NSString *)validateDomain:(NSString*)domain
{
    return [FDStringUtil replaceInString:trimString(domain) usingRegex:@"^http[s]?:\\/\\/" replaceWith:@""];
}

// Polling changes

-(void)startPoller{
    if(![self.pollingTimer isValid]){
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(pollNewMessages:)
                                                           userInfo:nil repeats:YES];
        FDLog(@"Start off-screen message poller");
    }
}

-(void) pollNewMessages:(id)sender{
    [HLMessageServices fetchChannelsAndMessages:nil];
}

-(void)cancelPoller{
    if([self.pollingTimer isValid]){
        [self.pollingTimer invalidate];
        FDLog(@"Cancel off-screen message poller");
    }
}

@end