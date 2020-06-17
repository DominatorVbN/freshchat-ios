//
//  FCtemplateFactory.h
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 18/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCMessages.h"
#import "FCTemplateSection.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FCLinkDelegate <NSObject>
- (BOOL)handleLinkDelegate: (NSURL *)url;
@end

@protocol FCTemplateDelegate <FCLinkDelegate>
- (void) dismissAndSendFragment:(NSArray *)fragments inReplyTo:(NSNumber *)messageID;
- (void) updateHeightConstraint:(int) height andShouldScrollTolast:(BOOL) scrollToLast;
@end

@protocol FCOutboundDelegate <NSObject>
- (void) postOutboundEvent;
@end

@interface TemplateFragmentData: FragmentData
-(id)initWith:(NSDictionary *) fragmentDictionary;
@property(nonatomic, retain, strong) NSString *templateType;
@property(nonatomic, retain, strong) NSArray<FCTemplateSection *> *section;
@end

@interface FCTemplateFactory : NSObject
+(nullable UIView<FCOutboundDelegate> *)getTemplateDataSourceFrom:(NSDictionary *)fragment andReplyTo:(NSNumber *)messageID withDelegate:(id<FCTemplateDelegate>) templateDelegate;
+(TemplateFragmentData *) getFragmentFrom:(NSDictionary *)fragment;
@end


NS_ASSUME_NONNULL_END

