//
//  Message.m
//  HotlineSDK
//
//  Created by user on 01/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCMessages.h"
#import "FCLocalization.h"
#import "FCRemoteConfig.h"
#import "FCJWTAuthValidator.h"
#import "FCTemplateFactory.h"
#include "FCConstants.h"

@implementation FCMessages

    @dynamic channelId;
    @dynamic conversationId;
    @dynamic createdMillis;
    @dynamic marketingId;
    @dynamic messageAlias;
    @dynamic messageUserAlias;
    @dynamic messageUserType;
    @dynamic isMarkedForUpload;
    @dynamic isWelcomeMessage;
    @dynamic isRead;
    @dynamic belongsToChannel;
    @dynamic belongsToConversation;
    @dynamic uploadStatus;
    @dynamic isDownloading;
    @dynamic messageType;
    @dynamic replyToMessage;
    @dynamic messageId;
    @dynamic replyFragments;

    static BOOL messageExistsDirty = YES;
    static BOOL messageTimeDirty = YES;


- (void)awakeFromFetch {
    [super awakeFromFetch];
    if (nil == self.messageType) {
        [self willChangeValueForKey:@"messageType"];
        self.messageType = @1;
        [self didChangeValueForKey:@"messageType"];
    }
}

+(NSString *) generateMessageID {
    NSTimeInterval  today = [[NSDate date] timeIntervalSince1970];
    NSString *userAlias = [FCUtilities getUserAliasWithCreate];
    NSString *intervalString = [NSString stringWithFormat:@"%.0f", today*1000];
    NSString *messageID  =[NSString stringWithFormat:@"%@%@%@",userAlias,@"_",intervalString];
    return messageID;
}

+(FCMessages *)saveMessageInCoreData:(NSArray *)fragmentsInfo onConversation:(FCConversations *)conversation inReplyTo:(NSNumber *)messageID{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessages *message = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    [message setMessageAlias:[FCMessages generateMessageID]];
    [message setMessageUserType:USER_TYPE_MOBILE];
    [message setMessageType:@1];
    [message setIsRead:YES];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    message.belongsToConversation = conversation;
    message.isWelcomeMessage = NO;
    message.isMarkedForUpload = YES;
    [message setMessageId:@0];
    [message setReplyToMessage:messageID];
    for(int i=0;i<fragmentsInfo.count;i++) {
        NSDictionary *fragmentInfo = fragmentsInfo[i];
        [FCMessageFragments createUploadFragment:fragmentInfo toMessage:message];
    }
    [datamanager save]; //Saves the fragment and message
    [FCMessages markDirty];
    return message;
}

+(void) markDirty{
    messageExistsDirty = YES;
    messageTimeDirty = YES;
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
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isRead == NO AND belongsToChannel == %@",channel];
        request.predicate = predicate;
        NSArray *messages = [context executeFetchRequest:request error:&pError];
        if (messages.count>0) {
            for(int i=0;i<messages.count;i++){
                FCMessages *message = messages[i];
                if(message){
                    if(![[message marketingId] isEqualToNumber:@0]){
                        [FCMessageServices markMarketingMessageAsRead:message context:context];
                    }else{
                        [message markAsRead];
                    }
                }
            }
            [FCCoreServices sendLatestUserActivity:channel];
            [FCUtilities postUnreadCountNotification];
            [context save:nil];
        }
    }];
}

+(void)uploadAllUnuploadedMessages{
    if([FCJWTUtilities isJWTTokenInvalid]) return;
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isMarkedForUpload == 1 AND uploadStatus == 0"];
        [request setPredicate:predicate];
        NSArray *array = [context executeFetchRequest:request error:&pError];
        NSSortDescriptor* desc=[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
        NSArray *sortedArr = [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
        if([sortedArr count]==0){
            return;
        }else{
            FDLog(@"There are %d unuploaded messages", (int)array.count);
            [FCMessageServices uploadAllUnuploadedMessages:sortedArr index:0];
        }
    }];
}

+(FCMessages *)retriveMessageForMessageId: (NSString *)messageId{

    NSError *pError;
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"messageAlias == %@",messageId];
    [request setPredicate:predicate];
    
    NSArray *array = [context executeFetchRequest:request error:&pError];

    if([array count] >1) {
        FDLog(@"%@", @"Multiple Messages stored with the same message Id");
    }
    
    if([array count] >0) {
        FCMessages *message = [array objectAtIndex:0];
        return message;
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

-(NSString *)getJSON {
    NSMutableDictionary *messageDict = [[NSMutableDictionary alloc]init];
//    [messageDict setObject:[self messageType] forKey:@"messageType"];
//    if([[self messageType] intValue ]== 1)
//        [messageDict setObject:[self text] forKey:@"text"];
//    else if([[self messageType] intValue ]== 2)
//        [messageDict setObject:[self durationInSecs] forKey:@"durationInSecs"];
//    else if([[self messageType] intValue ]== 3)
//    {
//        [messageDict setObject:[self picThumbWidth] forKey:@"picThumbWidth"];
//        [messageDict setObject:[self picThumbHeight] forKey:@"picThumbHeight"];
//        [messageDict setObject:[self picHeight] forKey:@"picHeight"];
//        [messageDict setObject:[self picWidth] forKey:@"picWidth"];
//        
//        if([self picCaption])
//            [messageDict setObject:[self picCaption] forKey:@"picCaption"];
//    }
    NSError *error;
    NSData *pJsonString = [NSJSONSerialization dataWithJSONObject:messageDict options:0 error:&error];
    return [[NSString alloc ]initWithData:pJsonString encoding:NSUTF8StringEncoding];
}

-(void)markAsRead{
    [self setIsRead:YES];
}

-(void)markAsUnread{
    BOOL wasRead = [self isRead];
    if(!wasRead) return
        [self setIsRead:NO];
}

+(FCMessages *)createNewMessage:(NSDictionary *)message toChannelID:(NSNumber *)channelId {
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    FCMessages *newMessage = (FCMessages *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    
    if([message valueForKey:@"alias"]) {
        newMessage.isWelcomeMessage = NO;
        newMessage.messageAlias = [message valueForKey:@"alias"];
        [newMessage setMessageUserType:USER_TYPE_AGENT];
        [newMessage setMessageType:[message valueForKey:@"messageType"]];
        if([message[@"readByUser"] boolValue]) {
            newMessage.isRead = YES;
        } else {
            newMessage.isRead = NO;
        }
    } else {
        newMessage.isWelcomeMessage = YES;
        newMessage.messageAlias = [NSString stringWithFormat:@"%d_welcomemessage",[channelId intValue]];
        newMessage.isRead = YES;
    }
    [newMessage setMessageUserType:[message valueForKey:@"messageUserType"]];
    [newMessage setCreatedMillis:[message valueForKey:@"createdMillis"]];
    [newMessage setMarketingId:[message valueForKey:@"marketingId"]];
    [newMessage setMessageUserAlias:[message valueForKey:@"messageUserAlias"]];
    [newMessage setMessageId:[message valueForKey:@"messageId"]];
    NSString *jsonString = @"";
    if ([message valueForKey:@"replyFragments"]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[message valueForKey:@"replyFragments"]
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        if (jsonData) {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
        }
    }
    [newMessage setReplyFragments:jsonString];
    [FCMessageFragments createFragments:[message valueForKey:@"messageFragments"] toMessage:newMessage];
    [[FCDataManager sharedInstance]save];
    
    [FCMessages markDirty];
    return newMessage;
}

-(FCMessageData *) ReturnMessageDataFromManagedObject{
    FCMessageData *message = [[FCMessageData alloc]init];
    message.createdMillis = [self createdMillis];
    message.messageAlias =[self messageAlias];
    message.isRead = [self isRead];
    message.uploadStatus = [self uploadStatus];
    message.messageUserType = [self messageUserType];
    message.isMarketingMessage = [self isMarketingMessage];
    message.marketingId = self.marketingId;
    message.isWelcomeMessage = self.isWelcomeMessage;
    message.messageUserAlias = self.messageUserAlias;
    message.replyFragments = self.replyFragments;
    message.fragments = [FCMessageFragments getAllFragments:self];
    message.messageId = [self messageId];
    return message;
}


- (BOOL) isMarketingMessage{
    if(([[self marketingId] intValue]<=0)||(![self marketingId]))
        return NO;
    else
        return YES;
}

+(NSArray *)getAllMesssageForChannel:(FCChannels *)channel{
    NSMutableArray *messages = [[NSMutableArray alloc]init];
    NSArray *matches = channel.messages.allObjects;
    NSArray *filteredMessages = [FCMessageHelper getUserAndAgentMsgs:matches];
    BOOL isHideConversationsEnabled = [[FCRemoteConfig sharedInstance].conversationConfig hideResolvedConversation];
        
    for (int i=0; i<filteredMessages.count; i++) {
        FCMessageData *message = [filteredMessages[i] ReturnMessageDataFromManagedObject];
        if (message){
            if(isHideConversationsEnabled){
                long long hideConvResolvedMillis = [FCMessageHelper getResolvedConvsHideTimeForChannel:channel.channelID];
                if(([message.createdMillis longLongValue] > hideConvResolvedMillis) || message.isWelcomeMessage){
                    [messages addObject:message];
                }
            }
            else{
                [messages addObject:message];
            }
        }
    }
    return messages;
}

+(FCMessages *)getWelcomeMessageForChannel:(FCChannels *)channel{
    FCMessages *message = nil;
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

+(void)removeWelcomeMessage:(FCChannels *)channel{
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"belongsToChannel == %@ AND isWelcomeMessage == 1",channel];
    NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
    for (int i=0; i<matches.count; i++) {
        FCMessages *message = matches[i];
        [FCMessages removeFragmentsInMessage:message];
        [context deleteObject:message];
    }   
}

+(void) removeFragmentsInMessage:(FCMessages *) message {
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"message == %@",message];
    NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
    for (int i=0; i<matches.count; i++) {
        FCMessageFragments *fragment = matches[i];
        [context deleteObject:fragment];
    }
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
            for(FCMessages *message in matches){
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
    long long lastMessageTime = [FCMessages lastMessageTimeInContext:context];
    return ([[NSDate date] timeIntervalSince1970] - (lastMessageTime/1000))/86400;
}

-(NSMutableDictionary *) convertMessageToDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    dict[@"messageUserType"] = [self messageUserType];
    dict[@"createdMillis"] = [self createdMillis];
    dict[@"messageFragments"] = [FCMessageFragments getAllFragmentsInDictionary:self];
    return dict;
}

-(NSString *)getDetailDescriptionForMessage {
    NSString *description = @"";
    NSArray *allFragments = [FCMessageFragments getAllFragments:self];
    BOOL hasImage = NO;
    NSString *textLabel = @"";
    BOOL hasQuickReplyFragment = NO;
    for (int i=0; i< allFragments.count; i++) {
        FragmentData *fragment = allFragments[i];
        if([fragment.type isEqualToString:@"2"]) {
            hasImage = YES;
        } else if([fragment.type isEqualToString:@"1"]) {
            textLabel = [self appendString:fragment.content toString: textLabel];
        } else if ([fragment.type isEqualToString: [@(FRESHCHAT_QUICK_REPLY_FRAGMENT) stringValue]]) {
            NSDictionary *dictionaryValue = fragment.dictionaryValue;
            NSString *label = dictionaryValue[@"label"];
            if(!label || trimString(label).length == 0) {
                label = dictionaryValue[@"customReplyText"] != nil ? dictionaryValue[@"customReplyText"] : @"";
            }
            textLabel = [self appendString:trimString(label) toString: textLabel];
        } else if ([fragment.type isEqualToString:@"5"]) {
            NSData *extraJSONData = [fragment.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
            NSString *label = extraJSONDict[@"label"];
            if (!label) {
                label = HLLocalizedString(LOC_DEFAULT_ACTION_BUTTON_TEXT);
            }
            
            if (label) {
                if (textLabel.length > 0) {
                    textLabel = [self appendString:[NSString stringWithFormat:@"🔘 %@", label] toString: textLabel];
                }
            }
        }
    }
    
    if(hasImage) {
        description = [NSString stringWithFormat:@"%@📷", description];
    }
    
    if([FCMessageUtil hasReplyFragmentsIn:self.replyFragments]) {
        hasQuickReplyFragment = YES;
        NSArray<NSDictionary *>* fragments = [FCMessageUtil getReplyFragmentsIn:self.replyFragments];
        if (fragments && fragments.count > 0) {
           TemplateFragmentData *fragmentData = [FCTemplateFactory getFragmentFrom:fragments.firstObject];
            if ([fragmentData.templateType isEqualToString:FRESHHCAT_TEMPLATE_DROPDOWN]) {
                description = [NSString stringWithFormat:@"🔽%@", description];
            }
        }
    }
    
    description = [self appendString:textLabel toString:description];
    
    if(description.length == 0 && !hasQuickReplyFragment) {
        description = @"❗️";
    }
    return [description substringToIndex: MIN(300, [description length])];
}

-(NSString *)appendString:(NSString *) appendString toString:(NSString *) sourceString {
    if (sourceString && appendString && appendString.length > 0) {
        if (sourceString.length > 0) {
            sourceString = [NSString stringWithFormat:@"%@ %@", sourceString, appendString];
        } else {
            sourceString = [NSString stringWithFormat:@"%@", appendString];
        }
    }
    return sourceString;
}

@end


