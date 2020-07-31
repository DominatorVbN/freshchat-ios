//
//  FCDropDownViewModel.h
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 24/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCTemplateFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCDropDownModel: NSObject
-(id)initWithLabel:(NSString *)label andContent:(NSDictionary *)content;
@property(nonatomic, strong, retain) NSString *label;
@property(nonatomic, strong, retain) NSDictionary *fragmentContent;
@end

@interface FCDropDownViewModel : NSObject
-(id)initWithFragment:(TemplateFragmentData *)templateFragment inReplyTo:(NSNumber*)messageID;
@property(nonatomic, strong, retain) NSArray<FCDropDownModel *>* options;
@property(nonatomic, strong, retain) NSNumber * replyMessageId;
@end


NS_ASSUME_NONNULL_END
