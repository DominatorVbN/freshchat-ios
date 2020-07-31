//
//  FCTemplateSection.h
//  FreshchatSDKTest
//
//  Created by Hemanth Kumar on 24/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCMessageFragments.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCTemplateSection : NSObject
-(id)initWith:(NSDictionary*) dictioanryInfo;
@property(nonatomic, retain, strong) NSString *name;
@property(nonatomic, retain, strong) NSArray<FragmentData *> *fragments;
-(NSDictionary*)dictionaryValue;
@end

NS_ASSUME_NONNULL_END
