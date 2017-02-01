//
//  HLEventManager.h
//  HotlineSDK
//
//  Created by Harish Kumar on 09/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KonotorDataManager.h"
#import "FDUtilities.h"
#import "HLEvent.h"

//Event plist file path
#define HLEVENT_DIR_PATH @"Hotline/Events"
#define HLEVENT_FILE_NAME @"eventsDict.plist" // Hotline/Events/events.plist

//bulk event base url for debug mode only
#define HLEVENTS_BULK_EVENTS_URL @"https://events.hotline.io/bulkevents"
#define HLEVENTS_BULK_EVENTS_DEBUG_URL @"https://events.staging.konotor.com/bulkevents"

//Events api response code
#define EVENT_STORE_RESPCODE_REQUEST_ACCEPTED           200
#define EVENT_STORE_RESPCODE_INVALID_REQUEST_FORMAT     400
#define EVENT_STORE_RESPCODE_UNSUPPORTED_MEDIA_TYPE     415
#define EVENT_STORE_RESPCODE_VALIDATION_FAILED          422

#define HLEVENTS_HTTP_RESPONSE_CODE_NOT_SUPPORTED               530
#define HLEVENTS_HTTP_RESPONSE_CODE_VALIDATION_FAILED           422
#define HLEVENTS_HTTP_RESPONSE_CODE_UNSUPPORTED_MEDIA_TYPE      415

//Events Name
#define HLEVENT_FAQ_OPEN_CATEGORY                   @"faq_open_category"
#define HLEVENT_FAQ_OPEN_ARTICLE                    @"faq_open_article"
#define HLEVENT_FAQ_UPVOTE_ARTICLE                  @"faq_upvote_article"
#define HLEVENT_FAQ_DOWNVOTE_ARTICLE                @"faq_downvote_article"
#define HLEVENT_FAQ_SEARCH                          @"faq_search"
#define HLEVENT_FAQ_SEARCH_LAUNCH                   @"faq_search_launch"
#define HLEVENT_CHANNELS_LAUNCH                     @"channels_launch"
#define HLEVENT_CONVERSATION_SEND_MESSAGE           @"conversation_send_message"
#define HLEVENT_FAQ_LAUNCH                          @"faqs_launch"
#define HLEVENT_CONVERSATIONS_LAUNCH                @"conversation_launch"
#define HLEVENT_CONVERSATION_DEEPLINK_LAUNCH        @"conversation_deeplink_launch"

//Event Params
#define HLEVENT_PARAM_CATEGORY_ID                   @"category_id"
#define HLEVENT_PARAM_CATEGORY_NAME                 @"category_name"
#define HLEVENT_PARAM_ARTICLE_ID                    @"article_id"
#define HLEVENT_PARAM_ARTICLE_NAME                  @"article_name"
#define HLEVENT_PARAM_ARTICLE_SEARCH_KEY            @"search_key"
#define HLEVENT_PARAM_ARTICLE_SEARCH_COUNT          @"search_article_count"
#define HLEVENT_PARAM_CHANNEL_ID                    @"channel_id"
#define HLEVENT_PARAM_CHANNEL_NAME                  @"channel_name"
#define HLEVENT_PARAM_MESSAGE_ALIAS                 @"message_alias"
#define HLEVENT_PARAM_MESSAGE_TYPE                  @"message_type"
#define HLEVENT_PARAM_SOURCE                        @"source"
#define HLEVENT_PARAM_TYPE                          @"type"

//Type of event
#define HLEVENT_TYPE_SDK                            @"SDK"
#define HLEVENT_TYPE_USER                           @"USER"

//Events Article Open Source Type
#define HLEVENT_LAUNCH_SOURCE_ARTICLE_LIST          @"article_list"
#define HLEVENT_LAUNCH_SOURCE_SEARCH                @"search_article"
#define HLEVENT_LAUNCH_SOURCE_DEEPLINK              @"deep_link"

//Channel launch source
#define HLEVENT_LAUNCH_SOURCE_DEFAULT               @"default"

//Conversation launch source
#define HLEVENT_LAUNCH_SOURCE_CONTACTUS             @"contact_us"
#define HLEVENT_LAUNCH_SOURCE_ARTICLE_NOT_HELPFUL   @"article_not_found_helpful"

//Message types
#define HLEVENT_MESSAGE_TYPE_TEXT                   @"text"
#define HLEVENT_MESSAGE_TYPE_IMAGE                  @"image"
#define HLEVENT_MESSAGE_TYPE_AUDIO                  @"audio"

//search launch
#define HLEVENT_SEARCH_LAUNCH_CATEGORY_LIST         @"category_list"

#define HLEVENTS_BATCH_SIZE 25

@interface HLEventManager : NSObject

+ (instancetype) sharedInstance;
+ (NSString *)getUserSessionId;
- (void) submitSDKEvent:(NSString *)eventName withBlock:(void(^)(HLEvent *event))builderBlock;
- (void) startEventsUploadTimer;
- (void) cancelEventsUploadTimer;
- (void) reset;
- (void) upload;

@end
