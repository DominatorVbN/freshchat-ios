//
//  FCDropDownViewModel.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 24/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCDropDownViewModel.h"

@implementation FCDropDownModel

- (id)initWithLabel:(NSString *)label andContent:(nonnull NSDictionary *)content {
    self = [self init];
    if(self) {
        self.label = label;
        self.fragmentContent = content;
    }
    return self;
}

@end

@implementation FCDropDownViewModel

-(id)initWithFragment:(TemplateFragmentData *)templateFragment inReplyTo:(nonnull NSNumber *)messageID {
    self = [self init];
    if (self) {
        self.replyMessageId = messageID;
        NSMutableArray *options = [[NSMutableArray alloc]init];
        FCTemplateSection *section = templateFragment.section.firstObject;
        if (section) {
            for (int i=0; i < section.fragments.count; i++) {
                FragmentData *fragment = section.fragments[i];
                NSDictionary *jsonDict = fragment.dictionaryValue;
                NSString *label = [jsonDict objectForKey:@"label"];
                if(!label || trimString(label).length == 0) {
                    label = [jsonDict objectForKey:@"customReplyText"] != nil ? [jsonDict objectForKey:@"customReplyText"] : @"";
                }
                label = trimString(label);
                if (label.length > 0) {
                    FCDropDownModel *dropDown = [[FCDropDownModel alloc] initWithLabel:label andContent:jsonDict];
                    [options addObject:dropDown];
                }
            }
        }
        self.options = options;
    }
    
    return self;
}

@end
