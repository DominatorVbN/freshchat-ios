//
//  FreshchatSDKTest.m
//  FreshchatSDKTest
//
//  Created by Hemanth Kumar on 24/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FCTemplateFactory.h"
#import "FCDropDownViewModel.h"

@interface FreshchatSDKTest : XCTestCase

@end

@implementation FreshchatSDKTest

- (void)setUp {
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

@end
