//
//  FreshchatSDKTest.m
//  FreshchatSDKTest
//
//  Created by Hemanth Kumar on 24/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FCTemplateFactory.h"
#import "FCCalendarModel.h"
#import "FCDateUtil.h"
#import "FCUtilities.h"
#import "FCDropDownViewModel.h"
#import "FCUtilities.h"
#import <OCMock/OCMock.h>
#import "FCUserDefaults.h"
#import "FCStringUtil.h"
#import "FCMessageController.h"
#import "FCLocalization.h"
#import "FCTheme.h"
#import "FCEventsHelper.h"
#import "FCOutboundEvent.h"
#import "FCSecureStore.h"
#import "FCRemoteConfig.h"
#import "FCMemLogger.h"
#import "FCLocalNotification.h"
#import "FCReachabilityManager.h"
#import "FCAttributedText.h"
#import "FCConversationUtil.h"
#import "FCFAQUtil.h"
#import "FCJWTUtilities.h"
#import "FCFooterView.h"
#import "FCMessages.h"
#import "FCReachability.h"
#import "FCListViewController.h"
#import "FCEventsConstants.h"
#import "FreshchatSDK.h"
#import "FCEventsManager.h"
#import "FCYesNoPromptView.h"
#import "FCPromptView.h"
#import "FCAgentMessageCell.h"
#import "FCCSATView.h"
#import "FCLocaleUtil.h"
#import "FCIndexManager.h"
#import "FCCalendarViewController.h"
#import "FCVotingManager.h"
#import "FCArticleDetailViewController.h"
#import "FCCategoryGridViewController.h"
#import "FCCategoryListController.h"
#import "FCJWTAuthValidator.h"
#import "FCTags.h"
#import "FCServiceRequest.h"
#import "FCAPI.h"
#import "FCAPIClient.h"

@interface FCUtilities (Test)
+ (NSString*)convertIntoMD5 :(NSString *) str;
+ (NSString *) replaceMatchString : (NSString *)matchStr withString : (NSString *)replaceStr;
@end

@interface Freshchat (Test)
- (NSString *)validateDomain:(NSString*)domain;
- (BOOL)cannotMakeUserCalls;
- (BOOL)isDeviceTokenUpdated:(NSString *)newToken;
- (BOOL)hasUpdatedConfig:(FreshchatConfig *)config;
- (NSDictionary *) getPreviousUserConfig;

@end

@interface FCEventsManager (Test)
- (NSNumber *)nextEventId;
@end

@interface FCYesNoPromptView (Test)
-(CGFloat)getPromptHeight;
@end

@interface FCAgentMessageCell (Test)
-(NSString *) getLocalizedAgentName;
-(BOOL) isTopFragment :(NSArray *)array currentIndex:(int)currentIndex;
@end

@interface FCCSATView (Test)
-(UIView *)createStarRatingView;
@end

@interface FCLocaleUtil (Test)
+(NSArray *)userLocaleParams:(BOOL)voteReq;
@end

@interface FCMemLogger (Test)
-(NSString *)getApplicationState;
-(NSString *)getUserSessionId;
@end

@interface FCIndexManager (Test)
+(NSString *) stringByStrippingHTML:(NSString *)stringContent;
@end

@interface FCCalendarViewController (Test)
@property (nonatomic, strong) NSDictionary* slotsResponseDict;
- (long) getMeetingEndMillisForStartTime :(NSNumber *) startTime;
@end

@interface FCMessageController (Test)
- (BOOL) checkIfResponseLabelIsEmpty;
- (NSMutableDictionary *) getChannelReplyTimeForResponse : (NSArray *)convArr;
- (float)lineCountForLabel:(UILabel *)label;
- (BOOL) isCalendarMsg : (FCMessageData *)msg;
- (NSString *)emptyText;
- (NSString *)loadingText;
- (NSString *)getIdentityForMessage:(FCMessageData *)message;
@end

@interface FCArticleDetailViewController (Test)
-(NSString *)fixLinksForiOS9:(NSString *) content;
-(NSString *)offLineMessageForContent:(NSString *) content;
@end

@interface FCCategoryGridViewController (Test)
-(NSString *)emptyText;
-(NSString *)loadingText;
@end

@interface FCCategoryListController (Test)
-(NSString *)emptyText;
-(NSString *)loadingText;
@end

@interface FreshchatSDKTest : XCTestCase

@end

@implementation FreshchatSDKTest

- (void)setUp {
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithAbbreviation:@"IST"];
    [NSTimeZone setDefaultTimeZone:timeZone];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(userActionEvent:)
        name:FRESHCHAT_EVENTS
      object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(notifReceived:)
        name:@"TEST_NOTIF"
      object:nil];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}


- (void)testDropDownFragmentData {
    NSString * replyFragments  = @"{\"position\": 0,\"fragmentType\": 1002,\"templateType\": \"quick_reply_dropdown\",\"sections\":[{\"name\": \"options\",\"fragments\": [{\"label\": \"Google\",\"position\": 0,\"contentType\": \"text/vnd.reply\",\"fragmentType\": 51,\"customReplyText\": \"Google\",\"payload\": \"123_google\"},{\"label\": \"Yahoo\",\"position\": 0,\"contentType\": \"text/vnd.reply\",\"fragmentType\": 51,\"customReplyText\": \"Yahoo\"},{\"label\": \"Reddit\",\"position\": 0,\"contentType\": \"text/vnd.reply\",\"fragmentType\": 51,\"customReplyText\": \"Reddi\"}]}]}";
    [self checkdropDownFragmentDataForString:replyFragments checkBack:true];
}

- (void)testCarouselFragmentData {
    NSString * replyFragments  = @" { \"position\": 0, \"sections\": [ {\"name\": \"carousel_title\", \"fragments\": [ { \"content\": \"Hello choose one of following...\",\"position\": 0, \"contentType\": \"text/html\",\"fragmentType\": 1 }] },{\"name\": \"cards\",\"fragments\": [{\"position\": 0,\"sections\": [ { \"name\": \"hero_image\",\"fragments\": [ {\"width\": 0,\"height\": 0,\"position\": 0, \"contentType\": \"application/octet-stream\", \"fragmentType\": 2 }] }, { \"name\": \"title\", \"fragments\": [ {\"content\": \"This is title\",\"position\": 0, \"contentType\": \"text/html\",\"fragmentType\": 1 }] }, { \"name\": \"description\",\"fragments\": [ {\"content\": \"This is description\",\"position\": 0, \"contentType\": \"text/html\", \"fragmentType\": 1} ] }, {\"name\": \"callback\", \"fragments\": [ { \"label\": \"callback\", \"payload\": \"thisispayload\", \"position\": 0,\"fragmentType\": 52 } ] },{\"name\": \"view\",\"fragments\": [ {\"label\": \"google\",\"target\": \"_blank\",\"content\": \"http://google.com\",\"position\": 0,\"contentType\": \"text/vnd.submit-form\",\"fragmentType\": 5 }]}],\"fragmentType\": 1002, \"templateType\": \"carousel_card_default\" }, {\"position\": 0,\"sections\": [ {\"name\": \"hero_image\", \"fragments\": [ {\"width\": 0,\"height\": 0,\"position\": 0,\"contentType\": \"application/octet-stream\", \"fragmentType\": 2} ]},{\"name\": \"title\",\"fragments\": [ {\"content\": \"This is title\",\"position\": 0,\"contentType\": \"text/html\",\"fragmentType\": 1 } ] },{\"name\": \"description\",\"fragments\": [ { \"content\": \"This is description\",\"position\": 0,\"contentType\": \"text/html\", \"fragmentType\": 1} ] },{\"name\": \"callback\",\"fragments\": [{\"label\": \"callback\",\"payload\": \"thisispayload\", \"position\": 0, \"fragmentType\": 52 } ] },{ \"name\": \"view\",\"fragments\": [{\"label\": \"google\",\"target\": \"_blank\",\"content\": \"http://google.com\",\"position\": 0, \"contentType\": \"text/vnd.submit-form\",\"fragmentType\": 5}] }],\"fragmentType\": 1002,\"templateType\": \"carousel_card_default\" }] } ], \"fragmentType\": 1002, \"templateType\": \"carousel\"  }";
    [self checkCarouselFragmentDataForString:replyFragments checkBack:true];
}

- (void)checkdropDownFragmentDataForString:(NSString*) replyFragments checkBack:(BOOL) shouldCheckBack {
    NSData *data = [replyFragments dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary* replyDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:0
                                                                    error:&error];
    TemplateFragmentData *fragmentData = [[TemplateFragmentData alloc] initWith:replyDictionary];
    XCTAssertTrue(fragmentData != nil);
    XCTAssertTrue([fragmentData.templateType isEqualToString:@"quick_reply_dropdown"]);
    XCTAssertTrue([fragmentData.section count] == 1);
    XCTAssertTrue([fragmentData.section.firstObject.fragments count] == 3);
    XCTAssertTrue([fragmentData.section.firstObject.name isEqualToString:@"options"]);
    XCTAssertTrue([fragmentData.section.firstObject.fragments.firstObject isKindOfClass:[FragmentData class]]);
    
    FCDropDownViewModel *dropDownModel = [[FCDropDownViewModel alloc] initWithFragment: fragmentData inReplyTo:@(1)];
    XCTAssertTrue(dropDownModel.options.count == 3);
    XCTAssertTrue([dropDownModel.options.firstObject.label isEqualToString:@"Google"]);
    XCTAssert([dropDownModel.options[1].label isEqualToString:@"Yahoo"]);
    XCTAssert([dropDownModel.options[2].label isEqualToString:@"Reddit"]);
    
    if (shouldCheckBack) {
        NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:fragmentData.dictionaryValue options:0 error:&error];
        NSString * fragment = [[NSString alloc] initWithData:jsonData   encoding:NSUTF8StringEncoding];
        [self checkdropDownFragmentDataForString:fragment checkBack:false];
    }
}

- (void)checkCarouselFragmentDataForString:(NSString*) replyFragments checkBack:(BOOL) shouldCheckBack {
    NSData *data = [replyFragments dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary* replyDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:0
                                                                    error:&error];
    TemplateFragmentData *fragmentData = [[TemplateFragmentData alloc] initWith:replyDictionary];
    XCTAssertTrue(fragmentData != nil);
    XCTAssertTrue([fragmentData.section count] == 2);
    XCTAssertTrue([fragmentData.templateType isEqualToString:@"carousel"]);
    
    XCTAssertTrue([fragmentData.section.firstObject.fragments count] == 1);
    XCTAssertTrue([fragmentData.section.firstObject.name isEqualToString:@"carousel_title"]);
    XCTAssertTrue([fragmentData.section.firstObject.fragments.firstObject isKindOfClass:[FragmentData class]]);
    XCTAssertTrue([fragmentData.section.firstObject.fragments.firstObject isKindOfClass:[FragmentData class]]);
    
    XCTAssertTrue([fragmentData.section[1].name isEqualToString:@"cards"]);
    XCTAssertTrue([fragmentData.section[1].fragments.firstObject isKindOfClass:[TemplateFragmentData class]]);
    XCTAssertTrue([fragmentData.section[1].fragments count] == 2);
    
    TemplateFragmentData *templateFragment = (TemplateFragmentData*)fragmentData.section[1].fragments.firstObject;
    XCTAssertTrue(templateFragment.section.count ==5);
    XCTAssertTrue([templateFragment.section[0].name isEqualToString:@"hero_image"]);
    XCTAssertTrue([templateFragment.section[0].fragments.firstObject isKindOfClass:[FragmentData class]]);
    XCTAssertTrue([templateFragment.section[1].name isEqualToString:@"title"]);
    XCTAssertTrue([templateFragment.section[1].fragments.firstObject isKindOfClass:[FragmentData class]]);
    XCTAssertTrue([templateFragment.section[2].name isEqualToString:@"description"]);
    XCTAssertTrue([templateFragment.section[2].fragments.firstObject isKindOfClass:[FragmentData class]]);
    XCTAssertTrue([templateFragment.section[3].name isEqualToString:@"callback"]);
    XCTAssertTrue([templateFragment.section[3].fragments.firstObject isKindOfClass:[FragmentData class]]);
    XCTAssertTrue([templateFragment.section[4].name isEqualToString:@"view"]);
    XCTAssertTrue([templateFragment.section[4].fragments.firstObject isKindOfClass:[FragmentData class]]);
    if (shouldCheckBack) {
        NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:fragmentData.dictionaryValue options:0 error:&error];
        NSString * fragment = [[NSString alloc] initWithData:jsonData   encoding:NSUTF8StringEncoding];
        [self checkCarouselFragmentDataForString:fragment checkBack:false];
    }
}

- (void) testLocale{

    NSString *selectedPreferredLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSMutableString *localeStr = [[NSMutableString alloc]initWithString:@"locale="];
    [localeStr appendString: selectedPreferredLanguage];
    NSArray *array = [FCLocaleUtil userLocaleParams:NO];
    NSArray *languages = [[NSArray alloc] initWithObjects:localeStr, nil];
    XCTAssertTrue([array isEqualToArray: languages]);
    NSArray *arrLocale = [FCLocaleUtil channelLocaleParams];
    NSArray *compArray = [NSArray arrayWithObjects: localeStr, @"lastLocaleId=0", nil];
    XCTAssertTrue([arrLocale isEqualToArray:compArray]);
    XCTAssertTrue([FCLocaleUtil hadLocaleChange]);
}

- (void)testDateUtils {
    id userDefaultsMock = OCMClassMock([FCUserDefaults class]);
    OCMStub([userDefaultsMock getStringForKey:HOTLINE_DEFAULTS_CONTENT_LOCALE]).andReturn(@"en_US");
    XCTAssertTrue([[FCDateUtil getDateStringWithFormat:@"yyyy-MM-dd HH:mm" forDate:[NSDate dateWithTimeIntervalSince1970:1591352446]] isEqualToString:@"2020-06-05 15:50"]);
    XCTAssertTrue([[FCDateUtil getDetailedDateStringWithFormat:@"yyyy-MM-dd HH:mm" forDate:[NSDate dateWithTimeIntervalSince1970:1591180412]] isEqualToString:@"Wednesday, 2020-06-03 16:03"]);
    XCTAssertTrue([[FCDateUtil getDetailedDateStringWithFormat:@"yyyy-MM-dd HH:mm" forDate:[NSDate dateWithTimeInterval:(24*60*60) sinceDate:[NSDate date]]] isEqualToString:@"Tomorrow"]);
    XCTAssertTrue([[FCDateUtil getDetailedDateStringWithFormat:@"yyyy-MM-dd HH:mm" forDate:[NSDate date]] isEqualToString:@"Today"]);
}

-(void)testCalendar {
    NSString *calendarString = @"{\"id\": \"83d31c01-d52e-4c59-88fd-f415db7d257a\",\"calendarTimeSlots\": [{\"id\": 0,\"from\": 1586748600000,\"to\": 1586754900000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1586758500000,\"to\": 1586773800000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1586835000000,\"to\": 1586841300000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1586844900000,\"to\": 1586855700000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1586921400000,\"to\": 1586927700000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1586931300000,\"to\": 1586956500000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1586961000000,\"to\": 1586975340000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1586975400000,\"to\": 1587014100000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1587017700000,\"to\": 1587028500000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1587033900000,\"to\": 1587042900000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1587094200000,\"to\": 1587100500000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1587104100000,\"to\": 1587111300000,\"prevTo\": 0}, {\"id\": 0,\"from\": 1587116700000,\"to\": 1587123000000,\"prevTo\": 0}],\"meetingLength\": 1800,\"bufferTime\": 900,\"minNoticeTime\": 1800,\"calendarType\": 1}";
    NSData *data = [calendarString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary* calendarDic = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:0
                                                                           error:&error];
    if (!error){
        id userDefaultsMock = OCMClassMock([FCUserDefaults class]);
        OCMStub([userDefaultsMock getStringForKey:HOTLINE_DEFAULTS_CONTENT_LOCALE]).andReturn(@"en_US");
        FCCalendarModel *model = [[FCCalendarModel alloc]initWith:calendarDic];
        NSMutableArray<FCCalendarDay*> *array = [FCDateUtil getSlotsFromCalendar:model andTimeZoneIdentifier:@"Asia/Kolkata"];
        XCTAssert(array.count == 5);
        XCTAssert([array.firstObject.dateString isEqualToString:@"Monday, 13 Apr 2020"]);
        XCTAssert(array.firstObject.morningSlots.count == 4);
        XCTAssert(array.firstObject.afterNoonSlots.count == 7);
        XCTAssert(array.firstObject.eveningSlots.count == 0);
        XCTAssert(array.firstObject.nightSlots.count == 0);
        XCTAssert(array.firstObject.morningSlots.firstObject.session == FCMorningSession);
        XCTAssert([array.firstObject.morningSlots.firstObject.time isEqualToString:@"9:00 AM"]);
        XCTAssert(array.firstObject.morningSlots[1].session == FCMorningSession);
        XCTAssert([array.firstObject.morningSlots[1].time isEqualToString:@"9:30 AM"]);
        XCTAssert(array.firstObject.morningSlots[2].session == FCMorningSession);
        XCTAssert([array.firstObject.morningSlots[2].time isEqualToString:@"10:00 AM"]);
        XCTAssert(array.firstObject.morningSlots[3].session == FCMorningSession);
        XCTAssert([array.firstObject.morningSlots[3].time isEqualToString:@"11:45 AM"]);
        XCTAssert(array.firstObject.afterNoonSlots.firstObject.session == FCAfterNoonSession);
        XCTAssert([array.firstObject.afterNoonSlots.firstObject.time isEqualToString:@"12:15 PM"]);
        XCTAssert(array.firstObject.afterNoonSlots[1].session == FCAfterNoonSession);
        XCTAssert([array.firstObject.afterNoonSlots[1].time isEqualToString:@"12:45 PM"]);
        XCTAssert(array.firstObject.afterNoonSlots[2].session == FCAfterNoonSession);
        XCTAssert([array.firstObject.afterNoonSlots[2].time isEqualToString:@"1:15 PM"]);
        XCTAssert(array.firstObject.afterNoonSlots[3].session == FCAfterNoonSession);
        XCTAssert([array.firstObject.afterNoonSlots[3].time isEqualToString:@"1:45 PM"]);
        XCTAssert(array.firstObject.afterNoonSlots[4].session == FCAfterNoonSession);
        XCTAssert([array.firstObject.afterNoonSlots[4].time isEqualToString:@"2:15 PM"]);
        XCTAssert(array.firstObject.afterNoonSlots[5].session == FCAfterNoonSession);
        XCTAssert([array.firstObject.afterNoonSlots[5].time isEqualToString:@"2:45 PM"]);
        XCTAssert(array.firstObject.afterNoonSlots[6].session == FCAfterNoonSession);
        XCTAssert([array.firstObject.afterNoonSlots[6].time isEqualToString:@"3:15 PM"]);
        XCTAssert(array[2].morningSlots.count == 4);
        XCTAssert(array[2].afterNoonSlots.count == 8);
        XCTAssert(array[2].eveningSlots.count == 5);
        XCTAssert(array[2].nightSlots.count == 7);
        XCTAssert(array[2].eveningSlots[0].session == FCEveningSession);
        XCTAssert([array[2].eveningSlots[0].time isEqualToString:@"4:15 PM"]);
        XCTAssert(array[2].eveningSlots[1].session == FCEveningSession);
        XCTAssert([array[2].eveningSlots[1].time isEqualToString:@"4:45 PM"]);
        XCTAssert(array[2].eveningSlots[2].session == FCEveningSession);
        XCTAssert([array[2].eveningSlots[2].time isEqualToString:@"5:15 PM"]);
        XCTAssert(array[2].eveningSlots[3].session == FCEveningSession);
        XCTAssert([array[2].eveningSlots[3].time isEqualToString:@"5:45 PM"]);
        XCTAssert(array[2].eveningSlots[4].session == FCEveningSession);
        XCTAssert([array[2].eveningSlots[4].time isEqualToString:@"6:15 PM"]);
        XCTAssert(array[2].nightSlots[0].session == FCNightSession);
        XCTAssert([array[2].nightSlots[0].time isEqualToString:@"8:00 PM"]);
        XCTAssert(array[2].nightSlots[1].session == FCNightSession);
        XCTAssert([array[2].nightSlots[1].time isEqualToString:@"8:30 PM"]);
        XCTAssert(array[2].nightSlots[2].session == FCNightSession);
        XCTAssert([array[2].nightSlots[2].time isEqualToString:@"9:00 PM"]);
        XCTAssert(array[2].nightSlots[3].session == FCNightSession);
        XCTAssert([array[2].nightSlots[3].time isEqualToString:@"9:30 PM"]);
        XCTAssert(array[2].nightSlots[4].session == FCNightSession);
        XCTAssert([array[2].nightSlots[4].time isEqualToString:@"10:00 PM"]);
        XCTAssert(array[2].nightSlots[5].session == FCNightSession);
        XCTAssert([array[2].nightSlots[5].time isEqualToString:@"10:30 PM"]);
        XCTAssert(array[2].nightSlots[6].session == FCNightSession);
        XCTAssert([array[2].nightSlots[6].time isEqualToString:@"11:00 PM"]);
        XCTAssert([[array.firstObject getSessionsIn:0] count] == 4);
        XCTAssert([[[array.firstObject getSessionsIn:0].firstObject getSessionTitle] isEqualToString: @"Morning"]);
        XCTAssert([[array.firstObject getSessionsIn:1] count] == 7);
        XCTAssert([[[array.firstObject getSessionsIn:1].firstObject getSessionTitle] isEqualToString: @"Afternoon"]);
        XCTAssert([[[array[2] getSessionsIn:2].firstObject getSessionTitle] isEqualToString: @"Evening"]);
        XCTAssert([[[array[2] getSessionsIn:3].firstObject getSessionTitle] isEqualToString: @"Night"]);
        XCTAssert([[array.firstObject getSessionsIn:2] count] == 0);
        [array.firstObject.morningSlots removeAllObjects];
        XCTAssert([[array.firstObject getSessionsIn:0] count] == 7);
    }
}


//JWT token

- (void) testJWTToken {
    NSString *jwtToken = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJmaXJzdF9uYW1lIjoiRnJlc2hjaGF0Iiwic3ViIjoiSldUUlMyNTYiLCJmcmVzaGNoYXRfdXVpZCI6IkQzRTdGRjRELUY4RTAtNEM0RC05Q0MyLTIwQTgzQjUxMjQ5NyIsImxhc3RfbmFtZSI6IlVzZXIiLCJleHAiOjE1OTMwMzIyMDMsInJlZmVyZW5jZV9pZCI6InRlc3RAMTIzNCIsImlzcyI6IkhhcmlzaCJ9.23ZaBAvAhrhb_XTIZ29F2XLxN7mt48zH13DKhaH53V6_ijG4LZ5VI4Qud6CN6p2VKi7XIKv5iUDU9Si-kNicBWfOXKm_RUrQ-0y8jxxU6pjvl2HZZsIpBQhBYx4dvnnU_Wx0W-ZHQU7H4WI5rYsggppr_DWrlXttJxeOf4sNWPatB6ePBnfLRdwk6PQmmy83Dhcs8RNpGggDi_lRTj6-4TnOFQZUuNnCYFce6UQEzkJKK5DGlaTw4SMW9wDw6SqkpcfdnSwTopEgonrA7FXZ7ecww7hZRwIyYQqMzyMM-OHFMpL-fT_ZAWM97oWwrJcvn47ANF4k8WFFJn-nzlaKltg9uafEwIwHxBKRHU68wgTu5zA3FgmAv0GiIV1cVnSfsvEwQ4RbIDiIdEl5gjiwUg-Vy0z8nQwl_NkgHQ02YBp8ROC7sK0Igz2LBQTYE-l-bhYt7IfPzZ-zoJBUaQzBspL6ftLXmjKnny4A9T10luHC742cFN0NmX1tr-mh6fH5F9dwcx9aMn1x2c0izSeDRLL3cNrH-hPFXYP6Ixwo6GDq09W7tSCMV13SytK1wolNzJSRRvjVbX70kGm0RNzwOW35xg-ecFUAlpgiuR6EmRZ08Q7y-7NUTZcXxXVT76IOS0H-s3grLBbolrqgt2V2xfElPMsqVxE4bgs1b_JZV4A";
    
    NSDictionary *dict = [FCJWTUtilities getJWTUserPayloadFromToken:jwtToken];
    XCTAssert([dict[@"first_name"] isEqualToString: @"Freshchat"]);
    XCTAssertTrue([FCJWTUtilities isValidityExpiedForJWTToken :jwtToken]);
    XCTAssert([dict[@"reference_id"] isEqualToString: [FCJWTUtilities getReferenceID :jwtToken]]);
    XCTAssert([dict[@"freshchat_uuid"] isEqualToString: [FCJWTUtilities getAliasFrom :jwtToken]]);
    XCTAssertTrue([FCJWTUtilities compareAlias:jwtToken str2:jwtToken]);
    
    FCJWTAuthValidator *authValidator = [FCJWTAuthValidator sharedInstance];
    authValidator.prevState = TOKEN_VALID;
    enum JWT_UI_STATE state = [authValidator getUiActionForTokenState:authValidator.prevState];
    XCTAssertTrue(state == 3);
}

//Remote-Config Class

- (void) testRemoteConfig {
    NSString *configString = @"{\"accountActive\":true,\"sessionTimeoutInterval\":1800000,\"userAuthConfig\":{\"appId\":0,\"jwtAuthEnabled\":false,\"strictModeEnabled\":false,\"authTimeOutInterval\":0},\"messageMaskingConfig\":{\"androidMessageMasks\":[],\"iosMessageMasks\":[]},\"conversationConfig\":{\"activeConvWindow\":259200000,\"activeConvFetchBackoffRatio\":1.25,\"agentAvatars\":\"REAL_AGENT_AVATAR\",\"launchDeeplinkFromNotification\":true,\"hideResolvedConversations\":false,\"hideResolvedConversationsMillis\":86400000,\"resolvedMsgTypes\":[2002,7001],\"reopenedMsgTypes\":[2003]},\"refreshIntervals\":{\"responseTimeExpectationsFetchInterval\":300000,\"remoteConfigFetchInterval\":3600000,\"msgFetchIntervalLaidback\":120000,\"faqFetchIntervalNormal\":600000,\"faqFetchIntervalLaidback\":432000000,\"channelsFetchIntervalNormal\":600000,\"channelsFetchIntervalLaidback\":432000000,\"activeConvMinFetchInterval\":20000,\"activeConvMaxFetchInterval\":60000,\"msgFetchIntervalNormal\":60000},\"eventsConfig\":{\"maxDelayInMillisUntilUpload\":15000,\"maxAllowedEventsPerDay\":50,\"maxEventsPerBatch\":10,\"maxAllowedPropertiesPerEvent\":20,\"triggerUploadOnEventsCount\":5,\"maxCharsPerEventName\":32,\"maxCharsPerEventPropertyName\":32,\"maxCharsPerEventPropertyValue\":256},\"csatSettings\":{\"userCsatViewTimer\":false,\"maximumUserSurveyViewHours\":0,\"maximumUserSurveyViewMillis\":1200000},\"unsupportedFragmentConfig\":{\"displayErrorCodes\":true,\"errorCodePlaceholder\":\"( Error code : %d )\",\"globalErrorMessage\":{\"errorCode\":1001,\"errorMessage\":\"Unsupported content type\"},\"errorMessageByTypes\":[]},\"enabledFeatures\":[\"READ_RECEIPTS\",\"APP_FILE_UPLOAD\",\"COBROWSING\",\"USER_TAG\",\"TYPING_INDICATOR\",\"AUTO_CAMPAIGNS\",\"WHATSAPP_PMP\",\"USER_EVENT\",\"EMAIL_CAMPAIGNS\",\"EMAILS\",\"WHATSAPP_AUC\",\"INBOX\",\"FAQ\"]}";
    
    NSData *data = [configString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary* configDict = [NSJSONSerialization JSONObjectWithData:data
                                                               options:0
                                                                 error:&error];
    
    if (!error){
        FCConversationConfig *config = [[FCConversationConfig alloc]init];
        [config updateConvConfig:[configDict objectForKey:@"conversationConfig"]];
        
        XCTAssertEqual(config.agentAvatar,1);
        XCTAssertEqual(config.activeConvFetchBackoffRatio,1.25);
        XCTAssertEqual(config.launchDeeplinkFromNotification,YES);
        XCTAssertEqual(config.activeConvWindow,259200000);
        XCTAssertEqual(config.hideResolvedConversationMillis,86400000);
        NSArray *reopenArray = @[@2003];
        XCTAssertTrue([config.reopenedMsgtypes isEqualToArray: reopenArray]);
        NSArray *resolveArray = @[@2002, @7001];
        XCTAssertTrue([config.resolvedMsgTypes isEqualToArray: resolveArray]);
        
        FCEnabledFeatures *featureEnableConfig = [[FCEnabledFeatures alloc] init];
        [featureEnableConfig updateConvConfig:[configDict objectForKey:@"enabledFeatures"]];
        
        XCTAssertTrue(featureEnableConfig.faqEnabled);
        XCTAssertTrue(featureEnableConfig.inboxEnabled);
        XCTAssertTrue(featureEnableConfig.autoCampaignsEnabled);
        XCTAssertTrue(featureEnableConfig.showCustomBrandBanner);
        
        FCRefreshIntervals *intervalConfig = [[FCRefreshIntervals alloc] init];
        [intervalConfig updateRefreshConfig:[configDict objectForKey:@"refreshIntervals"]];
        XCTAssertEqual(intervalConfig.responseTimeExpectationsFetchInterval, 300000);
        XCTAssertEqual(intervalConfig.remoteConfigFetchInterval, 3600000);
        XCTAssertEqual(intervalConfig.activeConvMinFetchInterval, 20000);
        XCTAssertEqual(intervalConfig.activeConvMaxFetchInterval, 60000);
        XCTAssertEqual(intervalConfig.msgFetchIntervalNormal, 60000);
        XCTAssertEqual(intervalConfig.msgFetchIntervalLaidback, 120000);
        XCTAssertEqual(intervalConfig.faqFetchIntervalNormal, 600000);
        XCTAssertEqual(intervalConfig.faqFetchIntervalLaidback, 432000000);
        XCTAssertEqual(intervalConfig.channelsFetchIntervalNormal, 600000);
        XCTAssertEqual(intervalConfig.channelsFetchIntervalLaidback, 432000000);
        
        FCCSatSettings *csatConfig = [[FCCSatSettings alloc] init];
        [csatConfig updateCSatConfig:[configDict objectForKey:@"csatSettings"]];
        XCTAssertEqual(csatConfig.maximumUserSurveyViewMillis, 1200000);
        XCTAssertFalse(csatConfig.isUserCsatViewTimerEnabled);
        
        FCUnsupportedFragmentErrorMsgs *unsupportMsgConfig = [[FCUnsupportedFragmentErrorMsgs alloc] init];
        [unsupportMsgConfig updateUnsupportedFragmentMsgInfo:[configDict objectForKey:@"unsupportedFragmentConfig"]];
        XCTAssertTrue(unsupportMsgConfig.displayErrorCodes);
        NSDictionary *dict2 = @{@"errorCode": @1001,
        @"errorMessage" : @"Unsupported content type"};
        XCTAssertTrue([unsupportMsgConfig.globalErrorMessage isEqualToDictionary:dict2]);
        XCTAssertTrue([unsupportMsgConfig.errorCodePlaceholder isEqualToString:@"( Error code : \%d )"]);
        
        
        FCUserAuthConfig *userAuthConfig = [[FCUserAuthConfig alloc] init];
        [userAuthConfig updateUserAuthConfig:[configDict objectForKey:@"userAuthConfig"]];
        XCTAssertFalse(userAuthConfig.isjwtAuthEnabled);
        XCTAssertFalse(userAuthConfig.isStrictModeEnabled);
        
        FCEventsConfig *eventConfig = [[FCEventsConfig alloc] init];
        [eventConfig updateEventsConfig:[configDict objectForKey:@"eventsConfig"]];
        XCTAssertEqual(eventConfig.maxDelayInMillisUntilUpload, 15000);
        XCTAssertEqual(eventConfig.maxEventsPerBatch, 10);
        XCTAssertEqual(eventConfig.maxAllowedEventsPerDay, 50);
        XCTAssertEqual(eventConfig.maxAllowedPropertiesPerEvent, 20);
        XCTAssertEqual(eventConfig.triggerUploadOnEventsCount, 5);
        XCTAssertEqual(eventConfig.maxCharsPerEventName, 32);
        XCTAssertEqual(eventConfig.maxCharsPerEventPropertyName, 32);
        XCTAssertEqual(eventConfig.maxCharsPerEventPropertyValue, 256);

    }
}

//Memlogger
- (void) testMemLogger {
    FCMemLogger *memLog = [[FCMemLogger alloc] init];
    NSString *appState = [memLog getApplicationState];
    XCTAssertEqualObjects(appState, @"Active");
    NSString *sessionId = [memLog getUserSessionId];
    XCTAssertTrue(sessionId.length >32);
}

//Event Helper

- (void) testvalidEventNameLength {
    BOOL hasValidEventName = [FCEventsHelper hasValidEventNameLength:@"FCEventFAQCategoryListOpen"];
    XCTAssertTrue(hasValidEventName);
}

- (void) testGetValidatedEventProperties {
    NSString *ctr = [FCUtilities returnLibraryPathForDir:FC_INBOUND_EVENT_DIR_PATH];
    XCTAssertTrue(ctr != nil);
    
    NSDictionary *dict1 = [FCEventsHelper getValidatedEventsProps: @{@"FCPropertyFAQID": @103,
                                                                    @"FCPropertyChannelID" : @40499728879621,
                                                                    @"FCPropertyFAQTitle" : @"inbox",
                                                                    @"FCPropertyConversationID" :@""}];
    NSDictionary *dict2 = @{@"FCPropertyFAQID": @103,
    @"FCPropertyChannelID" : @40499728879621,
    @"FCPropertyFAQTitle" : @"inbox",
                            @"fc_error" :@"Property value is empty for FCPropertyConversationID"};
    XCTAssertTrue([dict1 isEqualToDictionary:dict2]);
}

- (void) testDictForEventParams {
    
    XCTAssertTrue([FCEventsHelper hasValidEventNameLength:@"Event_Name"]);
    
    NSDictionary *dict1 = [FCEventsHelper getDictionaryForParamsDict: @{@(FCPropertyFAQID): @103,
    @(FCPropertyChannelID) : @40499728879621,
    @(FCPropertyFAQTitle) : @"inbox"}];
    
    NSDictionary *dict2 = @{@"FCPropertyFAQID": @103,
                            @"FCPropertyChannelID" : @40499728879621,
                            @"FCPropertyFAQTitle" : @"inbox"};
    XCTAssertTrue([dict1 isEqualToDictionary:dict2]);
}

- (void) testNextEvent {
    FCEventsManager *eventMgr = [[FCEventsManager alloc] init];
    NSNumber *nextId = [eventMgr nextEventId];
    XCTAssertTrue([nextId isEqualToNumber:@1]);
}
    
//SDK Header class tests

- (void) testSDKBuildVersion {
    XCTAssertTrue([[Freshchat SDKVersion] intValue] > 300);
}

- (void) testIsFreshchatNotification {
    
    id userSecureStoreMock = OCMClassMock([FCSecureStore class]);
    OCMStub([userSecureStoreMock objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN]).andReturn(@"7f3f0bc4-d23a-11ea-87d0-0242ac130003");
    XCTAssertTrue([[Freshchat sharedInstance] isDeviceTokenUpdated: @"7f3f0bc4-d23a-11ea-87d0-0242ac130004"]);
    
    BOOL isFreshchatNotif = [[Freshchat sharedInstance] isFreshchatNotification: @{
    @"aps": @{
            @"alert" : @{
                    @"body" : @"test"
                    },
            @"badge": @1,
            @"mutable-content" : @1,
            @"sound" : @"default"
            },
    @"channel_id": @103,
    @"conv_id" : @40499728879621,
    @"source" : @"freshchat_user",
    @"target_user_alias" : @"6D28735A-9E38-4E26-BEF3-B8FAA0114899",
    }];
    XCTAssertTrue(isFreshchatNotif);
}

- (void) testConfigSDK {
    FreshchatConfig *config = [[FreshchatConfig alloc]initWithAppID:@"63d96e60-642f-48cb-b40a-dfbf16306fe8" andAppKey:@"60b7af4d-5729-45e2-b94f-9ea1af8bad20"];
    XCTAssertEqual(config.appID, @"63d96e60-642f-48cb-b40a-dfbf16306fe8");
    XCTAssertEqual(config.appKey, @"60b7af4d-5729-45e2-b94f-9ea1af8bad20");
    XCTAssertEqual(config.cameraCaptureEnabled, true);
    XCTAssertEqual(config.teamMemberInfoVisible, true);
    XCTAssertEqual(config.gallerySelectionEnabled, true);
    XCTAssertEqual(config.notificationSoundEnabled, true);
    XCTAssertEqual(config.showNotificationBanner, true);
    XCTAssertEqual(config.responseExpectationVisible, true);
    XCTAssertEqual(config.eventsUploadEnabled, true);
    XCTAssertEqual(config.themeName, @"FCTheme");
    XCTAssertEqual(config.stringsBundle, @"FCLocalization");
    
    id userSecureStoreMock = OCMClassMock([FCSecureStore class]);
    OCMStub([userSecureStoreMock objectForKey:HOTLINE_DEFAULTS_DEVICE_UUID ]).andReturn(@"7f3f0bc4d23a11ea87d00242ac130003");
    OCMStub([userSecureStoreMock objectForKey:HOTLINE_DEFAULTS_APP_ID ]).andReturn(config.appID);
    OCMStub([userSecureStoreMock objectForKey:HOTLINE_DEFAULTS_APP_KEY ]).andReturn(config.appKey);
    OCMStub([userSecureStoreMock objectForKey:HOTLINE_DEFAULTS_DOMAIN ]).andReturn(@"web.freshchat.com");
}

- (void) testFreshchaUser {
    FreshchatUser *user = [[FreshchatUser sharedInstance] init];
    user.firstName = @"John";
    user.lastName = @"Doe";
    user.email = @"support@freshchat.com";
    
    XCTAssertEqual(user.firstName, @"John");
    XCTAssertEqual(user.lastName, @"Doe");
    XCTAssertEqual(user.email, @"support@freshchat.com");
    XCTAssertEqual(user.phoneNumber, nil); //No value set to check empty
    XCTAssertEqual(user.phoneCountryCode, nil);//No value set to check empty
}

-(void) testGetLocalLocale {
    [FCLocaleUtil updateLocaleWith:@"fr"];
    NSString *locale = [FCLocaleUtil getUserLocale];
    XCTAssertEqualObjects(locale, @"fr");
}

-(void) testSetLocale {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"name"] = @"xyz";
    [FCUtilities setLocale: dict];
    XCTAssertTrue([dict[@"locale"] isEqualToString: @"fr"]);
}

- (void) testFreshchatSDKMisc {
    NSString *domain = [[Freshchat sharedInstance] validateDomain:@"http://msdk.freshchat.com"];
    XCTAssertEqualObjects(domain, @"msdk.freshchat.com");
    
    FCYesNoPromptView *prompt = [[FCYesNoPromptView alloc] init];
    XCTAssertEqual([prompt getPromptHeight], (CGFloat)84.0);
    
    FCPromptView *promptView = [[FCPromptView alloc] init];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"Show View" forState:UIControlStateNormal];
    button.frame = CGRectMake(80, 210, 160, 40);
    CGFloat btnWidth = [promptView getDesiredWidthFor:button];
    XCTAssertEqual(208, (int)btnWidth);
    
    FCCSATView *csatView = [[FCCSATView alloc] init];
    UIView *starRateView = [csatView createStarRatingView];
    XCTAssertTrue(starRateView != nil);// just check for rating view
    
    XCTAssertFalse([[Freshchat sharedInstance] cannotMakeUserCalls]);
}

- (void) testFaqAndConvOptions {
    FAQOptions *faqOption = [[FAQOptions alloc] init];
    [faqOption filterByTags:@[@"wow"] withTitle:@"Title" andType:CATEGORY];
    [faqOption filterContactUsByTags:@[@"wow"]  withTitle:@"Title"];
    XCTAssertTrue([faqOption.tags.firstObject isEqualToString: @"wow"]);
    XCTAssertTrue([faqOption.contactUsTags.firstObject isEqualToString: @"wow"]);
    XCTAssertEqual(faqOption.filteredViewTitle, @"Title");
    XCTAssertEqual(faqOption.contactUsTitle, @"Title");
    XCTAssertEqual(faqOption.showContactUsOnFaqNotHelpful, true);
    XCTAssertEqual(faqOption.filteredType, CATEGORY);
    XCTAssertEqual(faqOption.showFaqCategoriesAsGrid , true);
    XCTAssertEqual(faqOption.showContactUsOnFaqScreens , true);
    XCTAssertTrue([FCFAQUtil hasTags:faqOption]);
    XCTAssertTrue([FCFAQUtil hasContactUsTags:faqOption]);
    XCTAssertTrue([FCFAQUtil hasFilteredViewTitle:faqOption]);
    
    FAQOptions *faqOptionCopy = ([FCFAQUtil nonTagCopy:faqOption]);
    XCTAssertFalse([faqOptionCopy.tags.firstObject isEqualToString: @"wow"]);
    XCTAssertTrue([faqOptionCopy.contactUsTags.firstObject isEqualToString: @"wow"]);
    XCTAssertEqual(faqOptionCopy.contactUsTitle, @"Title");
    XCTAssertEqual(faqOptionCopy.showContactUsOnFaqNotHelpful, true);
    XCTAssertEqual(faqOptionCopy.filteredType, CATEGORY);
    XCTAssertEqual(faqOptionCopy.showFaqCategoriesAsGrid , true);
    XCTAssertEqual(faqOptionCopy.showContactUsOnFaqScreens , true);
    
    ConversationOptions *convOpt = [[ConversationOptions alloc] init];
    [convOpt filterByTags:@[@"wow"] withTitle:@"Title"];
    XCTAssertTrue([convOpt.tags.firstObject isEqualToString: @"wow"]);
    XCTAssertEqual(convOpt.filteredViewTitle, @"Title");
    
    XCTAssertTrue([FCConversationUtil hasTags:convOpt]);
    XCTAssertTrue([FCConversationUtil hasFilteredViewTitle:convOpt]);
}

- (void) testEvents {
    
    NSDictionary *optionsDict =  @{
                        @(FCPropertyInputTags): @"wow",
                        @(FCPropertyFAQTitle) : @"Refund Queries"
                        };
    FCOutboundEvent *outEvent = [[FCOutboundEvent alloc] initOutboundEvent:FCEventFAQCategoryListOpen withParams:optionsDict];
    [FCEventsHelper postNotificationForEvent:outEvent];
    
}

- (void) userActionEvent:(NSNotification *)notif {
    FreshchatEvent *fcEvent = notif.userInfo[@"event"];
    XCTAssertEqual(fcEvent.name, FCEventFAQCategoryListOpen);
    NSDictionary *compareDict =  @{
    @"FCPropertyInputTags": @"wow",
    @"FCPropertyFAQTitle" : @"Refund Queries"
    };
    XCTAssertTrue([fcEvent.properties isEqualToDictionary:compareDict]);
    XCTAssertEqual([fcEvent valueForEventProperty:FCPropertyFAQTitle], @"Refund Queries");
}

- (void) testFreshchatMessage {
    FreshchatMessage *fcMsg = [[FreshchatMessage alloc] initWithMessage:@"Hello there" andTag:@"wow"];
    XCTAssertEqual(fcMsg.message, @"Hello there");
    XCTAssertTrue([fcMsg.tag isEqualToString:@"wow"]);
}

//Test cases for String Utilities

- (void) testValidUserProperty {
    BOOL isvalidProperty = [FCStringUtil isValidUserPropName:@"JonnyBawa"];
    XCTAssertTrue(isvalidProperty);
}

- (void) testRegexPattern {
    BOOL isRegexmatch = [FCStringUtil checkRegexPattern:@"\\b(?:\\d{4}[ -]?){3}(?=\\d{4}\\b)" inString:@"1234-1234-1234-1234"];
    XCTAssertTrue(isRegexmatch);
    
    NSString *matchStr = [FCUtilities replaceMatchString:@"1234-1234-1234-1234" withString:@"11111"];
    XCTAssertTrue([matchStr isEqualToString:@"11111"]);
}

- (void) testBase64EncodedString {
    NSString *strValue = [FCStringUtil base64EncodedStringFromString:@"support@freshchat.com"];
    XCTAssertTrue([strValue isEqualToString: @"c3VwcG9ydEBmcmVzaGNoYXQuY29t"]);
}

- (void) testReplaceSpecialChars {
    NSString *replacedStr = [FCStringUtil replaceSpecialCharacters:@"test#}123*" with:@"X"];
    XCTAssertTrue([replacedStr isEqualToString: @"testxx123x"]);
}

- (void) testReplaceStringUsingRegex {
    NSString *replaceString = [FCStringUtil replaceInString:@"1234-1234-1234-1234" usingRegex:@"\\b(?:\\d{4}[ -]?){3}(?=\\d{4}\\b)" replaceWith:@"XXXX-XXXX-XXXX-"];
    XCTAssertTrue([replaceString isEqualToString: @"XXXX-XXXX-XXXX-1234"]);
}

- (void) testEmptyString {
    BOOL isNotEmpty = [FCStringUtil isEmptyString:@"Hello there"];
    XCTAssertFalse(isNotEmpty);
}

- (void) testValidEmailId {
    BOOL validEmail = [FCStringUtil isValidEmail:@"support@freshchat.com"];
    XCTAssertTrue(validEmail);
    
    BOOL inValidEmail = [FCStringUtil isValidEmail:@"support.freshchat.com"];
    XCTAssertFalse(inValidEmail);
}

- (void) testNotEmptyString {
    BOOL isNotEmpty = [FCStringUtil isNotEmptyString:@"Hello there"];
    XCTAssertTrue(isNotEmpty);
}

- (void) testStringMisc {
    NSString *newLineStr = [FCStringUtil sanitizeStringForNewLineCharacter:@"line1 \n line2"];
    XCTAssertEqualObjects(newLineStr, @"line1 line2");
    NSString *utf8Str = [FCStringUtil sanitizeStringForUTF8: @"string 1 [\U00010000 string 2"];
    XCTAssertEqualObjects(utf8Str, @"string 1 [  string 2");
    NSString *idStr =  [FCStringUtil generateUUID];
    XCTAssertTrue(idStr.length >=32);
    NSString *strFromObj = [FCStringUtil getStringValue:[NSString stringWithFormat:@"String as object"]];
    XCTAssertEqualObjects(strFromObj, @"String as object");
}

- (void) testIndexManager {
    NSString *str = [FCIndexManager stringByStrippingHTML:@"<HTML>hello <b>there</b></HTML>"];
    XCTAssertEqualObjects(str, @"hello there");
}

- (void) testCategoryGridTextDisplay {
    FCCategoryGridViewController *catGrid = [[FCCategoryGridViewController alloc]init];
    FCCategoryListController *catList = [[FCCategoryListController alloc]init];
    XCTAssertEqualObjects([catGrid emptyText], [catList emptyText]);
    XCTAssertEqualObjects([catGrid loadingText], [catList loadingText]);
}

//Test cases for FCUtilities

- (void) testConvertToMD5 {
    NSString *md5CovStr = [FCUtilities convertIntoMD5:@"fe0a6d4f8719e4bae981d659c65419e6"];
    XCTAssertTrue([md5CovStr isEqualToString: @"f922209d12d7b7c0728a06ade8584ee8"]);
}

-(void) testString {
    NSString *str = @"Here is some <b>HTML</b>";
    BOOL containsHtmlString = [FCUtilities containsHTMLContent:str];
    XCTAssertTrue(containsHtmlString);
    NSAttributedString *attributedTextString = [FCUtilities getAttributedContentForString:str withFont:nil];
    XCTAssertEqualObjects(attributedTextString.string, @"Here is some HTML");
}

- (void) testContainsString {
    XCTAssertTrue([FCUtilities containsString:@"Here is some <b>HTML</b>" andTarget:@"<b>"]);
}

- (void) testTagsToLowercase {
    NSArray *testArray = @[@"BOSE", @"best", @"Test123"];
    NSArray *compArray = @[@"bose", @"best", @"test123"];
    NSArray *outPutArr = [FCUtilities convertTagsArrayToLowerCase:testArray];
    BOOL isbothArrayEqual = [outPutArr isEqualToArray:compArray];
    XCTAssertTrue(isbothArrayEqual);
}

- (void) testTags {
    NSDictionary *dict = [FCTags createDictWithTagName:@"alfa" type:@1 andIdvalue:@1];
    NSDictionary *compareDict = @{@"tagName" : @"alfa", @"taggableID" : @1, @"taggableType" : @1};
    XCTAssertTrue([compareDict isEqualToDictionary:dict]);
}

- (void) testReplyResponseTime {
    NSString *responseTime = [FCUtilities getReplyResponseForTime:57 andType:LAST_WEEK_AVG];
    XCTAssertEqualObjects(responseTime, @"Typically replies within a minute");
}

- (void) testValidUUID {
    BOOL validUUIDkey = [FCUtilities isValidUUIDForKey:@"c69641e9-8a85-4da1-858e-77169b0c76a7"];
    XCTAssertTrue(validUUIDkey);
}

- (void) testInvertColor {
    UIColor *color1 = [FCUtilities invertColor:[FCTheme colorWithHex:@"FFFFFF"]];
    UIColor *color2 = [FCTheme colorWithHex:@"000000"];
    XCTAssertTrue([color1 isEqual:color2]);
}

- (void) testAppendFNLN{
    NSString * fullName = [FCUtilities appendFirstName:@"JC" withLastName:@"Bose"];
    XCTAssertEqualObjects(fullName, @"JC Bose");
}

- (void) testIsAccountActive {
    BOOL isAccountDeleted = [FCUtilities isAccountDeleted];
    XCTAssertFalse(isAccountDeleted);
}

- (void) testDurationConversion {
    NSString *durationVal = [FCUtilities getDurationFromSecs : 1800];
    XCTAssertEqualObjects(durationVal, @"30 mins", @"Test Passed for duration conversion");
}

- (void) testDurationDiff {
    NSString *interval = [FCUtilities intervalStrFromMillis: 0 toMillis:1800000];
    XCTAssertEqualObjects(interval, @"30 mins", @"Test Passed for duration conversion");
}

- (void) testDateStringFromTime {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(969696900000 / 1000.0)];
    NSString *timeValue = [FCDateUtil getDateStringWithFormat:@"h:mm a" forDate:date];
    XCTAssertEqualObjects(timeValue, @"1:45 PM", @"Test Passed for date conversion");
}

- (void) testCalendarMsgWidthBounds {
    float width = [FCUtilities calendarMsgWidthInBounds:CGRectMake(0, 0, 200, 100)];
    XCTAssertEqual(width, 80);
}

- (void) testSameDate {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(969696900000 / 1000.0)];
    XCTAssertFalse([FCUtilities isTodaySameAsDate:date]);
}

- (void) testMiscUtil {
    XCTAssertTrue([FCUtilities isiOS10]);
    XCTAssertFalse([FCUtilities isVerLessThaniOS13]);
    XCTAssertFalse([FCUtilities isDeviceLanguageRTL]);
    XCTAssertTrue([FCUtilities hasNotchDisplay]);
    NSDictionary *dict = [FCUtilities filterValidUserPropEntries: @{@"Key1": @103,
                                                                    @"Key2" : @40499728879621,
                                                                    @"Key3" : @"value"}];
    XCTAssertTrue([dict isEqualToDictionary:@{@"Key3": @"value"}]);
    NSString *str = [NSString stringWithFormat:@"hl_ios_%@",[Freshchat SDKVersion]];
    XCTAssertTrue([[FCUtilities getTracker] isEqualToString:str]);
    XCTAssertTrue([FCUtilities generateOfflineMessageAlias].length > 0);
    NSDictionary *dict2 = [FCUtilities deviceInfoProperties];
    XCTAssertTrue([FCUtilities deviceModelName].length != 0);
    XCTAssertTrue([FCUtilities getCurrentTimeInMillis] > 1595303501586);
    NSLog(@"Time");
}

- (void) testActivecalendarMessageType {
    NSString *calendarMessage = @"{\"messageId\":368863015109157,\"alias\":\"90642c7a-72af-48c3-be57-3e7b909b9df8\",\"messageType\":9001,\"messageUserId\":793926819847,\"conversationId\":368862890000551,\"appId\":793925140483,\"createdMillis\":1592809647048,\"updatedMillis\":0,\"readByUser\":false,\"messageFragments\":[{\"fragmentType\":1,\"contentType\":\"texthtml\",\"content\":\"Could you please choose a convenient time slot for a demo?\",\"position\":0}],\"hasActiveCalInvite\":1,\"source\":1,\"ruleId\":0,\"articleContentId\":0,\"deliveredAt\":0,\"cobrowsingId\":0,\"labelId\":0,\"labelCategoryId\":0,\"messageUserAlias\":\"84a48262-cfbb-4880-af8d-31a089d13dc8\",\"conversationAlias\":\"32779cbf-85aa-475e-a470-f800c73ca5bf\",\"messageUserName\":\"Harish Kumar\",\"userFirstName\":\"Harish\",\"userLastName\":\"Kumar\",\"shouldTranslate\":0,\"read\":false,\"marketingId\":0,\"messageUserType\":1,\"marketingReplyId\":-1,\"conversationChannelId\":52,\"replyFragments\":[],\"internalMeta\":{\"offlineEnabled\":false,\"calendarMessageMeta\":{\"calendarSenderId\":793926819847,\"calendarAgentId\":793926819847,\"calendarAgentAlias\":\"84a48262-cfbb-4880-af8d-31a089d13dc8\",\"calendarInviteId\":\"aba41b37-1f77-457b-98b2-0e3190acd9a3\",\"retryCalendarEvent\":false}},\"responseForBot\":false,\"searchUniqueId\":368863015109157,\"searchAppId\":793925140483,\"agentMessage\":true}";
    
    NSData *data = [calendarMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary* calendarDict = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:0
                                                                           error:&error];
    
    NSLog(@"calendar dict %@", calendarDict);
    if (!error){
        
        FCMessageData *message = [[FCMessageData alloc]init];
        message.createdMillis = calendarDict[@"createdMillis"];
        message.messageAlias = calendarDict[@"messageAlias"];
        message.isRead = calendarDict[@"isRead"];
        message.uploadStatus = calendarDict[@"uploadStatus"];
        message.messageUserType = calendarDict[@"messageUserType"];
        message.messageType = calendarDict[@"messageType"];
        message.isMarketingMessage = calendarDict[@"isMarketingMessage"];
        message.marketingId = calendarDict[@"marketingId"];
        message.isWelcomeMessage = calendarDict[@"isWelcomeMessage"];
        message.messageUserAlias = calendarDict[@"messageUserAlias"];
        message.replyFragments = calendarDict[@"replyFragments"];
        message.internalMeta = calendarDict[@"internalMeta"];
        message.hasActiveCalInvite = calendarDict[@"hasActiveCalInvite"];
        message.messageId = calendarDict[@"messageId"];
        
        XCTAssertEqualObjects(@9001, message.messageType);
        XCTAssertTrue(message.hasActiveCalInvite);
        FCMessageController *msgCtr = [[FCMessageController alloc] init];
        XCTAssertTrue([msgCtr isCalendarMsg : message]);
        XCTAssertEqualObjects([msgCtr getIdentityForMessage:message], @368863015109157);
    }
}

- (void) testArticle {
    
    FCArticleDetailViewController *articleCtr = [[FCArticleDetailViewController alloc] init];
    NSString *fixStr = [articleCtr fixLinksForiOS9 :@"src=\"//fc-use1-00-pics-bkt-00.s3.amazonaws.com\""];
    XCTAssertTrue([fixStr isEqualToString:@"src=\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com\""]);
    
    FCVotingManager *votingMgr = [FCVotingManager sharedInstance];
    votingMgr.votedArticlesDictionary = [[NSMutableDictionary alloc] init];
    [votingMgr.votedArticlesDictionary setObject:@1 forKey:@12552];
    [votingMgr.votedArticlesDictionary setObject:@0 forKey:@12553];
    XCTAssertFalse([votingMgr isArticleVoted:@12552]);
    XCTAssertTrue([votingMgr isArticleDownvoted:@12552]);
    XCTAssertFalse([votingMgr getArticleVoteFor:@12553]);
}

- (void) testMsgControllerMethods {
    FCMessageController *msgCtr = [[FCMessageController alloc] init];
    XCTAssertTrue([msgCtr checkIfResponseLabelIsEmpty]);
    NSArray *array = @[@{@"channelId" : @707, @"responseTime" : @0 },
                       @{@"channelId" : @787, @"responseTime" : @0},
                       @{@"channelId" : @789, @"responseTime" : @5},
                       @{@"channelId" : @792, @"responseTime" : @0},
                       @{@"channelId" : @30, @"responseTime" : @0}];
    NSDictionary *dict = [msgCtr getChannelReplyTimeForResponse : array];
    NSDictionary *dictInfo1 = [dict objectForKey:@707];
    NSDictionary *dict2 = @{@"channelId": @707,
                            @"responseTime" : @0};
    XCTAssertTrue([dictInfo1 isEqualToDictionary:dict2]);
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text= @"This is sample text";
    XCTAssertTrue([msgCtr lineCountForLabel:lbl] == 1.0);
    XCTAssertTrue([msgCtr emptyText].length == 0);
    XCTAssertTrue([msgCtr loadingText].length == 0);
}

- (void) testHtWithFont {
    UIFont *sysFont = [UIFont systemFontOfSize:14];
    float cellHt =  [FCListViewController heightOfCell:sysFont];
    XCTAssertEqual(58.0, cellHt);
    
}
- (void) testAgentAndUserMsgs {
    
    BOOL isMe = [FCMessageHelper isUserMe: @"0"];
    BOOL isCurrentUser = [FCMessageHelper isCurrentUser :@0];
    XCTAssertTrue(isMe);
    XCTAssertTrue(isCurrentUser);
    
    NSMutableArray *msgArray = [[NSMutableArray alloc] init];
    for (int i = 0; i <= 4; ++i) {
        FCMessageData *message = [[FCMessageData alloc]init];
        if(i % 2 == 0){
            message.messageType = @1;
        }else {
            message.messageType = @7002;
        }
        FCMessages *msg = (FCMessages *)message;
        [msgArray addObject:msg];
    }
    XCTAssertEqual(3, [FCMessageHelper getUserAndAgentMsgs  : msgArray].count);
    
    FCAgentMessageCell *agentCell = [[FCAgentMessageCell alloc] init];
    NSString *locAgentName = [agentCell getLocalizedAgentName];
    XCTAssertEqualObjects(locAgentName, @"Support");
    BOOL isTopFragment = [agentCell isTopFragment:@[@"frag1", @"frag2"] currentIndex:0];
    XCTAssertTrue(isTopFragment);
}

- (void) testJsonMsgObj {
    NSString *str = [FCMessages getJsonStringObjForMessage:@{
    @"aps": @{@"key1":@"val1"},
    @"channel_id": @103}
                                   withKey:@"aps"];
    XCTAssertTrue([str isEqualToString:@"{\n  \"key1\" : \"val1\"\n}"]);
    
    NSDictionary *dict = [FCMessageUtil getInternalMetaForData:str];
    XCTAssertTrue([dict isEqualToDictionary:@{@"key1":@"val1"}]);
}

- (void) testLocalNotif {
    [FCLocalNotification post:@"TEST_NOTIF"];
}

- (void) notifReceived:(NSNotification *)notif {
    XCTAssertEqual(notif.name, @"TEST_NOTIF");
}

- (void) testFCAttributedText {
    NSMutableAttributedString *str2 = [[FCAttributedText sharedInstance] addAttributedString:@"Hello <b>World</b>" withFont:[UIFont systemFontOfSize:12]];
    XCTAssertEqualObjects(str2.string, @"Hello World");
}

- (void) testReachability {
    FCReachabilityManager *reachMgr = [[FCReachabilityManager sharedInstance] initWithDomain:@"http://www.google.com"];
    XCTAssertTrue(reachMgr.isReachable);
    if(reachMgr.isReachable){
        FCReachability *rch = [FCReachability reachabilityWithHostName:@"http://www.google.com"];
        FCReachability *rch1 = [FCReachability reachabilityForInternetConnection];
        XCTAssertEqual(rch.isReachable, rch1.isReachable);
        
        NSString *appId = @"63d96e60-642f-48cb-b40a-dfbf16306fe8";
        NSString *path = [NSString stringWithFormat:HOTLINE_API_TYPLICAL_REPLY,appId];
        
        FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
        [request setRelativePath:path andURLParams:@[@"t=60b7af4d-5729-45e2-b94f-9ea1af8bad20",@"locale=en"]];
        FCAPIClient *apiClient = [FCAPIClient sharedInstance];
        [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
            if (!error) {
                NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
                XCTAssertTrue(statusCode == 200);
            }
        }];
    }
}

-(void) testIsTemplateFragment {
    NSString *replyFragmentValid = @"[{\"templateType\":\"carousel\",\"sections\":[{\"name\":\"carousel_title\",\"fragments\":[{\"content\":\"Hello choose one of following Hello choose one of following Hello choose one of following\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"cards\",\"fragments\":[{\"templateType\":\"carousel_card_default\",\"sections\":[{\"name\":\"hero_image\",\"fragments\":[{\"height\":400,\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessage/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408374876.png\",\"position\":0,\"thumbnail\":{\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessageThumb/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408374986.jpeg\",\"width\":400,\"height\":400},\"fragmentType\":2,\"contentType\":\"application/octet-stream\",\"width\":400}]},{\"name\":\"title\",\"fragments\":[{\"content\":\"Apple\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"description\",\"fragments\":[{\"content\":\"Apple Inc. is an American multinational technology company headquartered in Cupertino, California, that designs, develops, and sells consumer electronics, computer software, and online services. It is considered one of the Big Four technology companies, alongside Amazon, Google, and Microsoft.\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"callback\",\"fragments\":[{\"label\":\"Select\",\"payload\":\"appelpayload\",\"position\":0,\"fragmentType\":52}]}],\"position\":0,\"fragmentType\":1002},{\"templateType\":\"carousel_card_default\",\"sections\":[{\"name\":\"hero_image\",\"fragments\":[{\"height\":200,\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessage/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408375251.png\",\"position\":0,\"thumbnail\":{\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessageThumb/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408375335.jpeg\",\"width\":200,\"height\":200},\"fragmentType\":2,\"contentType\":\"application/octet-stream\",\"width\":200}]},{\"name\":\"title\",\"fragments\":[{\"content\":\"Google\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"description\",\"fragments\":[{\"content\":\"Google LLC is an American multinational technology company that specializes in Internet-related services and products, which include online advertising technologies, search engine, cloud computing, software, and hardware.\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"callback\",\"fragments\":[{\"label\":\"Select\",\"payload\":\"GooglePayload\",\"position\":0,\"fragmentType\":52}]}],\"position\":0,\"fragmentType\":1002},{\"templateType\":\"carousel_card_default\",\"sections\":[{\"name\":\"hero_image\",\"fragments\":[{\"height\":1200,\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessage/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408375470.png\",\"position\":0,\"thumbnail\":{\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessageThumb/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408375553.jpeg\",\"width\":400,\"height\":400},\"fragmentType\":2,\"contentType\":\"application/octet-stream\",\"width\":1200}]},{\"name\":\"title\",\"fragments\":[{\"content\":\"Facebook\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"description\",\"fragments\":[{\"content\":\"Facebook, Inc. is an American social media and technology company based in Menlo Park, California.\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"callback\",\"fragments\":[{\"label\":\"Select\",\"payload\":\"Facebook Payload\",\"position\":0,\"fragmentType\":52}]},{\"name\":\"view\",\"fragments\":[{\"target\":\"_self\",\"label\":\"Visit\",\"content\":\"https://www.facebook.com\",\"contentType\":\"text/vnd.submit-form\",\"position\":0,\"fragmentType\":5}]}],\"position\":0,\"fragmentType\":1002}]}],\"position\":0,\"fragmentType\":1002}]";
    NSString *replyFragmentInValid = @"";
    XCTAssertEqual([replyFragmentValid isTemplateFragment], true);
    XCTAssertEqual([replyFragmentInValid isTemplateFragment], false);
}

- (void) testSDKDefaultTheme {
    FCTheme *theme = [FCTheme sharedInstance];
    XCTAssertTrue([[theme getBannerTextColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme getBannerBackgroundColor] isEqual:[FCTheme colorWithHex:@"4F5F78"]]);
    XCTAssertEqualObjects([theme getBannerTextFont], [UIFont systemFontOfSize:12.0]);
    XCTAssertTrue([theme getCssFileContent:[theme getArticleDetailCSSFileName]].length > 0);
    XCTAssertTrue([theme isTeamMemberAvatarVisibile]);
    XCTAssertEqual([theme userMessageTextAlignment],[theme agentMessageTextAlignment]);
    
    XCTAssertTrue([[theme getInvitationStatusTextColor] isEqual:[FCTheme colorWithHex:@"293A5A"]]);
    XCTAssertEqualObjects([theme getInvitationStatusTextFont], [UIFont boldSystemFontOfSize:14.0]);
    XCTAssertTrue([[theme getInvitationDurationTextColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getInvitationDurationTextFont], [UIFont systemFontOfSize:12.0]);
    XCTAssertTrue([[theme getInvitationTimeTextColor] isEqual:[FCTheme colorWithHex:@"293A5A"]]);
    XCTAssertEqualObjects([theme getInvitationTimeTextFont], [UIFont boldSystemFontOfSize:14.0]);
    XCTAssertTrue([[theme getInvitationDescriptionTextColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getInvitationDescriptionTextFont], [UIFont systemFontOfSize:12.0]);
    XCTAssertTrue([[theme getInvitationDateTextColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getInvitationDateTextFont], [UIFont systemFontOfSize:12.0]);
    XCTAssertTrue([[theme getInvitationAvatarsBorderColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme getInvitationBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    
    XCTAssertTrue([[theme getFindSlotButtonTitleColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertEqualObjects([theme getFindSlotButtonTitleFont], [UIFont systemFontOfSize:15.0]);
    XCTAssertTrue([[theme getFindSlotButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"0053BF"]]);
    XCTAssertTrue([[theme getNotInterestedButtonColor] isEqual:[FCTheme colorWithHex:@"687D99"]]);
    XCTAssertEqualObjects([theme getNotInterestedButtonFont], [UIFont systemFontOfSize:15.0]);
    
    XCTAssertTrue([[theme getCarouselTitleColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertEqualObjects([theme getCarouselTitleFont], [UIFont boldSystemFontOfSize:17.0]);
    XCTAssertTrue([[theme getCarouselDescriptionColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertEqualObjects([theme getCarouselDescriptionFont], [UIFont systemFontOfSize:15.0]);
    XCTAssertTrue([[theme getCarouselSelectedTextColor] isEqual:[FCTheme colorWithHex:@"808080"]]);
    XCTAssertEqualObjects([theme getCarouselSelectedTextFont], [UIFont systemFontOfSize:15.0]);
    XCTAssertTrue([[theme getCarouselActionButtonColor] isEqual:[FCTheme colorWithHex:@"0079FF"]]);
    XCTAssertEqualObjects([theme getCarouselActionButtonFont], [UIFont systemFontOfSize:15.0]);
    XCTAssertTrue([[theme getCarouselSelectedCardBackground] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    
    XCTAssertTrue([[theme getDropDownBarBorderColor] isEqual:[FCTheme colorWithHex:@"45A4EC"]]);
    XCTAssertEqualObjects([theme getDropDownBarFont], [UIFont systemFontOfSize:15.0]);
    XCTAssertEqualObjects([theme getDropDownPickerOptionFont], [UIFont systemFontOfSize:15.0]);
    XCTAssertEqual([theme getDropDownPickerOptionHeight], 44.0);
    XCTAssertEqual([theme getDropDownPickerViewPortraitHeight], 220.0);
    XCTAssertEqual([theme getDropDownPickerViewLandScapeHeight], 132.0);
    
    XCTAssertEqualObjects([theme getQuickReplyMessageFont], [UIFont fontWithName:@"Arial" size:15]);
    XCTAssertTrue([[theme getQuickReplyBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme getQuickReplyCellBackgroundColor] isEqual:[FCTheme colorWithHex:@"0380fc"]]);
    XCTAssertTrue([[theme getQuickReplyMessageColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertEqual([theme getQuickReplyCellPadding], 10.0);
    XCTAssertEqual([theme getQuickReplyRowPadding], 10.0);
    XCTAssertEqual([theme getQuickReplyMessageCornerRadius], 10.0);
    XCTAssertEqual([theme getQuickReplyHeightPercentage], 35.0);
    
    XCTAssertEqualObjects([theme unsupportedMsgFragmentFont], [UIFont systemFontOfSize:15]);
    XCTAssertTrue([[theme unsupportedMsgFragmentFontColor] isEqual:[FCTheme colorWithHex:@"8D96A5"]]);
    XCTAssertTrue([[theme unsupportedMsgFragmentBorderColor] isEqual:[FCTheme colorWithHex:@"F2F3F5"]]);
    XCTAssertTrue([[theme unsupportedMsgFragmentBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    
    XCTAssertTrue([[theme conversationOverlayBackgroundColor] isEqual:[FCTheme colorWithHex:@"34AADC"]]);
    XCTAssertEqualObjects([theme conversationOverlayTextFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme conversationOverlayTextColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    
    XCTAssertEqualObjects([theme imgAttachBackButtonFont], [UIFont systemFontOfSize:16]);
    XCTAssertTrue([[theme imgAttachBackButtonFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    
    XCTAssertTrue([[theme custSatDialogueYesButtonTextColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertEqualObjects([theme custSatDialogueYesButtonFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme custSatDialogueYesButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"007AFF"]]);
    XCTAssertTrue([[theme custSatDialogueYesButtonBorderColor] isEqual:[FCTheme colorWithHex:@"808285"]]);
    
    XCTAssertTrue([[theme custSatDialogueNoButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"F6F6F5"]]);
    XCTAssertTrue([[theme custSatDialogueNoButtonTextColor] isEqual:[FCTheme colorWithHex:@"535353"]]);
    XCTAssertEqualObjects([theme custSatDialogueNoButtonFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme custSatDialogueNoButtonBorderColor] isEqual:[FCTheme colorWithHex:@"808285"]]);
    
    XCTAssertTrue([[theme custSatDialogueBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    
    XCTAssertTrue([[theme custSatDialogueTitleTextColor] isEqual:[FCTheme colorWithHex:@"1D2129"]]);
    XCTAssertEqualObjects([theme custSatDialogueTitleFont], [UIFont systemFontOfSize:15]);
    
    XCTAssertTrue([[theme csatPromptSubmitButtonColor] isEqual:[FCTheme colorWithHex:@"378CF8"]]);
    XCTAssertEqualObjects([theme csatPromptSubmitButtonTitleFont], [UIFont systemFontOfSize:15]);
    XCTAssertTrue([[theme csatPromptSubmitButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"F7F7F7"]]);
    
    XCTAssertTrue([[theme csatPromptInputTextFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertEqualObjects([theme csatPromptInputTextFont], [UIFont systemFontOfSize:13]);
    XCTAssertTrue([[theme csatPromptInputTextBorderColor] isEqual:[FCTheme colorWithHex:@"808285"]]);
    
    XCTAssertEqualObjects([theme csatPromptInputTextFont], [UIFont systemFontOfSize:13]);
    XCTAssertTrue([[theme csatPromptInputTextBorderColor] isEqual:[FCTheme colorWithHex:@"808285"]]);
    
    XCTAssertTrue([[theme csatPromptRatingBarColor] isEqual:[FCTheme colorWithHex:@"0BA4DB"]]);
    
    XCTAssertTrue([[theme csatPromptHorizontalLineColor] isEqual:[FCTheme colorWithHex:@"B3B3B3"]]);
    XCTAssertTrue([[theme csatDialogBackgroundColor] isEqual:[FCTheme colorWithHex:@"F7F7F7"]]);
    
    XCTAssertTrue([[theme inputToolbarBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme inputToolbarDividerColor] isEqual:[FCTheme colorWithHex:@"B3B3B3"]]);
    
    XCTAssertTrue([[theme inputTextFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertEqualObjects([theme inputTextFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme inputTextfieldBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme inputTextCursorColor] isEqual:[FCTheme colorWithHex:@"808285"]]);
    XCTAssertTrue([[theme inputTextBorderColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme inputTextPlaceholderFontColor] isEqual:[FCTheme colorWithHex:@"D3D3D3"]]);
    XCTAssertTrue([[theme sendButtonColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    
    XCTAssertTrue([[theme actionButtonTextColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertEqualObjects([theme actionButtonFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme actionButtonSelectedColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertTrue([[theme actionButtonColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme actionButtonBorderColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    
    XCTAssertEqualObjects([theme getUserMessageTimeFont], [UIFont systemFontOfSize:11]);
    XCTAssertTrue([[theme getUserMessageTimeFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    
    XCTAssertTrue([[theme userHyperlinkColor] isEqual:[FCTheme colorWithHex:@"2283F6"]]);
    XCTAssertEqualObjects([theme userMessageFont], [UIFont fontWithName:@"Arial" size:15]);
    XCTAssertTrue([[theme userMessageFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertTrue([theme userMessageTextAlignment] == NSTextAlignmentNatural);
    
    XCTAssertEqualObjects([theme agentMessageTimeFont], [UIFont systemFontOfSize:11]);
    XCTAssertTrue([[theme agentMessageTimeFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    
    XCTAssertTrue([[theme agentMessageFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertTrue([theme agentMessageTextAlignment] == NSTextAlignmentNatural);
    XCTAssertTrue([[theme agentHyperlinkColor] isEqual:[FCTheme colorWithHex:@"2283F6"]]);
    XCTAssertEqualObjects([theme agentMessageFont], [UIFont fontWithName:@"Arial" size:15]);
    
    XCTAssertTrue([[theme agentNameFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertEqualObjects([theme agentNameFont], [UIFont systemFontOfSize:13]);
    
    XCTAssertEqualObjects([theme channelTitleFont], [UIFont systemFontOfSize:15]);
    XCTAssertTrue([[theme channelTitleFontColor] isEqual:[FCTheme colorWithHex:@"222222"]]);
    
    XCTAssertEqualObjects([theme channelDescriptionFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme channelDescriptionFontColor] isEqual:[FCTheme colorWithHex:@"ABABAB"]]);
    XCTAssertEqual([theme numberOfChannelListDescriptionLines], 1);
    
    XCTAssertEqualObjects([theme channelLastUpdatedFont], [UIFont systemFontOfSize:12]);
    XCTAssertTrue([[theme channelLastUpdatedFontColor] isEqual:[FCTheme colorWithHex:@"ABABAB"]]);
    
    XCTAssertEqualObjects([theme badgeButtonFont], [UIFont systemFontOfSize:13]);
    XCTAssertTrue([[theme badgeButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"3399FF"]]);
    XCTAssertTrue([[theme badgeButtonTitleColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    
    XCTAssertTrue([[theme channelIconPlaceholderImageBackgroundColor] isEqual:[FCTheme colorWithHex:@"3F51B5"]]);
    XCTAssertEqualObjects([theme channelIconPlaceholderImageCharFont], [UIFont systemFontOfSize:22]);
    
    XCTAssertTrue([[theme channelListCellSeparatorColor] isEqual:[FCTheme colorWithHex:@"DE4147"]]);
    XCTAssertTrue([[theme channelListBackgroundColor] isEqual:[FCTheme colorWithHex:@"F8FAFA"]]);
    
    XCTAssertTrue([[theme channelCellSelectedColor] isEqual:[FCTheme colorWithHex:@"DCDCDC"]]);
    XCTAssertTrue([[theme channelListCellBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    
    XCTAssertTrue([[theme channelEmptyResultMessageFontColor] isEqual:[FCTheme colorWithHex:@"525454"]]);
    XCTAssertEqualObjects([theme channelEmptyResultMessageFont], [UIFont systemFontOfSize:15]);
    
    XCTAssertTrue([[theme getCalendarPopupNavBarTitleTextColor] isEqual:[FCTheme colorWithHex:@"283A59"]]);
    XCTAssertEqualObjects([theme getCalendarPopupNavBarTitleTextFont], [UIFont boldSystemFontOfSize:15]);
    
    XCTAssertTrue([[theme getCalendarPopupNavBarDurationTextColor] isEqual:[FCTheme colorWithHex:@"465571"]]);
    XCTAssertEqualObjects([theme getCalendarPopupNavBarDurationTextFont], [UIFont systemFontOfSize:13]);
    
    XCTAssertTrue([[theme getCalendarPopupNavBarBackgroundColor] isEqual:[FCTheme colorWithHex:@"F5F5F5"]]);
    XCTAssertTrue([[theme getCalendarPopupNavBarDividerColor] isEqual:[FCTheme colorWithHex:@"B3B3B3"]]);
    
    XCTAssertTrue([[theme getCalendarEmailViewDescTextColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertEqualObjects([theme getCalendarEmailViewDescTextFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme getCalendarEmailViewTextFieldTextColor] isEqual:[FCTheme colorWithHex:@"495973"]]);
    XCTAssertEqualObjects([theme getCalendarEmailViewTextFieldTextFont], [UIFont systemFontOfSize:14]);
    
    XCTAssertTrue([[theme getCalendarEmailViewNextBtnTitleColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertEqualObjects([theme getCalendarEmailViewNextBtnTitleFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme getCalendarEmailViewNextBtnBackgroundColor] isEqual:[FCTheme colorWithHex:@"0249A6"]]);
    
    XCTAssertTrue([[theme getCalendarSlotsSessionNameTextColor] isEqual:[FCTheme colorWithHex:@"808080"]]);
    XCTAssertEqualObjects([theme getCalendarSlotsSessionNameTextFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme getCalendarSlotsDateTextColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getCalendarSlotsDateTextFont], [UIFont boldSystemFontOfSize:14]);
    
    XCTAssertTrue([[theme getCalendarSlotsStateDescTextColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getCalendarSlotsStateDescTextFont], [UIFont systemFontOfSize:16]);
    XCTAssertTrue([[theme getCalendarSlotsButtonTitleColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getCalendarSlotsButtonTitleFont], [UIFont systemFontOfSize:13]);
    
    XCTAssertTrue([[theme getCalendarSlotsButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme getCalendarSlotsButtonSelectedBackgroundColor] isEqual:[FCTheme colorWithHex:@"091E42"]]);
    XCTAssertTrue([[theme getCalendarSlotsButtonBorderColor] isEqual:[FCTheme colorWithHex:@"595959"]]);
    XCTAssertTrue([[theme getCalendarSlotsShowMoreButtonTitleColor] isEqual:[FCTheme colorWithHex:@"707C92"]]);
    
    XCTAssertEqualObjects([theme getCalendarSlotsShowMoreButtonTitleFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme getCalendarSlotsShowMoreButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    
    XCTAssertTrue([[theme getCalendarSlotsShowMoreButtonBorderColor] isEqual:[FCTheme colorWithHex:@"707C92"]]);
    XCTAssertTrue([[theme getCalendarSlotsDividerColor] isEqual:[FCTheme colorWithHex:@"E1E4E8"]]);
    
    XCTAssertTrue([[theme getCalendarConfirmDescriptionTextColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getCalendarConfirmDescriptionTextFont], [UIFont systemFontOfSize:16]);
    
    XCTAssertTrue([[theme getCalendarConfirmTimeTextColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getCalendarConfirmTimeTextFont], [UIFont boldSystemFontOfSize:21]);
    
    XCTAssertTrue([[theme getCalendarConfirmDateTextColor] isEqual:[FCTheme colorWithHex:@"293B5B"]]);
    XCTAssertEqualObjects([theme getCalendarConfirmDateTextFont], [UIFont systemFontOfSize:16]);
    
    XCTAssertTrue([[theme getCalendarConfirmAvatarsBorderColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme getCalendarConfirmButtonTitleColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertEqualObjects([theme getCalendarConfirmButtonTitleFont], [UIFont systemFontOfSize:15]);
    
    XCTAssertTrue([[theme getCalendarConfirmButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"0249A6"]]);
    XCTAssertTrue([[theme getCalendarConfirmChangeSlotButtonTitleColor] isEqual:[FCTheme colorWithHex:@"707C92"]]);
    XCTAssertEqualObjects([theme getCalendarConfirmChangeSlotButtonTitleFont], [UIFont systemFontOfSize:15]);
    XCTAssertTrue([[theme getCalendarConfirmChangeSlotButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme getCalendarConfirmChangeSlotButtonBorderColor] isEqual:[FCTheme colorWithHex:@"707C92"]]);
    
    XCTAssertEqualObjects([theme voiceRecordingTimeLabelFont], [UIFont systemFontOfSize:13]);
    XCTAssertTrue([[theme faqListViewCellBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertEqual([theme numberOfCategoryListDescriptionLines], 1);
    XCTAssertEqualObjects([theme faqCategoryTitleFont], [UIFont systemFontOfSize:15]);
    
    XCTAssertTrue([[theme faqCategoryTitleFontColor] isEqual:[FCTheme colorWithHex:@"222222"]]);
    XCTAssertTrue([[theme faqCategoryBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme gridViewCardBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme gridViewCardShadowColor] isEqual:[FCTheme colorWithHex:@"9A9B9E"]]);
    XCTAssertTrue([[theme faqPlaceholderIconBackgroundColor] isEqual:[FCTheme colorWithHex:@"535353"]]);
    XCTAssertTrue([[theme faqListCellSeparatorColor] isEqual:[FCTheme colorWithHex:@"C9C9CA"]]);
    XCTAssertTrue([[theme faqListCellSelectedColor] isEqual:[FCTheme colorWithHex:@"DCDCDC"]]);
    
    XCTAssertEqualObjects([theme faqCategoryDetailFont], [UIFont systemFontOfSize:14]);
    
    XCTAssertTrue([[theme faqCategoryDetailFontColor] isEqual:[FCTheme colorWithHex:@"808285"]]);
    
    XCTAssertTrue([[theme faqEmptyResultMessageFontColor] isEqual:[FCTheme colorWithHex:@"525454"]]);
    XCTAssertEqualObjects([theme faqEmptyResultMessageFont], [UIFont systemFontOfSize:15]);
    XCTAssertTrue([[theme articleListFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertEqualObjects([theme articleListFont], [UIFont systemFontOfSize:14]);
    
    XCTAssertTrue([[theme articleListBackgroundColor] isEqual:[FCTheme colorWithHex:@"F8FAFA"]]);
    XCTAssertTrue([[theme articleListCellSeperatorColor] isEqual:[FCTheme colorWithHex:@"C9C9CA"]]);
    XCTAssertTrue([[theme articleListCellBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertEqualObjects([theme searchBarFont], [UIFont systemFontOfSize:13]);
    
    XCTAssertTrue([[theme searchBarFontColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertTrue([[theme searchBarTextViewBorderColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme searchBarInnerBackgroundColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme searchBarOuterBackgroundColor] isEqual:[FCTheme colorWithHex:@"F8F8F8"]]);
    
    XCTAssertTrue([[theme searchBarCancelButtonColor] isEqual:[FCTheme colorWithHex:@"0079FF"]]);
    
    XCTAssertEqualObjects([theme searchBarCancelButtonFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme searchBarCursorColor] isEqual:[FCTheme colorWithHex:@"0079FF"]]);
    XCTAssertTrue([[theme SearchBarTextPlaceholderColor] isEqual:[FCTheme colorWithHex:@"808285"]]);
    
    XCTAssertTrue([[theme progressBarColor] isEqual:[FCTheme colorWithHex:@"6D6D6D"]]);
    XCTAssertTrue([[theme dialogueButtonColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme talkToUsButtonTextColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme talkToUsButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"4D90E9"]]);
    XCTAssertEqualObjects([theme talkToUsButtonFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme noItemsFoundMessageColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    
    XCTAssertTrue([[theme getArticleDetailCSSFileName] isEqualToString :@"normalize"]);
    
    XCTAssertTrue([[theme imagePreviewScreenBackgroundColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    
    XCTAssertTrue([theme sdkFont].pointSize == 17.0);
    
    XCTAssertTrue([[theme notificationBackgroundColor] isEqual:[FCTheme colorWithHex:@"6D6D6D"]]);
    XCTAssertTrue([[theme notificationTitleTextColor] isEqual:[FCTheme colorWithHex:@"EFEFEF"]]);
    XCTAssertTrue([[theme notificationMessageTextColor] isEqual:[FCTheme colorWithHex:@"EFEFEF"]]);
    
    XCTAssertEqualObjects([theme notificationTitleFont], [UIFont systemFontOfSize:14]);
    XCTAssertEqualObjects([theme notificationMessageFont], [UIFont systemFontOfSize:14]);
    
    XCTAssertTrue([[theme notificationChannelIconBorderColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme notificationChannelIconBackgroundColor] isEqual:[FCTheme colorWithHex:@"3F51B5"]]);
    XCTAssertTrue([theme shouldShowPushPrompt] == YES);
    
    XCTAssertTrue([[theme dialogueTitleTextColor] isEqual:[FCTheme colorWithHex:@"535353"]]);
    
    XCTAssertEqualObjects([theme dialogueTitleFont], [UIFont systemFontOfSize:15]);
    XCTAssertEqualObjects([theme dialogueYesButtonFont], [UIFont systemFontOfSize:14]);
    
    XCTAssertTrue([[theme dialogueYesButtonTextColor] isEqual:[FCTheme colorWithHex:@"FFFFFF"]]);
    XCTAssertTrue([[theme dialogueYesButtonBorderColor] isEqual:[FCTheme colorWithHex:@"D8D8D8"]]);
    XCTAssertTrue([[theme dialogueYesButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"007AFF"]]);
    
    XCTAssertTrue([[theme dialogueNoButtonBackgroundColor] isEqual:[FCTheme colorWithHex:@"F6F6F5"]]);
    XCTAssertTrue([[theme dialogueNoButtonTextColor] isEqual:[FCTheme colorWithHex:@"535353"]]);
    XCTAssertTrue([[theme dialogueNoButtonBorderColor] isEqual:[FCTheme colorWithHex:@"C1C1BF"]]);
    
    XCTAssertEqualObjects([theme dialogueNoButtonFont], [UIFont systemFontOfSize:14]);
    XCTAssertTrue([[theme dialogueBackgroundColor] isEqual:[FCTheme colorWithHex:@"F6F6F5"]]);
    
    XCTAssertTrue([[theme navigationBarBackgroundColor] isEqual:[FCTheme colorWithHex:@"F8F8F8"]]);
    XCTAssertEqualObjects([theme navigationBarTitleFont], [UIFont systemFontOfSize:17]);
    XCTAssertTrue([[theme navigationBarTitleColor] isEqual:[FCTheme colorWithHex:@"000000"]]);
    XCTAssertTrue([[theme navigationBarButtonColor] isEqual:[FCTheme colorWithHex:@"0079FF"]]);
    XCTAssertEqualObjects([theme navigationBarButtonFont], [UIFont systemFontOfSize:16]);
}

@end
