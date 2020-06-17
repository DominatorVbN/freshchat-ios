//
//  Message.h
//  HotlineSDK
//
//  Created by user on 01/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FreshchatSDK.h"
#import "FCChannels.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCConversations.h"
#import "FCMessageServices.h"
#import <UIKit/UIImage.h>
#import "FCCoreServices.h"
#import "FCMessageData.h"
#import "FCMessageFragments.h"
#import "FCMessageHelper.h"
#import "FCMessageUtil.h"

#define MESSAGE_NOT_UPLOADED 0
#define MESSAGE_UPLOADING 1
#define MESSAGE_UPLOADED 2

#define FC_CALENDAR_INVITE_MSG @9001
#define FC_CALENDAR_CANCEL_MSG @9002
#define FC_CALENDAR_CONFIRM_MSG @9003
#define FC_CALENDAR_FAILURE_MSG @9004

NS_ASSUME_NONNULL_BEGIN

@interface FCMessages : NSManagedObject

    @property (nullable, nonatomic, retain) NSNumber *channelId;
    @property (nullable, nonatomic, retain) NSString *conversationId;
    @property (nullable, nonatomic, retain) NSString *createdMillis;
    @property (nullable, nonatomic, retain) NSNumber *marketingId;
    @property (nullable, nonatomic, retain) NSString *messageAlias;
    @property (nullable, nonatomic, retain) NSString *messageUserAlias;
    @property (nullable, nonatomic, retain) NSString *replyFragments;
    @property (nullable, nonatomic, retain) NSNumber *messageUserType;
    @property (nullable, nonatomic, retain) NSNumber *uploadStatus;
    @property (nonatomic) BOOL isMarkedForUpload;
    @property (nonatomic) BOOL isWelcomeMessage;
    @property (nonatomic) BOOL isRead;
    @property (nonatomic) BOOL isDownloading;
    @property (nonatomic) BOOL hasActiveCalInvite;
    @property (nullable, nonatomic, retain) NSString *internalMeta;
    @property (nullable, nonatomic, retain) FCChannels *belongsToChannel;
    @property (nullable, nonatomic, retain) FCConversations *belongsToConversation;
    @property (nullable, nonatomic, retain) NSNumber *messageType;
    @property (nullable, nonatomic, retain) NSNumber *replyToMessage;
    @property (nullable, nonatomic, retain) NSNumber *messageId;

    +(FCMessages *)getWelcomeMessageForChannel:(FCChannels *)channel;
    +(void) removeWelcomeMessage:(FCChannels *)channel;
    +(FCMessages *) retriveMessageForMessageId: (NSString *)messageId;
    -(NSString *) getJSON;
    +(NSString *)generateMessageID;
    +(FCMessages *)createNewMessage:(NSDictionary *)message toChannelID:(NSNumber *)channelId;
    -(void) associateMessageToConversation: (FCConversations *)conversation;
    +(FCMessages *)saveMessageInCoreData:(NSArray *)fragmentsInfo forMessageType:(NSNumber *)msgType withInfo:(NSDictionary *)info onConversation:(FCConversations *)conversation inReplyTo:(nullable NSNumber *)messageID;
    +(void)uploadAllUnuploadedMessages;
    -(void) markAsRead;
    -(void) markAsUnread;
    +(NSInteger)getUnreadMessagesCountForChannel:(NSNumber *)channel;
    +(void) markAllMessagesAsReadForChannel:(FCChannels *)channel;
    -(BOOL) isMarketingMessage;
    +(NSArray *) getAllMesssageForChannel:(FCChannels *)channel withHandler:(void (^) (FCMessageData *)) calendarBlock;
    +(bool) hasUserMessageInContext:(NSManagedObjectContext *)context;
    +(long long) lastMessageTimeInContext:(NSManagedObjectContext *)context;
    +(long) daysSinceLastMessageInContext:(NSManagedObjectContext *)context;
    -(NSMutableDictionary *) convertMessageToDictionary;
    -(NSString *)getDetailDescriptionForMessage;
    + (void) updateCalInviteStatusForId:(NSString *)calInviteId forChannel:(FCChannels*)channel completionHandler:(nullable void (^)()) handler;
    + (NSString*) getJsonStringObjForMessage : (NSDictionary *) message withKey : (NSString *) key;
@end

NS_ASSUME_NONNULL_END
