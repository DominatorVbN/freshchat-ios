//
//  KonotorMessage.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "FCMessageUtil.h"
#import "FCConversations.h"
#import "FCMessageHelper.h"
#import "FCMessageBinaries.h"
#import "FCDataManager.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCSecureStore.h"
#import "FCMessageServices.h"
#import "FCLocalNotification.h"
#import "FCCoreServices.h"
#import "FCConstants.h"
#import "FCUserDefaults.h"
#import "FCEventsHelper.h"

#define KONOTOR_IMG_COMPRESSION YES

@class KonotorConversationData;
@class KonotorMessageData;

@implementation FCMessageUtil

@dynamic articleID;
@dynamic actionLabel;
@dynamic actionURL;
@dynamic audioURL;
@dynamic bytes;
@dynamic createdMillis;
@dynamic durationInSecs;
@dynamic isDownloading;
@dynamic isWelcomeMessage;
@dynamic isMarkedForUpload;
@dynamic marketingId;
@dynamic messageAlias;
@dynamic messageRead;
@dynamic messageType;
@dynamic messageUserId;
@dynamic picCaption;
@dynamic picHeight;
@dynamic picThumbHeight;
@dynamic picThumbUrl;
@dynamic picThumbWidth;
@dynamic picUrl;
@dynamic picWidth;
@dynamic read;
@dynamic text;
@dynamic uploadStatus;
@dynamic belongsToChannel;
@dynamic belongsToConversation;
@dynamic hasMessageBinary;

NSMutableDictionary *gkMessageIdMessageMap_old;

static BOOL messageExistsDirty = YES;
static BOOL messageTimeDirty = YES;

+(NSString *)generateMessageID{
    NSTimeInterval  today = [[NSDate date] timeIntervalSince1970];
    NSString *userAlias = [FCUtilities getUserAliasWithCreate];
    NSString *intervalString = [NSString stringWithFormat:@"%.0f", today*1000];
    NSString *messageID  =[NSString stringWithFormat:@"%@%@%@",userAlias,@"_",intervalString];
    return messageID;
}

+(FCMessageUtil *)saveTextMessageInCoreData:(NSString *)text onConversation:(FCConversations *)conversation{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessageUtil *message = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    [message setMessageUserId:[USER_TYPE_MOBILE stringValue]];
    [message setMessageRead:YES];
    [message setText:text];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    message.belongsToConversation = conversation;
    message.isWelcomeMessage = NO;
    [datamanager save];
    [FCMessageUtil markDirty];
    return message;
}

+(void) markDirty{
    messageExistsDirty = YES;
    messageTimeDirty = YES;
}

+(FCMessageUtil* )savePictureMessageInCoreData:(UIImage *)image withCaption:(NSString *)caption onConversation:(nonnull FCConversations *)conversation{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessageUtil *message = (FCMessageUtil *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    
    [message setMessageUserId:[USER_TYPE_MOBILE stringValue]];
    [message setMessageAlias:[FCMessageUtil generateMessageID]];
    [message setMessageType:@3];
    [message setMessageRead:YES];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    [message setPicCaption:caption];
    FCMessageBinaries *messageBinary = (FCMessageBinaries *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_BINARIES_ENTITY inManagedObjectContext:context];
    NSData *imageData, *thumbnailData;
  
    if(image){
        imageData = UIImageJPEGRepresentation(image, 0.5);
        CGImageSourceRef src = CGImageSourceCreateWithData( (__bridge CFDataRef)(imageData), NULL);
        NSDictionary *osptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform, kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways, [NSNumber numberWithDouble:300], kCGImageSourceThumbnailMaxPixelSize, nil];
#if KONOTOR_IMG_COMPRESSION
        NSDictionary *compressionOptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform, kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways, [NSNumber numberWithDouble:1000], kCGImageSourceThumbnailMaxPixelSize, nil];
#endif
        
        CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)osptions); // Create scaled image
        
#if KONOTOR_IMG_COMPRESSION
        CGImageRef compressedImage = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)compressionOptions);
#endif
        
        UIImage *imgthumb = [[UIImage alloc] initWithCGImage:thumbnail];
        int h = imgthumb.size.height;
        int w = imgthumb.size.width;
        
#if KONOTOR_IMG_COMPRESSION
        UIImage *imgCompressed = [[UIImage alloc] initWithCGImage:compressedImage];
#endif

        thumbnailData = UIImageJPEGRepresentation(imgthumb,0.5);
        
#if KONOTOR_IMG_COMPRESSION
        imageData=UIImageJPEGRepresentation(imgCompressed, 0.5);
        [message setPicHeight:[NSNumber numberWithInt:imgCompressed.size.height]];
        [message setPicWidth:[NSNumber numberWithInt:imgCompressed.size.width]];
#else
        [message setPicHeight:[NSNumber numberWithInt:image.size.height]];
        [message setPicWidth:[NSNumber numberWithInt:image.size.width]];
        
#endif
        [message setPicThumbHeight:[NSNumber numberWithInt:h]];
        [message setPicThumbWidth:[NSNumber numberWithInt:w]];
        
        CFRelease(src);
        CFRelease(thumbnail);
    }
    
    [messageBinary setBinaryImage:imageData];
    [messageBinary setBinaryThumbnail:thumbnailData];
    [messageBinary setValue:message forKey:@"belongsToMessage"];
    [message setValue:messageBinary forKey:@"hasMessageBinary"];
    message.belongsToConversation = conversation;
    message.isWelcomeMessage = NO;
    [datamanager save];
    [FCMessageUtil markDirty];
    return message;
}

+(NSInteger)getUnreadMessagesCountForChannel:(NSNumber *)channelID{
    FCChannels *channel = [FCChannels getWithID:channelID inContext:[FCDataManager sharedInstance].mainObjectContext];
    return [channel unreadCount];
}

+(void)markAllMessagesAsReadForChannel:(FCChannels *)channel{
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"messageRead == NO AND belongsToChannel == %@",channel];
        request.predicate = predicate;
        NSArray *messages = [context executeFetchRequest:request error:&pError];
        if (messages.count>0) {
            for(int i=0;i<messages.count;i++){
                FCMessageUtil *message = messages[i];
                if(message){
                    if(![[message marketingId] isEqualToNumber:@0]){
                        [FCMessageServices markMarketingMessageAsRead:message context:context];
                    }else{
                        [message markAsRead];
                    }
                }
            }
            [FCCoreServices sendLatestUserActivity:channel];
        }
        [context save:nil];
    }];
}

+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessageUtil* messageObject = [FCMessageUtil retriveMessageForMessageId:messageId];
    if(!messageObject) return NO;
    
    FCMessageBinaries *pMessageBinary = (FCMessageBinaries*)[messageObject valueForKeyPath:@"hasMessageBinary"];
    if(!pMessageBinary){
        FCMessageBinaries *messageBinary = (FCMessageBinaries *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_BINARIES_ENTITY inManagedObjectContext:context];
        [pMessageBinary setBinaryImage:imageData];
        [messageBinary setValue:messageObject forKey:@"belongsToMessage"];
        [messageObject setValue:messageBinary forKey:@"hasMessageBinary"];
        [datamanager save];
        return YES;
    }else{
        [pMessageBinary setBinaryImage:imageData];
        [datamanager save];
        return YES;
    }
    return NO;
}


+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessageUtil* messageObject = [FCMessageUtil retriveMessageForMessageId:messageId];
    if(!messageObject){
        return NO;
    }
    FCMessageBinaries *pMessageBinary = (FCMessageBinaries*)[messageObject valueForKeyPath:@"hasMessageBinary"];
    if(!pMessageBinary){
        FCMessageBinaries *messageBinary = (FCMessageBinaries *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_BINARIES_ENTITY inManagedObjectContext:context];
        [pMessageBinary setBinaryThumbnail:imageData];
        [messageBinary setValue:messageObject forKey:@"belongsToMessage"];
        [messageObject setValue:messageBinary forKey:@"hasMessageBinary"];
        [datamanager save];
        return YES;
    }else{
        [pMessageBinary setBinaryThumbnail:imageData];
        [datamanager save];
        return YES;
    }
    return NO;
}

+(void)uploadAllUnuploadedMessages{
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isMarkedForUpload == YES AND uploadStatus == 0"];
        [request setPredicate:predicate];
        NSArray *array = [context executeFetchRequest:request error:&pError];
        if([array count]==0){
            return;
        }else{
            FDLog(@"There are %d unuploaded messages", (int)array.count);
            for(int i=0;i<[array count];i++){
                FCMessageUtil *message = array[i];
                FCConversations *convo = message.belongsToConversation;
                [FCMessageServices uploadMessage:message toConversation:convo onChannel:message.belongsToChannel];
            }
        }
    }];
}

+(FCMessageUtil *)retriveMessageForMessageId: (NSString *)messageId{
    if(gkMessageIdMessageMap_old){
        FCMessageUtil *message = [gkMessageIdMessageMap_old objectForKey:messageId];
        if(message) return message;
    }
    
    if(!gkMessageIdMessageMap_old){
        gkMessageIdMessageMap_old = [[ NSMutableDictionary alloc]init];
    }
    
    NSError *pError;
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"messageAlias == %@",messageId];
    [request setPredicate:predicate];
    
    NSArray *array = [context executeFetchRequest:request error:&pError];
    if([array count]==0){
        return nil;
    }
    
    if([array count] >1){
        return array[0];
        FDLog(@"%@", @"Multiple Messages stored with the same message Id");
    }else if([array count]==1){
        FCMessageUtil *message = [array objectAtIndex:0];
        if(message){
            [gkMessageIdMessageMap_old setObject:message forKey:messageId];
            return message;
        }
    }
    return nil;
}

-(void)associateMessageToConversation: (FCConversations *)conversation{
    if(conversation){
        NSMutableSet *mutableSetOfExistingConversationsOnDisk = [conversation  mutableSetValueForKey:@"hasMessages"];
        [mutableSetOfExistingConversationsOnDisk addObject:self];
        self.belongsToConversation = conversation;
        [[FCDataManager sharedInstance]save];
    }
}

-(NSString *)getJSON{
    NSMutableDictionary *messageDict = [[NSMutableDictionary alloc]init];
    [messageDict setObject:[self messageType] forKey:@"messageType"];
    if([[self messageType] intValue ]== 1)
        [messageDict setObject:[self text] forKey:@"text"];
    else if([[self messageType] intValue ]== 2)
        [messageDict setObject:[self durationInSecs] forKey:@"durationInSecs"];
    else if([[self messageType] intValue ]== 3)
    {
        [messageDict setObject:[self picThumbWidth] forKey:@"picThumbWidth"];
        [messageDict setObject:[self picThumbHeight] forKey:@"picThumbHeight"];
        [messageDict setObject:[self picHeight] forKey:@"picHeight"];
        [messageDict setObject:[self picWidth] forKey:@"picWidth"];
        
        if([self picCaption])
            [messageDict setObject:[self picCaption] forKey:@"picCaption"];
}
    NSError *error;
    NSData *pJsonString = [NSJSONSerialization dataWithJSONObject:messageDict options:0 error:&error];
    return [[NSString alloc ]initWithData:pJsonString encoding:NSUTF8StringEncoding];
}

-(void)markAsRead{
    [self setMessageRead:YES];
}

-(void)markAsUnread{
    BOOL wasRead = [self messageRead];
    if(!wasRead) return
    [self setMessageRead:NO];
}

+(FCMessageUtil *)createNewMessage:(NSDictionary *)message{
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    FCMessageUtil *newMessage = (FCMessageUtil *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    newMessage.isWelcomeMessage = NO;
    newMessage.messageAlias = [message valueForKey:@"alias"];
    newMessage.messageType = [message valueForKey:@"messageType"];
    newMessage.messageUserId = [message[@"messageUserType"]stringValue];
    newMessage.bytes = [message valueForKey:@"bytes"];
    newMessage.durationInSecs = [message valueForKey:@"durationInSecs"];
    newMessage.read = [message valueForKey:@"read"];
    [newMessage setAudioURL:[message valueForKey:@"binaryUrl"]];
    newMessage.text = (message[@"text"]) ? message[@"text"] : @"";
    [newMessage setCreatedMillis:[message valueForKey:@"createdMillis"]];
    [newMessage setMarketingId:[message valueForKey:@"marketingId"]];
    [newMessage setActionLabel:[message valueForKey:@"messageActionLabel"]];
    [newMessage setActionURL:[message valueForKey:@"messageActionUrl"]];
    
    if (message[@"articleId"]) {
        newMessage.articleID = message[@"articleId"];
    }
    
    if(([newMessage.messageType isEqualToNumber:[NSNumber numberWithInt:KonotorMessageTypePicture]])||([newMessage.messageType isEqualToNumber:[NSNumber numberWithInt:KonotorMessageTypePictureV2]])){
        [newMessage setPicHeight:[message valueForKey:@"picHeight"]];
        [newMessage setPicWidth:[message valueForKey:@"picWidth"]];
        [newMessage setPicThumbHeight:[message valueForKey:@"picThumbHeight"]];
        [newMessage setPicThumbWidth:[message valueForKey:@"picThumbWidth"]];
        [newMessage setPicUrl:[message valueForKey:@"picUrl"]];
        [newMessage setPicThumbUrl:[message valueForKey:@"picThumbUrl"]];
        [newMessage setPicCaption:[message valueForKey:@"picCaption"]];
    }
    [[FCDataManager sharedInstance]save];
    [FCMessageUtil markDirty];
    return newMessage;
}

- (BOOL) isMarketingMessage{
    if(([[self marketingId] intValue]<=0)||(![self marketingId]))
        return NO;
    else
        return YES;
}

+(FCMessageUtil *)getWelcomeMessageForChannel:(FCChannels *)channel{
    FCMessageUtil *message = nil;
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"belongsToChannel == %@ AND isWelcomeMessage == 1",channel];
    NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        message = matches.firstObject;
    }
    
    if (matches.count > 1) {
        FDLog(@"Duplicate welcome messages found for a channel");
    }
    
    return message;
}

+(bool) hasUserMessageInContext:(NSManagedObjectContext *)context {
    static BOOL messageExists = NO;
    if(messageExistsDirty){
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"isWelcomeMessage <> 1"];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
        if(!error){
            messageExists =  matches.count > 0;
            messageExistsDirty = NO;
        }
    }
    return messageExists;
}

+(long long) lastMessageTimeInContext:(NSManagedObjectContext *)context {
    static long long lastMessageTime = 0;
    if(messageTimeDirty){
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"isWelcomeMessage <> 1"];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
        if(!error){
            for(FCMessageUtil *message in matches){
                NSNumber *createdMillis = message.createdMillis;
                if( lastMessageTime < [createdMillis longLongValue] ){
                    lastMessageTime = [createdMillis longLongValue];
                }
            }
            messageTimeDirty = NO;
        }
    }
    return lastMessageTime;
}

+(long) daysSinceLastMessageInContext:(NSManagedObjectContext *)context{
    long long lastMessageTime = [FCMessageUtil lastMessageTimeInContext:context];
    return ([[NSDate date] timeIntervalSince1970] - (lastMessageTime/1000))/86400;
}


+(BOOL)hasReplyFragmentsIn:(NSString*)data {
    NSArray<NSDictionary *>* fragments = [self getReplyFragmentsIn:data];
    if (fragments) {
        NSSet<NSNumber *> *validFragments = [[NSSet alloc] initWithArray:@[@(FRESHCHAT_TEMPLATE_FRAGMENT), @(FRESHCHAT_COLLECTION_FRAGMENT)]];
        for(int i=0; i< fragments.count; i++) {
            NSDictionary *fragmentDictionary = fragments[i];
            NSNumber *fragmentType = fragmentDictionary[@"fragmentType"];
            if(fragmentType && [validFragments containsObject:fragmentType]) {
                return true;
            }
        }
    }
    
    return false;
}

+ (NSDictionary *) getInternalMetaForData : (NSString *)data {
    if(data){
        NSError *error;
        NSDictionary *metaDict = [self objectFromStringData:data withError:error];
        if (!error) {
            return metaDict;
        }
    }
    return nil;
}

+(NSArray<NSDictionary *> *)getReplyFragmentsIn:(NSString*)data {
    if (data) {
        NSError *error;
        NSArray<NSDictionary *> *fragments =[self objectFromStringData:data withError:error];
        if (!error) {
            return fragments;
        }
    }
    return nil;
}

+ (id) objectFromStringData : (NSString *)data withError:(NSError *)error {
    NSData *extraJSONData = [data dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:extraJSONData
                                           options:0
                                             error:&error];
}

+ (void) cancelCalendarInviteForMsg : (FCMessageData *)message andConv :(FCConversations *) conv {
    NSDictionary *info = @{@"hasActiveCalInvite" : @NO, @"internalMeta" :[FCStringUtil isNotEmptyString: message.internalMeta] ? message.internalMeta : @""};
    NSDictionary *jsonDict = [FCMessageUtil getInternalMetaForData:message.internalMeta];
    
    NSString *inviteId = [jsonDict valueForKeyPath:@"calendarMessageMeta.calendarInviteId"];
    if([FCStringUtil isNotEmptyString:inviteId]){
        
        FCOutboundEvent *outEvent = [[FCOutboundEvent alloc] initOutboundEvent:FCEventCalendarInviteCancel
                                                                    withParams:@{@(FCPropertyInviteId) : inviteId}];
        [FCEventsHelper postNotificationForEvent:outEvent];
        
        [FCMessages updateCalInviteStatusForId:[jsonDict valueForKeyPath:@"calendarMessageMeta.calendarInviteId"] forChannel:conv.belongsToChannel completionHandler:^{
            [FCMessageHelper uploadNewMsgWithImageData:nil textFeed:@"Cancelled the invite" messageType:FC_CALENDAR_CANCEL_MSG withInfo:info onConversation:conv andChannel:conv.belongsToChannel];
        }];
    }
}

+ (void) sendCalendarInviteForMsg : (FCMessageData *)message withSlotInfo :(NSDictionary*)slotInfo andConv :(FCConversations *) conv {
    NSDictionary *info = [FCMessageUtil getInternalMetaForData:message.internalMeta];
    if ([info count] > 0){
        //update active status flag
        [FCMessages updateCalInviteStatusForId:[info valueForKeyPath:@"calendarMessageMeta.calendarInviteId"] forChannel:conv.belongsToChannel completionHandler:^{
            NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] initWithDictionary:info];
                
                NSMutableDictionary *infoDict = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *extraJsonInfo = [[NSMutableDictionary alloc]init];
                extraJsonInfo[@"endMillis"] = [slotInfo valueForKey:@"endMillis"];
                extraJsonInfo[@"eventProviderType"] = @1;
                extraJsonInfo[@"fragmentType"] = @7;
                extraJsonInfo[@"isPendingCreation"] = @"true";
                extraJsonInfo[@"startMillis"] = [slotInfo valueForKey:@"startMillis"];
                extraJsonInfo[@"userTimeZone"] = [slotInfo valueForKey:@"userTimeZone"];
                infoDict[@"extraJSON"] = extraJsonInfo;
                
                NSMutableDictionary *calendarMeta = [jsonDict mutableCopy];
                
                NSMutableDictionary *innerDict = [jsonDict[@"calendarMessageMeta"] mutableCopy];
                innerDict[@"calendarBookingEmail"] = [FCUserDefaults getStringForKey:FRESHCHAT_DEFAULTS_CALENDAR_INVITE_EMAILID];
                calendarMeta[@"calendarMessageMeta"] = innerDict;
                
                NSMutableDictionary *internalMeta = [[NSMutableDictionary alloc] init];
                internalMeta[@"internalMeta"] = [calendarMeta mutableCopy];
                infoDict[@"internalMeta"] = [FCMessages getJsonStringObjForMessage:internalMeta withKey:@"internalMeta"];// convert to string
            
                [FCMessageHelper uploadNewMsgWithImageData:nil textFeed:@"" messageType:@1 withInfo:infoDict onConversation:conv andChannel:conv.belongsToChannel];
        }];
    }
}

@end


@implementation KonotorMessageData

@end
