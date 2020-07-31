
//
//  Konotor.m
//  Konotor
//
//  Created by Vignesh G on 04/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "FCMessageHelper.h"
#import "FCDataManager.h"
#import "FCAudioRecorder.h"
#import "FCAudioPlayer.h"
#import "FCMacros.h"
#import "FCMessageServices.h"
#import "FCUtilities.h"
#import "FCSecureStore.h"
#import <ImageIO/ImageIO.h>
#import "FCUserUtil.h"
#import "FCUserdefaults.h"
#import "FCMessages.h"
#import "FCJWTUtilities.h"
#import "FCLocalNotification.h"
#import "FCRemoteConfig.h"
#import "FCJWTAuthValidator.h"
#import "FCEventsHelper.h"

#define KONOTOR_IMG_COMPRESSION YES

@implementation FCMessageHelper

__weak static id <KonotorDelegate> _delegate;

+(id) delegate{
    return _delegate;
}

+(void) setDelegate:(id)delegate{
    _delegate = delegate;
}

+(double) getCurrentPlayingAudioTime
{
    return [FCAudioPlayer audioPlayerGetCurrentTime];
}

+(NSString *) stopRecording
{
    return[FCAudioRecorder stopRecording];
}

+(BOOL) isRecording{
    return [FCAudioRecorder isRecording];
}

+(NSString *) stopRecordingOnConversation:(FCConversations*)conversation
{
    return [FCAudioRecorder stopRecordingOnConversation:conversation];
}

+ (NSTimeInterval) getTimeElapsedSinceStartOfRecording
{
    return[FCAudioRecorder getTimeElapsedSinceStartOfRecording];

}

+(BOOL) cancelRecording
{
    return[FCAudioRecorder cancelRecording];

}

+(void) uploadVoiceRecordingWithMessageID: (NSString *)MessageID toConversationID: (NSString *)ConversationID onChannel:(FCChannels*)channel{
    [FCAudioRecorder SendRecordingWithMessageID:MessageID toConversationID:ConversationID onChannel:channel];
    [[FCMessageHelper delegate] didStartUploadingNewMessage];
}

+(BOOL) StopPlayback{
    return [FCAudioPlayer StopMessage];
}

+(NSString *)getCurrentPlayingMessageID{
    return [FCAudioPlayer currentPlaying:nil set:NO ];
}

+(void)uploadNewMessage:(NSArray *)fragmentsInfo onConversation:(FCConversations *)conversation withMessageType:(NSNumber *)msgType onChannel:(FCChannels *)channel inReplyTo:(NSNumber*)messageId{
    FCMessages *message = [FCMessages saveMessageInCoreData:fragmentsInfo forMessageType:msgType  withInfo :@{} onConversation:conversation inReplyTo:messageId];
    [channel addMessagesObject:message];
    [[FCDataManager sharedInstance]save];
    [FCMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];    
    [[FCMessageHelper delegate] didStartUploadingNewMessage];
    [self postOutBoundEventsForChannel:channel onConversation:conversation];
}

+(void)uploadNewMsgWithImageData:(NSData*)imageData textFeed:(NSString *)caption messageType:(NSNumber *)msgType withInfo:(NSDictionary *)info onConversation:(FCConversations *)conversation andChannel:(FCChannels *)channel{
    //Upload the image with caption first then upload the message
    NSMutableArray *fragmentsInfo = [[NSMutableArray alloc] init];
    UIImage *image = [UIImage imageWithData:imageData];
    if(imageData){
        NSData *thumbnailData;
        float imageWidth,imageHeight,imageThumbHeight,imageThumbWidth;
        
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
        
#if KONOTOR_IMG_COMPRESSION
        UIImage *imgCompressed = [[UIImage alloc] initWithCGImage:compressedImage];
#endif
        
        thumbnailData = UIImageJPEGRepresentation(imgthumb,0.5);
        
#if KONOTOR_IMG_COMPRESSION
        imageData=UIImageJPEGRepresentation(imgCompressed, 0.5);
        imageWidth = imgCompressed.size.width;
        imageHeight = imgCompressed.size.height;
#else
        imageWidth = image.size.width;
        imageHeight = image.size.height;
#endif
        imageThumbHeight = imgthumb.size.height;
        imageThumbWidth = imgthumb.size.width;
        
        CFRelease(src);
        CFRelease(thumbnail);
        NSString *contentType = [FCUtilities contentTypeForImageData:imageData];
        NSDictionary *thumbnailInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       contentType,@"contentType",
                                       @"",@"content",
                                       [NSNumber numberWithFloat:imageThumbWidth],@"width",
                                       [NSNumber numberWithFloat:imageThumbHeight],@"height",
                                       nil];
        
        NSDictionary *imageFragmentInfo = [[NSDictionary alloc] initWithObjectsAndKeys:  @2, @"fragmentType",
                                           contentType,@"contentType",
                                           @"",@"content", //Populate with empty url
                                           [NSNumber numberWithFloat:imageWidth],@"width",
                                           [NSNumber numberWithFloat:imageHeight],@"height",
                                           imageData, @"binaryData1",
                                           thumbnailData, @"binaryData2",
                                           @0,@"position",
                                           thumbnailInfo, @"thumbnail",nil];
        
        [fragmentsInfo addObject: imageFragmentInfo];
    }
    
    if(![caption isEqualToString:@""]) {
        NSDictionary *textFragmentInfo = [[NSDictionary alloc] initWithObjectsAndKeys:  @1, @"fragmentType",
                                          @"text/html",@"contentType",
                                          caption,@"content",
                                          (image != nil) ? @1 : @0 ,@"position",nil];
        [fragmentsInfo addObject:textFragmentInfo];
    }else if(([info count] > 0) && !(imageData)){
        NSDictionary *calFragmentInfo = [[NSDictionary alloc] initWithObjectsAndKeys:  @7, @"fragmentType",
                                         [FCMessages getJsonStringObjForMessage:info withKey:@"extraJSON"], @"extraJSON",
                                         nil];
        [fragmentsInfo addObject:calFragmentInfo];
    }
    
    FCMessages *message = [FCMessages saveMessageInCoreData:fragmentsInfo forMessageType:msgType withInfo:info onConversation:conversation inReplyTo:nil];
    [channel addMessagesObject:message];
    [[FCDataManager sharedInstance]save];
    
    //Check for JWT Auth and expiry
    if([FCRemoteConfig sharedInstance].isUserAuthEnabled && [FCJWTUtilities isValidityExpiedForJWTToken:[FreshchatUser sharedInstance].jwtToken]){
        [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_EXPIRED];
        return;
    }
    
    if(![FCUserUtil isUserRegistered]) {
        [FCUserUtil registerUser:nil];
    } else {
        [self uploadMessage:message withImageData:imageData inChannel:channel andConversation:conversation];
    }
}

+ (void) uploadMessage :(FCMessages *) message withImageData:(NSData*)imageData inChannel:(FCChannels *) channel andConversation : (FCConversations *)conversation {
    [FCMessageHelper performSelector:@selector(UploadFinishedNotification:) withObject:message.messageAlias];
    if(imageData){
        [FCMessageServices uploadPictureMessage:message toConversation:conversation withCompletion:^{
            [FCMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];
            [[FCMessageHelper delegate] didStartUploadingNewMessage];
        }];
    }
    else{
        [FCMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];
        [[FCMessageHelper delegate] didStartUploadingNewMessage];
    }
}
    
+(void) uploadMessageWithImageData:(NSData *)imageData textFeed:(NSString *)textFeedback messageType:(NSNumber *)msgType onConversation:(FCConversations *)conversation andChannel:(FCChannels *)channel{
    [FCUserUtil setUserMessageInitiated];
    NSArray *freshchatRegexArray = [FCUserDefaults getObjectForKey:FRESTCHAT_DEFAULTS_MESSAGE_MASK];
    textFeedback = freshchatRegexArray.count > 0 ? [FCUtilities applyRegexForInputText:textFeedback] : textFeedback;
    [self uploadNewMsgWithImageData:imageData textFeed:textFeedback messageType:msgType withInfo : @{} onConversation:conversation andChannel:channel];
    [self postOutBoundEventsForChannel:channel onConversation:conversation];
}

+(void) postOutBoundEventsForChannel:(FCChannels *)channel onConversation:(FCConversations *)conversation {
    NSMutableDictionary *eventsDict = [[NSMutableDictionary alloc] init];
    if(channel.channelAlias){
        [eventsDict setObject:channel.channelAlias forKey:@(FCPropertyChannelID)];
    }
    [eventsDict setObject:channel.name forKey:@(FCPropertyChannelName)];
    if(conversation){
        [eventsDict setObject:conversation.conversationAlias forKey:@(FCPropertyConversationID)];
    }
    FCOutboundEvent *outEvent = [[FCOutboundEvent alloc] initOutboundEvent:FCEventMessageSent
                                                               withParams:eventsDict];
    [FCEventsHelper postNotificationForEvent:outEvent];
}

+(void)uploadImage:(UIImage *)image onConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    [self uploadImage:image withCaption:nil onConversation:conversation onChannel:channel];
}

+(void) uploadImage:(UIImage *)image withCaption:(NSString *)caption onConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    
    FCMessageUtil *message = [FCMessageUtil savePictureMessageInCoreData:image withCaption:caption onConversation:conversation];
    [channel addMessagesObject:message];
    [FCMessageServices uploadMessage:message toConversation:conversation onChannel:channel];
    [[FCMessageHelper delegate] didStartUploadingNewMessage];
}

+ (long long) getResolvedConvsHideTimeForChannel : (NSNumber *)channelID {
    
    FCChannels *channel = [FCChannels getWithID:channelID inContext:[FCDataManager sharedInstance].mainObjectContext];
    NSSortDescriptor *sortDesc =[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:NO];
    
    NSArray *allMessages = channel.messages.allObjects;
    
    NSArray *sortedMsgsArray = [allMessages sortedArrayUsingDescriptors:@[sortDesc]];
    
    long rcHideAfterMillis = [FCRemoteConfig sharedInstance].conversationConfig.hideResolvedConversationMillis;
    
    NSArray <FCMessages *> * resolvedAndReopenedMsgs = [FCMessageHelper getStatusMsgs:sortedMsgsArray];
    
    if(resolvedAndReopenedMsgs.count > 0){
        //check if last msg is resolved type then get difference b/w current time resolved time
        if (([[FCUtilities getResolvedMsgTypes] containsObject:resolvedAndReopenedMsgs.firstObject.messageType]) && ([FCUtilities getCurrentTimeInMillis] - [resolvedAndReopenedMsgs.firstObject.createdMillis longLongValue] > rcHideAfterMillis)){
            return [resolvedAndReopenedMsgs.firstObject.createdMillis longLongValue];
        }
        for (int i=0; i<resolvedAndReopenedMsgs.count; i++) {
            if (i+1 < resolvedAndReopenedMsgs.count) {
                //check for reopened - resolve and compare the time interval with remote config
                if (([[FCUtilities getReopenedMsgTypes] containsObject:resolvedAndReopenedMsgs[i].messageType]) && ([resolvedAndReopenedMsgs[i].createdMillis longLongValue] - [resolvedAndReopenedMsgs[i+1].createdMillis longLongValue]) > rcHideAfterMillis){
                    return [resolvedAndReopenedMsgs[i+1].createdMillis longLongValue];
                }
            }
        }
    }
    return 0;
}

+ (NSArray *) getUserAndAgentMsgs: (NSArray *) allMessages{
    //Added to avoid disply empty staus messages if remote config fails
    // is added if any chance for old message(s) type value is 0
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(messageType < 1000) OR (messageType == 9001 OR messageType == 9002 OR messageType == 9003 OR messageType == 9004)"];
    return [allMessages filteredArrayUsingPredicate:predicate];
}

+ (NSArray *) getStatusMsgs: (NSArray *) allMessages{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(messageType IN %@)", [FCUtilities getResolvedReopenedMsgTypes]];
    return [allMessages filteredArrayUsingPredicate:predicate];
}

+(BOOL) playMessageWithMessageID:(NSString *) messageID
{
    return [FCAudioPlayer playMessageWithMessageID:messageID];
    
}

+(BOOL) playMessageWithMessageID:(NSString *) messageID atTime:(double)time
{
    return [FCAudioPlayer PlayMessage:messageID atTime:time];
    
}

+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId
{
    return [FCMessageUtil setBinaryImage:imageData forMessageId:messageId];
}
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId
{
    return [FCMessageUtil setBinaryImageThumbnail:imageData forMessageId:messageId];
}

+(BOOL)isUserMe:(NSString *)userId{
    NSString *currentUserID = [USER_TYPE_MOBILE stringValue];
    if(currentUserID){
        if([userId isEqualToString:currentUserID]){
            return YES;
        }
    }
    return NO;
}

+(BOOL)isCurrentUser:(NSNumber *)userId{
    return [userId  isEqual: USER_TYPE_MOBILE];
}

+(void) conversationsDownloaded
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didFinishDownloadingMessages) ])
        {
            [[FCMessageHelper delegate] didFinishDownloadingMessages];
        }
    }
}

+(void)UploadFinishedNotification: (NSString *) messageID{
    if([FCMessageHelper delegate]){
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didFinishUploading:) ]){
            [[FCMessageHelper delegate] didFinishUploading:messageID];
        }
    }
}

+(void)UploadFailedNotification: (NSString *) messageID
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didEncounterErrorWhileUploading:) ])
        {
            [[FCMessageHelper delegate] didEncounterErrorWhileUploading:messageID];
        }
    }
}

+(void)NotifyServerError
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didNotifyServerError)])
        {
            [[FCMessageHelper delegate] didNotifyServerError];
        }
    }
}

+(void) MediaDownloadFailedNotification:(NSString *) messageID
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didEncounterErrorWhileDownloading:) ])
        {
            [[FCMessageHelper delegate] didEncounterErrorWhileDownloading:messageID];
        }
    }
}

+(void) conversationsDownloadFailed
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didEncounterErrorWhileDownloadingConversations)])
        {
            [[FCMessageHelper delegate] didEncounterErrorWhileDownloadingConversations];
        }
    }
}
@end
