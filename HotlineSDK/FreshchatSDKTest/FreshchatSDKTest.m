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

@interface FreshchatSDKTest : XCTestCase

@end

@implementation FreshchatSDKTest

- (void)setUp {
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithAbbreviation:@"IST"];
    [NSTimeZone setDefaultTimeZone:timeZone];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
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

- (void) testValidEmailId {
    BOOL validEmail = [FCStringUtil isValidEmail:@"support@freshchat.com"];
    XCTAssertTrue(validEmail);
    
    BOOL inValidEmail = [FCStringUtil isValidEmail:@"support.freshchat.com"];
    XCTAssertFalse(inValidEmail);
}

- (void) testDurationConversion {
    NSString *durationVal = [FCUtilities getDurationFromSecs : 1800];
    XCTAssertEqualObjects(durationVal, @"30 mins", @"Test Passed for duration conversion");
}

- (void) testDurationDiff {
    NSString *interval = [FCUtilities intervalStrFromMillis: 0 toMillis:1800000];
    XCTAssertEqualObjects(interval, @"30 mins", @"Test Passed for duration conversion");
}

-(void) testIsTemplateFragment {
    NSString *replyFragmentValid = @"[{\"templateType\":\"carousel\",\"sections\":[{\"name\":\"carousel_title\",\"fragments\":[{\"content\":\"Hello choose one of following Hello choose one of following Hello choose one of following\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"cards\",\"fragments\":[{\"templateType\":\"carousel_card_default\",\"sections\":[{\"name\":\"hero_image\",\"fragments\":[{\"height\":400,\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessage/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408374876.png\",\"position\":0,\"thumbnail\":{\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessageThumb/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408374986.jpeg\",\"width\":400,\"height\":400},\"fragmentType\":2,\"contentType\":\"application/octet-stream\",\"width\":400}]},{\"name\":\"title\",\"fragments\":[{\"content\":\"Apple\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"description\",\"fragments\":[{\"content\":\"Apple Inc. is an American multinational technology company headquartered in Cupertino, California, that designs, develops, and sells consumer electronics, computer software, and online services. It is considered one of the Big Four technology companies, alongside Amazon, Google, and Microsoft.\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"callback\",\"fragments\":[{\"label\":\"Select\",\"payload\":\"appelpayload\",\"position\":0,\"fragmentType\":52}]}],\"position\":0,\"fragmentType\":1002},{\"templateType\":\"carousel_card_default\",\"sections\":[{\"name\":\"hero_image\",\"fragments\":[{\"height\":200,\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessage/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408375251.png\",\"position\":0,\"thumbnail\":{\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessageThumb/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408375335.jpeg\",\"width\":200,\"height\":200},\"fragmentType\":2,\"contentType\":\"application/octet-stream\",\"width\":200}]},{\"name\":\"title\",\"fragments\":[{\"content\":\"Google\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"description\",\"fragments\":[{\"content\":\"Google LLC is an American multinational technology company that specializes in Internet-related services and products, which include online advertising technologies, search engine, cloud computing, software, and hardware.\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"callback\",\"fragments\":[{\"label\":\"Select\",\"payload\":\"GooglePayload\",\"position\":0,\"fragmentType\":52}]}],\"position\":0,\"fragmentType\":1002},{\"templateType\":\"carousel_card_default\",\"sections\":[{\"name\":\"hero_image\",\"fragments\":[{\"height\":1200,\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessage/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408375470.png\",\"position\":0,\"thumbnail\":{\"content\":\"https://fc-use1-00-pics-bkt-00.s3.amazonaws.com/e9c099365d14c657e002111408d180a0374159e114ae1bed8f6b426c55d5f4d3/f_feedbackMessageThumb/u_7806186dc4235f4808495b5d71033dd3cceea4cb960fa22238cc6edc807e3749/img_1587408375553.jpeg\",\"width\":400,\"height\":400},\"fragmentType\":2,\"contentType\":\"application/octet-stream\",\"width\":1200}]},{\"name\":\"title\",\"fragments\":[{\"content\":\"Facebook\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"description\",\"fragments\":[{\"content\":\"Facebook, Inc. is an American social media and technology company based in Menlo Park, California.\",\"contentType\":\"text/html\",\"position\":0,\"fragmentType\":1}]},{\"name\":\"callback\",\"fragments\":[{\"label\":\"Select\",\"payload\":\"Facebook Payload\",\"position\":0,\"fragmentType\":52}]},{\"name\":\"view\",\"fragments\":[{\"target\":\"_self\",\"label\":\"Visit\",\"content\":\"https://www.facebook.com\",\"contentType\":\"text/vnd.submit-form\",\"position\":0,\"fragmentType\":5}]}],\"position\":0,\"fragmentType\":1002}]}],\"position\":0,\"fragmentType\":1002}]";
    NSString *replyFragmentInValid = @"";
    XCTAssertEqual([replyFragmentValid isTemplateFragment], true);
    XCTAssertEqual([replyFragmentInValid isTemplateFragment], false);
}

@end
