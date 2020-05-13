//
//  FDUtilities.m
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <asl.h>
#import "FCUsers.h"
#import "FCUtilities.h"
#import "FCSecureStore.h"
#import "FCMacros.h"
#import "FCTheme.h"
#import "FreshchatSDK.h"
#import "FCStringUtil.h"
#import "FCLocalization.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>
#import "FCPlistManager.h"
#import "FCCoreServices.h"
#import "FCLocalNotification.h"
#import "FCRemoteConfig.h"
#import "FCUserDefaults.h"
#import "FCConstants.h"
#import "FCLocalization.h"
#import "FCAutolayoutHelper.h"
#import "FCContainerController.h"
#import "FDImageView.h"
#import "FCJWTUtilities.h"
#import "FCJWTAuthValidator.h"
#import "FCFAQUtil.h"
#import "FCChannelUtil.h"
#import "FDThemeConstants.h"
#import "FCEventsManager.h"
#import "FCUserUtil.h"
#import "FCAnimatedImage.h"

#define EXTRA_SECURE_STRING @"73463f9d-70de-41f8-857a-58590bdd5903"
#define ERROR_CODE_USER_DELETED 19
#define ERROR_CODE_ACCOUNT_DELETED 20

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation FCUtilities

#pragma mark - General Utitlites


+(NSBundle *)frameworkBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath      = [[NSBundle bundleForClass:[self class]] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"FreshdeskSDKResources.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return frameworkBundle;
}

+ (void) resetNavigationStackWithController:(UIViewController *)controller currentController:(UIViewController *)currentController {
    NSMutableArray<UIViewController *> *viewControllers = [currentController.navigationController.viewControllers mutableCopy];
    [viewControllers removeAllObjects];
    [viewControllers addObject:controller];
    [currentController.navigationController setViewControllers:viewControllers animated:NO];
}


+(UIImage *)imageWithColor:(UIColor *)color{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (BOOL) isSDKInitialized {
    FCSecureStore *store = [FCSecureStore sharedInstance];
    if([store objectForKey:HOTLINE_DEFAULTS_APP_ID] && [store objectForKey:HOTLINE_DEFAULTS_APP_KEY] ){
        return TRUE;
    }
    return FALSE;
}

+(NSString *) getTracker{
    return [NSString stringWithFormat:@"hl_ios_%@",[Freshchat SDKVersion]];
}

+(NSString *) getUUIDLookupKey{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *uuIdLookupKey = [NSString stringWithFormat:@"%@-%@", appID ,HOTLINE_DEFAULTS_DEVICE_UUID ];
    return uuIdLookupKey;
}

+(void) removeUUIDWithAppID:(NSString *)appID {    
    FCSecureStore *persistedStore = [FCSecureStore persistedStoreInstance];
    if(appID) {
        NSString *uuIdLookupKey = [NSString stringWithFormat:@"%@-%@", appID ,HOTLINE_DEFAULTS_DEVICE_UUID ];
        if(uuIdLookupKey) {
            [persistedStore removeObjectWithKey:uuIdLookupKey];
        }
    }
}

+(void) removeUUID {
    FCSecureStore *store = [FCSecureStore sharedInstance];
    FCSecureStore *persistedStore = [FCSecureStore persistedStoreInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    if(appID) {
        NSString *uuIdLookupKey = [NSString stringWithFormat:@"%@-%@", appID ,HOTLINE_DEFAULTS_DEVICE_UUID ];
        if(uuIdLookupKey) {
            [persistedStore removeObjectWithKey:uuIdLookupKey];
        }
    }
}

/* This function gets the user-alias from persisted secure store for new customers (Hotline),
 it also migrates the key from [Konotor SDK to Hotline SDK] if exists */
+(NSString *)currentUserAlias{
    NSString* userAlias = [[FCSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    if(userAlias){
        return userAlias;
    }
    return @""; //return empty to prevent null
}

+(NSString *)getUserAliasWithCreate{
    NSString* userAlias = [[FCSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    if(userAlias){
        return userAlias;
    }
    else {
        userAlias = [FCUtilities generateUserAlias];
        if(userAlias){
            [[FCSecureStore sharedInstance] setObject:userAlias forKey:HOTLINE_DEFAULTS_DEVICE_UUID];
        }
    }
    return userAlias;
}

+(void) updateUserAlias: (NSString *) userAlias {
    if(userAlias){
        [[FCSecureStore sharedInstance] setObject:userAlias forKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    }
}

+(UIViewController*) topMostController {
    UIViewController *topController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

+(NSString *)generateUserAlias{
    NSString *userAlias;
    FCSecureStore *persistedStore = [FCSecureStore persistedStoreInstance];
    NSString *uuIdLookupKey = [FCUtilities getUUIDLookupKey];
    BOOL isExistingUser = [persistedStore checkItemWithKey:uuIdLookupKey];
    if (!isExistingUser) {
        FCUsers *user = [FCUsers getUser];
        if (user.userAlias) {
            userAlias = user.userAlias;
            FDLog(@"Migrating Konotor User");
        }
        else {
            userAlias = [FCStringUtil generateUUID];
        }
        [FCUtilities storeUserAlias:userAlias];
    }
    userAlias = [persistedStore objectForKey:uuIdLookupKey];
    return userAlias;
}


+(void)storeUserAlias:(NSString *)alias{
    FCSecureStore *persistedStore = [FCSecureStore persistedStoreInstance];
    [persistedStore setObject:alias forKey:[FCUtilities getUUIDLookupKey]];
}

+ (NSString *) returnLibraryPathForDir : (NSString *) directory{
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:directory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath
                                  withIntermediateDirectories:YES
                                                   attributes:attr
                                                        error:&error];
        if (error){
            FDLog(@"Error creating directory path: %@", [error localizedDescription]);
        }
    }
    return filePath;
}

+(NSString *) getKeyForObject:(NSObject *) object {
    if(object){
        return [NSString stringWithFormat:@"%lu" , (unsigned long)[object hash]];
    }
    return @"nil";
}

+(NSString *)getAdID{
    NSString *adId = @"";
    Class advertisingClass = NSClassFromString(@"ASIdentifierManager");
    if (advertisingClass){
        adId = [[[advertisingClass performSelector:@selector(sharedManager)]
                                    performSelector:@selector(advertisingIdentifier)]
                                    performSelector: @selector(UUIDString)];
    }
    return  adId;
}

+(NSString *)generateOfflineMessageAlias{
    NSString *randomString = [FCStringUtil generateUUID];
    return [NSString stringWithFormat:@"temp-%@", randomString];
}


+(NSDictionary *)deviceInfoProperties{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    UIDevice *device = [UIDevice currentDevice];
    
    [properties setValue:[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"app_version"];
    [properties setValue:@"iOS" forKey:@"os"];
    [properties setValue:[device systemVersion] forKey:@"os_version"];
    [properties setValue:[FCUtilities deviceModelName] forKey:@"model"];
    [properties setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"app_version_code"];
    [properties setValue:FRESHCHAT_SDK_VERSION forKey:@"sdk_version_code"];
    return [NSDictionary dictionaryWithDictionary:properties];
}

static NSInteger networkIndicator = 0;

+(void)setActivityIndicator:(BOOL)isVisible{
    if (isVisible){
        networkIndicator++;
    }
    else{
        if(networkIndicator > 0){
            networkIndicator--;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(networkIndicator > 0)];
    });
}

+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule{
    NSString *pStr = [NSString stringWithFormat:@"%@:%@",pModule,alertviewstring ];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: pModule
                          message: pStr
                          delegate: nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Ok",
                          nil];
    [alert show];
    return;
}

+(NSString *) getReplyResponseForTime :(NSInteger)timeInSec andType: (enum ResponseTimeType) type {
    float minutes = timeInSec/60.0;
    NSString *messageStr;
    if (minutes <= 1) {
        messageStr = (type == CURRENT_AVG) ? HLLocalizedString(LOC_CURRENTLY_REPLYING_IN_MINUTE) : HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_MIN);
    }else if (minutes < 55) {
        int min;
        if (minutes < 10) {
            // If < 10 minutes
            min = (int) ceil(minutes);
        } else {
            // If < 55 minutes, round off to factor of 5
            min = (int) ceil(minutes / 5) * 5;
        }
        messageStr = (type == CURRENT_AVG) ?  HLLocalizedString(LOC_CURRENTLY_REPLYING_IN_X_MIN) : HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_X_MIN);
        if([FCStringUtil isEmptyString:trimString(messageStr)]) return nil;
        return [NSString stringWithFormat: @"%@ %d %@",messageStr, min,HLLocalizedString(LOC_PLACEHOLDER_MINS)];
    } else if (minutes <= 60) {
        messageStr = (type == CURRENT_AVG) ? HLLocalizedString(LOC_CURRENTLY_REPLYING_IN_HOUR) : HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_HOUR);
    } else if (minutes <= 120) {
        messageStr = (type == CURRENT_AVG) ? HLLocalizedString(LOC_CURRENTLY_REPLYING_IN_TWO_HOURS) : HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_TWO_HOURS);
    } else {
        messageStr = (type == CURRENT_AVG) ? HLLocalizedString(LOC_CURRENTLY_REPLYING_IN_FEW_HOURS) : HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_FEW_HOURS);
    }
    return messageStr;
}

+ (NSTimeInterval) getCurrentTimeInMillis{
    return ceil(([[NSDate date] timeIntervalSince1970]) * ONE_SECONDS_IN_MS);
}

#pragma add Hide Conversation Changes

+ (NSArray *) getReopenedMsgTypes; {
    return [FCRemoteConfig sharedInstance].conversationConfig.reopenedMsgtypes;
}

+ (NSArray *) getResolvedMsgTypes{
    return [FCRemoteConfig sharedInstance].conversationConfig.resolvedMsgTypes;
}

+ (NSArray *) getResolvedReopenedMsgTypes {
    return [[FCRemoteConfig sharedInstance].conversationConfig.resolvedMsgTypes arrayByAddingObjectsFromArray:[FCRemoteConfig sharedInstance].conversationConfig.reopenedMsgtypes];
}

+ (NSString*)convertIntoMD5 :(NSString *) str
{
    // Create pointer to the string as UTF8
    const char *ptr = [str UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[16];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr,(unsigned int) strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:16 * 2];
    for(int i = 0; i < 16; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+(BOOL)isPoweredByHidden{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    
    NSString *secretKey = [[FCTheme sharedInstance] getFooterSecretKey];
    if (!secretKey) return NO;
    
    NSString* myString = [NSString stringWithFormat:@"%@%@%@",[store objectForKey:HOTLINE_DEFAULTS_APP_ID],EXTRA_SECURE_STRING,[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:[myString length]];
    
    [myString enumerateSubstringsInRange:NSMakeRange(0,[myString length])
                                 options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                              usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                  [reversedString appendString:substring];
                              }];
    
    return ([[self convertIntoMD5:reversedString] isEqualToString:secretKey]) ? YES : NO;
}

+(NSNumber *)getLastUpdatedTimeForKey:(NSString *)key{
    NSNumber *lastUpdateTime = [[FCSecureStore sharedInstance] objectForKey:key];
    if (lastUpdateTime == nil) lastUpdateTime = @0;
    return lastUpdateTime;
}

+(void) showAlertViewWithTitle : (NSString *)title message : (NSString *)message andCancelText : (NSString *) cancelText{
    
    if(title.length == 0) {
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelText otherButtonTitles:nil, nil];
    [alertView show];
}

+(BOOL) isValidPropKey: (NSString *) str {
    return str && [str length] <=32 && [FCStringUtil isValidUserPropName:str];
}

+(BOOL) isValidPropValue: (NSString *) str {
    return str && [str length] <= 256;
}

+(NSDictionary*) filterValidUserPropEntries :(NSDictionary*) userDict{
    NSMutableDictionary *userProperties = [[NSMutableDictionary alloc] init];
    if(userDict){
        for(id key in userDict){
            if([FCUtilities isValidPropKey:key]){
                NSObject *valueObj = [userDict objectForKey:key];
                if([valueObj isKindOfClass:[NSString class]]) {
                    NSString *value = (NSString *) valueObj;
                    if([FCUtilities isValidPropValue:value]){
                        [userProperties setObject:value forKey:key];
                    }
                    else {
                        ALog(@"Invalid user property value %@ - %@ : <validation error>", key, valueObj);
                    }
                } else {
                    ALog(@"Invalid user property value. Not a NSString. %@ - %@ : <validation error>", key, valueObj);
                }
            }
            else{
                ALog(@"Invalid user property  key %@ : <validation error>", key);
            }
        }
    }
    return userProperties;
}

+(NSString *)appName{
    NSString *appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    if (appName) {
        return appName;
    }else{
        return [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    }
}

+(NSArray *) convertTagsArrayToLowerCase : (NSArray *)tags{
    NSArray *noEmptyTags = [tags filteredArrayUsingPredicate:
                               [NSPredicate predicateWithFormat:@"length > 0"]];
    return [noEmptyTags valueForKey:@"lowercaseString"];
}

+(BOOL) canMakeRemoteConfigCall {
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[FCUserDefaults getObjectForKey:CONFIG_RC_LAST_API_FETCH_INTERVAL_TIME]];
    if(isnan(interval)){
        return true;
    }
    if(interval > [FCRemoteConfig sharedInstance].refreshIntervals.remoteConfigFetchInterval/ 1000.0){
        return true;
    }
    return false;
}

+ (BOOL) isRemoteConfigFetched {
    return ([FCUserDefaults getObjectForKey:CONFIG_RC_LAST_API_FETCH_INTERVAL_TIME])? TRUE :FALSE;
}

+(BOOL) canMakeSessionCall {
    if(![FCUserDefaults getObjectForKey:FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME]){
        return  true;
    }
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[FCUserDefaults getObjectForKey:FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME]];
    FDLog(@"Time interval b/w dates %f", interval);
    if(interval > [FCRemoteConfig sharedInstance].sessionTimeOutInterval/1000){
        return true;
    }
    return false;
}

+ (BOOL) canMakeTypicallyRepliesCall {
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[FCUserDefaults getObjectForKey:CONFIG_RC_LAST_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL]];
    
    if(isnan(interval)){
        return true;
    }
    if(interval > [FCRemoteConfig sharedInstance].refreshIntervals.responseTimeExpectationsFetchInterval/ 1000.0){
        return true;
    }
    return false;
}

+ (void) removeResponseTimeFetchInterval {
    [FCUserDefaults removeObjectForKey:CONFIG_RC_LAST_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL];
}

+ (BOOL) isTodaySameAsDate : (NSDate *) date {
    return [FCUtilities isSameDate:date excludeDay:false];
}

+ (BOOL) isSameDate : (NSDate *) date excludeDay : (BOOL) excludeDay{
    NSDate *currentdate = [NSDate date];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents* currentComp = [calendar components:unitFlags fromDate:currentdate];
    NSDateComponents* lastFetchComp = [calendar components:unitFlags fromDate:date];
    NSComparisonResult result;
    result = [currentdate compare:date];
    if(result == NSOrderedDescending){//date comparision, current should be greater than
        if (!(([currentComp day] == [lastFetchComp day] || excludeDay) && [currentComp month] == [lastFetchComp month] && [currentComp year]  == [lastFetchComp year])){
            return false;
        }
    }
    return true;
}

+(BOOL) canMakeDAUCall {
    FCSecureStore* store = [FCSecureStore sharedInstance];
    if ([FCUserUtil isUserRegistered]) {
        NSDate *lastFetchDate = [store objectForKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
        if(lastFetchDate){
            return ![self isTodaySameAsDate:lastFetchDate];
        }
    } else {
        NSDate *lastFetchDateForNonRegisteredUser = [store objectForKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME_UNKNOWN_USER];
        if(lastFetchDateForNonRegisteredUser){
            return ![FCUtilities isSameDate:lastFetchDateForNonRegisteredUser excludeDay:true];
        }
    }
    return true;
}

+ (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];

    switch (c) {
    case 0xFF:
        return @"image/jpeg";
    case 0x89:
        return @"image/png";
    case 0x47:
        return @"image/gif";
    case 0x49:
    case 0x4D:
        return @"image/tiff";
    }
    return nil;
}

+(BOOL) containsHTMLContent: (NSString *)content {
    if (([FCUtilities containsString:content andTarget:@"<b>"])
        || ([FCUtilities containsString:content andTarget:@"<i>"])
        || ([FCUtilities containsString:content andTarget:@"<span"])
        || ([FCUtilities containsString:content andTarget:@"<p>"])
        || ([FCUtilities containsString:content andTarget:@"<div>"])
        || ([FCUtilities containsString:content andTarget:@"<u>"])
        || ([FCUtilities containsString:content andTarget:@"&lt"])
        || ([FCUtilities containsString:content andTarget:@"&gt"])
        || ([FCUtilities containsString:content andTarget:@"&nbsp"])
        || ([FCUtilities containsString:content andTarget:@"<a href"])
        || ([FCUtilities containsString:content andTarget:@"<a>"])
        || ([FCUtilities containsString:content andTarget:@"<h1>"])
        || ([FCUtilities containsString:content andTarget:@"<h2>"])
        || ([FCUtilities containsString:content andTarget:@"<h3>"])
        || ([FCUtilities containsString:content andTarget:@"<h4>"])
        || ([FCUtilities containsString:content andTarget:@"<h5>"])
        || ([FCUtilities containsString:content andTarget:@"<h6>"])) {
        return true;
    }
    return false;
}

+(BOOL) containsString: (NSString *)original andTarget:(NSString *)target {
    if([original rangeOfString:target].location == NSNotFound) {
        return false;
    }
    return true;
}

+(NSString *) appendFirstName :(NSString *)firstName withLastName:(NSString *) lastName{
    NSString *spaceStr = @"";
    if ((firstName.length) && (lastName.length)){
        spaceStr = @" ";
    }
    NSString* fName = firstName ? firstName : @"";
    NSString* lName = lastName ? lastName : @"";
    return ([@[fName, spaceStr, lName] componentsJoinedByString:@""]);
}

+ (void) loadImageAndPlaceholderBgWithUrl:(NSString *)url forView:(UIImageView *)imageView withColor: (UIColor*)color andName:(NSString *)channelName {
    imageView.image = [FCUtilities generateImageForLabel:channelName withColor:color];
    if (url.length){//check if its valid but empty stringas well as if it's nil, since calling length on nil will also return 0
        [FCUtilities loadImageWithUrl:url forView:imageView andErrorImage:nil];
    }
}

+ (void) loadImageWithUrl : (NSString *) url forView : (UIImageView *) imgView andErrorImage:(UIImage *)errorImage{
    FDWebImageManager *manager = [FDWebImageManager sharedManager];
    [manager loadImageWithURL:[NSURL URLWithString:url] options:FDWebImageDelayPlaceholder progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, FDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([imgView isKindOfClass:[FCAnimatedImageView class]] && data &&  [[FCUtilities contentTypeForImageData:data] isEqualToString:@"image/gif"]) {
                FCAnimatedImageView *animatedImageView = (FCAnimatedImageView *)imgView;
                animatedImageView.animatedImage = [FCAnimatedImage animatedImageWithGIFData: data];
            }
            else if(imgView){
                imgView.image = image;
            } else if(errorImage) {
                imgView.image = errorImage;
            }
        });
    }];
}

+ (void) cacheImageWithUrl : (NSString *) url {
    FDWebImageManager *manager = [FDWebImageManager sharedManager];
    [manager loadImageWithURL:[NSURL URLWithString:url] options:FDWebImageDelayPlaceholder progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, FDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        FDLog(@"Image cached - %@", imageURL);
    }];
}

+(UIImage *)generateImageForLabel:(NSString *)labelText withColor :(UIColor *)color{
    FCTheme *theme = [FCTheme sharedInstance];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    NSString *firstLetter = [labelText substringToIndex:1];
    firstLetter = [firstLetter uppercaseString];
    label.text = firstLetter;
    label.font = [theme channelIconPlaceholderImageCharFont];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = color;
    label.layer.cornerRadius = label.frame.size.height / 8.0f;
    label.clipsToBounds = YES;
    
    UIGraphicsBeginImageContextWithOptions(label.frame.size, NO, 0.0);
    
    [[label layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (FCBarButtonItem *) getCloseBarBtnItemforCtr : (id) ctr withSelector:(SEL) selector{
     return [[FCBarButtonItem alloc] initWithImage:[[FCTheme sharedInstance] getImageWithKey:IMAGE_SOLUTION_CLOSE_BUTTON]
                                                                                            style:UIBarButtonItemStylePlain
                                                                                           target:ctr
                                                                                           action:selector];
}

+(NSString *) getLocalizedPositiveFeedCSATQues{
    return ([FCLocalization isNotEmpty:LOC_MESSAGES_AGENT_LABEL_TEXT] ? HLLocalizedString(LOC_CSAT_CHAT_RESOLUTION_QUESTION_TEXT) : nil);
}

+(NSMutableAttributedString *) getAttributedContentForString :(NSString *)strVal withFont :(UIFont *) font{
    NSMutableAttributedString *atbString = [[NSMutableAttributedString alloc] init];;
    NSMutableAttributedString *str = [[FCAttributedText sharedInstance] getAttributedString:strVal];
    if(str == nil) {
        NSMutableAttributedString *content = [[FCAttributedText sharedInstance] addAttributedString:strVal withFont:font];
        atbString = content;
    } else {
        atbString = str;
    }
    return atbString;
}

+(NSString*)deviceModelName{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSDictionary *commonNamesDictionary =
    @{
      @"i386":     @"iOS Simulator",
      @"x86_64":   @"iOS Simulator",
      
      @"iPhone1,1":    @"iPhone",
      @"iPhone1,2":    @"iPhone 3G",
      @"iPhone2,1":    @"iPhone 3GS",
      @"iPhone3,1":    @"iPhone 4",
      @"iPhone3,2":    @"iPhone 4(Rev A)",
      @"iPhone3,3":    @"iPhone 4(CDMA)",
      @"iPhone4,1":    @"iPhone 4S",
      @"iPhone5,1":    @"iPhone 5(GSM)",
      @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
      @"iPhone5,3":    @"iPhone 5c(GSM)",
      @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
      @"iPhone6,1":    @"iPhone 5s(GSM)",
      @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
      @"iPhone7,1":    @"iPhone 6 Plus",
      @"iPhone7,2":    @"iPhone 6",
      @"iPhone8,1":    @"iPhone 6s",
      @"iPhone8,2":    @"iPhone 6s Plus",
      @"iPhone8,4":    @"iPhone SE",
      @"iPhone9,1":    @"iPhone 7",
      @"iPhone9,3":    @"iPhone 7",
      @"iPhone9,2":    @"iPhone 7 Plus",
      @"iPhone9,4":    @"iPhone 7 Plus",
      @"iPhone10,1":   @"iPhone 8",
      @"iPhone10,4":   @"iPhone 8",
      @"iPhone10,2":   @"iPhone 8 Plus",
      @"iPhone10,5":   @"iPhone 8 Plus",
      @"iPhone10,3":   @"iPhone X",
      @"iPhone10,6":   @"iPhone X",
      @"iPhone11,2":   @"iPhone XS",
      @"iPhone11,4":   @"iPhone XS Max",
      @"iPhone11,6":   @"iPhone XS Max",
      @"iPhone11,8":   @"iPhone XR",
      @"iPhone12,1":   @"iPhone 11",
      @"iPhone12,3":   @"iPhone 11 Pro",
      @"iPhone12,5":   @"iPhone 11 Pro Max",
      
      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2(WiFi)",
      @"iPad2,2":  @"iPad 2(GSM)",
      @"iPad2,3":  @"iPad 2(CDMA)",
      @"iPad2,4":  @"iPad 2(WiFi Rev A)",
      @"iPad2,5":  @"iPad Mini 1st Gen(WiFi)",
      @"iPad2,6":  @"iPad Mini 1st Gen(GSM)",
      @"iPad2,7":  @"iPad Mini 1st Gen(GSM+CDMA)",
      @"iPad3,1":  @"iPad 3(WiFi)",
      @"iPad3,2":  @"iPad 3(GSM+CDMA)",
      @"iPad3,3":  @"iPad 3(GSM)",
      @"iPad3,4":  @"iPad 4(WiFi)",
      @"iPad3,5":  @"iPad 4(GSM)",
      @"iPad3,6":  @"iPad 4(GSM+CDMA)",
      @"iPad4,1":  @"iPad Air(WiFi)",
      @"iPad4,2":  @"iPad Air(WiFi+Cellular)",
      @"iPad4,3":  @"iPad Air(WiFi+LTE - China)",
      @"iPad4,4":  @"iPad Mini 2(WiFi)",
      @"iPad4,5":  @"iPad Mini 2(WiFi+Cellular)",
      @"iPad4,6":  @"iPad Mini 2(WiFi+Cellular - China)",
      @"iPad4,7":  @"iPad Mini 3(WiFi)",
      @"iPad4,8":  @"iPad Mini 3(WiFi+Cellular)",
      @"iPad4,9":  @"iPad Mini 3(WiFi+Cellular - China)",
      @"iPad5,1":  @"iPad mini 4",
      @"iPad5,2":  @"iPad mini 4",
      @"iPad5,3":  @"iPad Air 2(WiFi)",
      @"iPad5,4":  @"iPad Air 2(WiFi+Cellular)",
      @"iPad6,7":  @"iPad Pro (12.9 inch)",
      @"iPad6,8":  @"iPad Pro (12.9 inch)",
      @"iPad6,3":  @"iPad Pro (9.7 inch)",
      @"iPad6,4":  @"iPad Pro (9.7 inch)",
      @"iPad6,11": @"iPad (2017)",
      @"iPad6,12": @"iPad (2017)",
      @"iPad7,1":  @"iPad Pro 12.9 Inch 2. Generation",
      @"iPad7,2":  @"iPad Pro 12.9 Inch 2. Generation",
      @"iPad7,3":  @"iPad Pro 10.5 Inch",
      @"iPad7,4":  @"iPad Pro 10.5 Inch",
      @"iPad7,5":  @"iPad 6th Gen (WiFi)",
      @"iPad7,6":  @"iPad 6th Gen (WiFi+Cellular)",
      @"iPad7,11": @"iPad 7th Gen 10.2-inch (WiFi)",
      @"iPad7,12": @"iPad 7th Gen 10.2-inch (WiFi+Cellular)",
      @"iPad8,1":  @"iPad Pro 3rd Gen (11 inch, WiFi)",
      @"iPad8,2":  @"iPad Pro 3rd Gen (11 inch, 1TB, WiFi)",
      @"iPad8,3":  @"iPad Pro 3rd Gen (11 inch, WiFi+Cellular)",
      @"iPad8,4":  @"iPad Pro 3rd Gen (11 inch, 1TB, WiFi+Cellular)",
      @"iPad8,5":  @"iPad Pro 3rd Gen (12.9 inch, WiFi)",
      @"iPad8,6":  @"iPad Pro 3rd Gen (12.9 inch, 1TB, WiFi)",
      @"iPad8,7":  @"iPad Pro 3rd Gen (12.9 inch, WiFi+Cellular)",
      @"iPad8,8":  @"iPad Pro 3rd Gen (12.9 inch, 1TB, WiFi+Cellular)",
      @"iPad11,1": @"iPad mini 5th Gen (WiFi)",
      @"iPad11,2": @"iPad mini 5th Gen",
      @"iPad11,3": @"iPad Air 3rd Gen (WiFi)",
      @"iPad11,4": @"iPad Air 3rd Gen",
      
      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",
      @"iPod7,1":  @"iPod 6th Gen",
      @"iPod9,1":  @"iPod 7th Gen",
      };
    NSString *deviceName = commonNamesDictionary[machineName];
    if (!deviceName) { deviceName = machineName; }
    return deviceName;
}

+(BOOL)isiOS10{
    return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0");
}

+ (BOOL)isVerLessThaniOS13 {
    return SYSTEM_VERSION_LESS_THAN(@"13.0");
}

+(void)initiatePendingTasks{
    [FCLocalNotification post:HOTLINE_NOTIFICATION_PERFORM_PENDING_TASKS];
}

+(BOOL)hasInitConfig{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSManagedObjectContext *ctx = [FCDataManager sharedInstance].mainObjectContext;
    return [store checkItemWithKey:HOTLINE_DEFAULTS_APP_ID] && [store checkItemWithKey:HOTLINE_DEFAULTS_APP_KEY] && ctx != nil;
}

+(void) resetAlias {
    [FCUtilities removeUUID];
    NSString *newAlias = [FCUtilities generateUserAlias];
    [[FCSecureStore sharedInstance] setObject:newAlias forKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    FDLog(@"Created new alias: %@",newAlias);
}



+(void) resetDataAndRestoreWithExternalID: (NSString *) externalID withRestoreID: (NSString *)restoreID withCompletion:(void (^)())completion {
    [FCCoreServices resetUserData:^{
        [[FCEventsManager sharedInstance] reset];
        [[FCSecureStore sharedInstance] setBoolValue:NO forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
        [FCUserDefaults removeObjectForKey:HOTLINE_DEFAULTS_IS_MESSAGE_SENT];        
        FreshchatUser* oldUser = [FreshchatUser sharedInstance];
        oldUser.externalID = externalID;
        oldUser.restoreID = restoreID;
        [FCUsers storeUserInfo:oldUser];
        [FCCoreServices restoreUserWithExtId:externalID restoreId:restoreID withCompletion:nil];
        if(completion) {
            completion();
        }
    }];
}

+(void) resetDataAndRestoreWithJwtToken: (NSString *) jwtIdToken withCompletion:(void (^)())completion {
     [FCCoreServices resetUserData:^{
         [[FCSecureStore sharedInstance] setBoolValue:NO forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
         [FCUserDefaults removeObjectForKey:HOTLINE_DEFAULTS_IS_MESSAGE_SENT];
         FreshchatUser* oldUser = [FreshchatUser sharedInstance];
         [FCUsers storeUserInfo:oldUser];
         [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_NOT_SET];
         if([[FCSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_APP_ID] && [[FCSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_APP_KEY]){
             [FCCoreServices restoreUserWithJwtToken:jwtIdToken withCompletion:nil];
         }
         if(completion) {
             completion();
         }
     }];
}

+ (BOOL) canMakeConversationFetchCall {
    if([[FCRemoteConfig sharedInstance] isActiveConvAvailable]){
        NSNumber * messageFetchLastUpdatedTime = [FCUtilities getLastUpdatedTimeForKey:FC_CONVERSATIONS_LAST_REQUESTED_TIME];
        
        if(!messageFetchLastUpdatedTime){
            // if first time, fetch now
            return TRUE;
        }
        
        NSTimeInterval activeConvFetch = [FCRemoteConfig sharedInstance].refreshIntervals.msgFetchIntervalNormal;
        if(([FCUtilities getCurrentTimeInMillis] - [messageFetchLastUpdatedTime longValue]) > activeConvFetch){
            return TRUE;
        }
    }
    return FALSE;
}

+(void) updateUserWithExternalID: (NSString *) externalID withRestoreID: (NSString *)restoreID {
    FreshchatUser *currentUser = [FreshchatUser sharedInstance];
    if (currentUser && restoreID && externalID) {
        if ( ![restoreID isEqualToString:currentUser.restoreID]
            || ![externalID isEqualToString:currentUser.externalID]) {
            currentUser.restoreID = restoreID;
            currentUser.externalID = externalID;
            [FCUsers storeUserInfo:currentUser];
            [FCLocalNotification post:FRESHCHAT_USER_RESTORE_ID_GENERATED info:@{}];
        }
    }
}


+ (void) updateUserWithData : (NSDictionary*) userDict{
    FreshchatUser *user = [FreshchatUser sharedInstance];
    if(userDict[@"firstName"]){
        user.firstName = userDict[@"firstName"];
    }
    if(userDict[@"lastName"]){
        user.lastName = userDict[@"lastName"];
    }
    if(userDict[@"email"]){
        user.email = userDict[@"email"];
    }
    if(userDict[@"phone"]){
        user.phoneNumber = userDict[@"phone"];
    }
    if(userDict[@"phoneCountry"]){
        user.phoneCountryCode = userDict[@"phoneCountry"];
    }
    if(userDict[@"identifier"]){
        user.externalID = userDict[@"identifier"];
    }
    if(userDict[@"restoreId"]){
        user.restoreID = userDict[@"restoreId"];
    }
    if(userDict[@"jwtUserAuthToken"]){
        user.jwtToken = userDict[@"jwtUserAuthToken"];
    }
    [FCUsers storeUserInfo:user];
    [self updateUserAlias: userDict[@"alias"]];
}

+(void)postUnreadCountNotification{
    dispatch_async(dispatch_get_main_queue(), ^{
        [FCUtilities unreadCountInternalHandler:^(NSInteger count) {
            [FCLocalNotification post:FRESHCHAT_UNREAD_MESSAGE_COUNT_CHANGED info:@{}];
        }];
    });
}

+ (BOOL) isPoweredByFooterViewHidden{
    //#include both changes server check and internal md5 check also :)
    //TODO: Add remote config for footer banner
    /*BOOL showFreshchatBrandBanner = [[[FCRemoteConfig sharedInstance] enabledFeatures] showCustomBrandBanner];
    return (!showFreshchatBrandBanner && [self isPoweredByHidden]);*/
    
    return [self isPoweredByHidden];
}

+ (BOOL) hasNotchDisplay{
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone) {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 2436: //X, XS
            case 2688: //XS Max
            case 1792: //XR
                return true;
            default:
                return false;
        }
    }
    return false;
}

+ (BOOL)isDeviceLanguageRTL {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")){
        return ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft);
    }
    return false;
}

+(BOOL)isValidUUIDForKey : (NSString *)key
{
    return (bool)[[NSUUID alloc] initWithUUIDString:key];
}
//Update account state, Caution : use "Yes" carefully
+ (void) updateAccountDeletedStatusAs :(BOOL) state{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    [store setBoolValue:state forKey:FRESHCHAT_DEFAULTS_IS_ACCOUNT_DELETED];
}

+ (BOOL) isAccountDeleted{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    return (BOOL)[store boolValueForKey:FRESHCHAT_DEFAULTS_IS_ACCOUNT_DELETED];
}

+ (void) processResetChanges {
    [FreshchatUser sharedInstance].isRestoring = false;
    [FCLocalNotification post:FRESHCHAT_USER_RESTORE_STATE info:@{@"state":@1}];
    [[FCSecureStore sharedInstance] removeObjectWithKey:FRESHCHAT_DEFAULTS_IS_FIRST_AUTH];
}

+ (void) handleGDPRForResponse :(FCResponseInfo *)responseInfo {
    if([[responseInfo responseAsDictionary][@"errorCode"] integerValue] == ERROR_CODE_ACCOUNT_DELETED) {
        [self updateAccountDeletedStatusAs:TRUE];
        [[Freshchat sharedInstance] resetUserWithCompletion:^{
            [FCLocalNotification post:FRESHCHAT_ACCOUNT_DELETED_EVENT];
        }];
    } else {
        [[Freshchat sharedInstance] resetUserWithCompletion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[Freshchat sharedInstance] dismissFreshchatViews];
            });
        }];
    }
}

+(void)unreadCountInternalHandler:(void (^)(NSInteger count))completion{
    [[FCDataManager sharedInstance]fetchAllVisibleChannelsWithCompletion:^(NSArray *channelInfos, NSError *error) {
        NSInteger result = 0;
        for (FCChannelInfo *channel in channelInfos) {
            if (channel.unreadMessages > 0) result = result + channel.unreadMessages;
        }
        completion(result);
    }];
}

+(UIColor *) invertColor :(UIColor *)color {
    const CGFloat *componentColors = CGColorGetComponents(color.CGColor);
    return [[UIColor alloc] initWithRed:(1.0 - componentColors[0])
                                               green:(1.0 - componentColors[1])
                                                blue:(1.0 - componentColors[2])
                                               alpha:componentColors[3]];
}

#pragma add regex expressions

+ (NSString *) applyRegexForInputText :(NSString *) inputText {
    NSArray *freshchatRegexArray = [FCRemoteConfig sharedInstance].messageMaskConfig.messageMasks;
    
    for (NSDictionary *dict in freshchatRegexArray) {
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[dict objectForKey:@"regex"] options:0 error:&error];
        NSRange searchedRange = NSMakeRange(0, [inputText length]);
        
        NSArray* matches = [regex matchesInString:inputText options:0 range: searchedRange];
        for (NSTextCheckingResult* match in [matches reverseObjectEnumerator]) {
            NSString* matchText = [inputText substringWithRange:[match range]];
            inputText = [inputText stringByReplacingCharactersInRange:[match range] withString:[self replaceMatchString:matchText withString:[dict objectForKey:@"replacementStr"]]];
        }
    }
    return inputText;
}

+ (NSString *) replaceMatchString : (NSString *)matchStr withString : (NSString *)replaceStr{
    if(replaceStr) {
        if(replaceStr.length > 1){
            return replaceStr;
        }
        else{
            return [[NSString new] stringByPaddingToLength:[matchStr length] withString:replaceStr startingAtIndex:0];
        }
    }
    return [[NSString new] stringByPaddingToLength:[matchStr length] withString:@"*" startingAtIndex:0];
}

+ (void) updateCurrentTimeForKey : (NSString *) keyName {
    [[FCSecureStore sharedInstance] setObject:[NSNumber numberWithLong: [[NSDate date] timeIntervalSince1970] * 1000] forKey:keyName];
}

+ (void) addFlagToDisableUserPropUpdate {
    [[FCSecureStore sharedInstance] setBoolValue:TRUE forKey:FRESHCHAT_DEFAULTS_DROP_UPDATE_USER_PROPERTIES];
}

+ (void) removeFlagToDisableUserPropUpdate {
    [[FCSecureStore sharedInstance] setBoolValue:FALSE forKey:FRESHCHAT_DEFAULTS_DROP_UPDATE_USER_PROPERTIES];
}

+ (BOOL) canUpdateUserProperties {
    return ![[FCSecureStore sharedInstance] boolValueForKey:FRESHCHAT_DEFAULTS_DROP_UPDATE_USER_PROPERTIES];
}

+(BOOL) handleLink : (NSURL *)url faqOptions: (FAQOptions *)faqOptions
    navigationController:(UIViewController *) navController
    handleFreshchatLinks:(BOOL) handleFreshchatLinks
    postOutboundEvent:(BOOL) postOutboundEvent {
    
    if(url == nil) {
        return NO;
    }
    
    if ([[url scheme] caseInsensitiveCompare:@"freshchat"] == NSOrderedSame ) {
        if (([[url host] caseInsensitiveCompare:@"faq"] == NSOrderedSame) &&
            ([[url path] caseInsensitiveCompare:@"/article"] == NSOrderedSame)) {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            NSNumber *articleID = [[NSNumber alloc] initWithInt:-1];
            for (NSURLQueryItem *queryItem in [urlComponents queryItems]) {
                if (queryItem.value == nil) {
                    continue;
                }
                if ([queryItem.name isEqualToString:@"article_id"]) {
                    articleID = [[NSNumber alloc] initWithInteger:[queryItem.value integerValue]];
                    break;
                }
            }
            if(articleID.integerValue != -1) {                
                [FCFAQUtil launchArticleID:articleID withNavigationCtlr:navController andFaqOptions:faqOptions fromLink:true];
                return YES;
            }
        } else if (([[url host] caseInsensitiveCompare:@"channels"] == NSOrderedSame)) {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            NSArray *tags;
            NSNumber *channelID;
            NSString *title;
            for (NSURLQueryItem *queryItem in [urlComponents queryItems]) {
                if (queryItem.value == nil) {
                    continue;
                }
                if ([queryItem.name isEqualToString:@"tags"]) {
                    NSMutableArray *tagsArr =[[NSMutableArray alloc] initWithArray:[queryItem.value componentsSeparatedByString:@","]];
                    tags = [FCUtilities convertTagsArrayToLowerCase:tagsArr];
                }
                
                if ([queryItem.name isEqualToString:@"id"]) {
                    channelID = [[NSNumber alloc]initWithInteger:[queryItem.value integerValue]];
                }
                if ([queryItem.name isEqualToString:@"title"]) {
                    title = queryItem.value;
                }
            }
            if (tags!=nil) {
                [FCChannelUtil launchChannelWithTags:tags withTitle:title withNavigationCtlr:navController];
                return YES;
            } else if(channelID!=nil) {
                [FCChannelUtil launchChannelWithId:channelID withTitle:title withNavigationCtlr:navController];
                return YES;
            }
        } else {
            return YES;
        }
    } else if(([[url scheme] caseInsensitiveCompare:@"faq"] == NSOrderedSame))  {
        NSNumberFormatter *numbFormatter = [[NSNumberFormatter alloc] init];
        NSNumber *articleId = [numbFormatter numberFromString:[url host]];
        if (articleId!= nil) {
            [FCFAQUtil launchArticleID:articleId withNavigationCtlr:navController andFaqOptions:faqOptions fromLink:true];
            return YES;
        }
    } else if(!handleFreshchatLinks) {
        if(postOutboundEvent) {
            FCOutboundEvent *outEvent = [[FCOutboundEvent alloc] initOutboundEvent:FCEventLinkTap
                                                                      withParams:@{
                                                                                   @(FCPropertyURL)  : url.absoluteString
                                                                                   }];
            [FCEventsHelper postNotificationForEvent:outEvent];
        }
        
    }
    if ([Freshchat sharedInstance].customLinkHandler != nil) {
        return [Freshchat sharedInstance].customLinkHandler(url);
    }
    return NO;
}

+ (NSString *) getSDKThemeName {
    FCSecureStore *store = [FCSecureStore sharedInstance];
    if([store objectForKey:HOTLINE_DEFAULTS_THEME_NAME]){
        return [store objectForKey:HOTLINE_DEFAULTS_THEME_NAME];
    } else {
        return  [store objectForKey: FD_DEFAULT_THEME_NAME];
    }
}

+(void) loadImageFromURL:(NSString  * _Nonnull)imageURL withCache:(void (^ _Nullable)())cacheBlock withError:(void (^ _Nullable)())errorBlock withCompletion:(void (^_Nullable)(UIImage * _Nonnull))completionBlock {
    [[FDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:imageURL] completion:^(BOOL isInCache) {
        if(isInCache) {
            cacheBlock();
        }
        else {
            FDWebImageManager *manager = [FDWebImageManager sharedManager];
            [manager loadImageWithURL:[NSURL URLWithString:imageURL] options:FDWebImageDelayPlaceholder progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, FDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                if (error) {
                    errorBlock();
                } else {
                    if(image && finished){
                        completionBlock(image);
                    }
                }
            }];
        }
    }];
}

@end


@implementation NSString(UtilMethods)

-(BOOL) isTemplateFragment {
    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    NSDictionary *jsonDict = jsonArray.firstObject;
    if(jsonDict && ![jsonDict isKindOfClass:[NSNull class]] && jsonDict[@"fragmentType"]) {
        if ([jsonDict[@"fragmentType"] integerValue] == FRESHCHAT_TEMPLATE_FRAGMENT) {
            return YES;
        }
    }
    return NO;
}

-(NSDictionary *)dictionaryValue {
    NSData *fragmentData = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:fragmentData options:0 error:nil];    
}
@end
