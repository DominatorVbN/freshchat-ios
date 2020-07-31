//
//  FCTemplateSection.m
//  FreshchatSDKTest
//
//  Created by Hemanth Kumar on 24/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCTemplateSection.h"
#import "FCTemplateFactory.h"

@implementation FCTemplateSection

-(id)initWith:(NSDictionary*) dictionaryInfo {
    self = [self init];
    if (self) {
        self.name = [dictionaryInfo objectForKey:@"name"];
        self.fragments = [self setFragment:dictionaryInfo];
    }
    return self;
}

-(NSMutableArray<FragmentData *> *)setFragment:(NSDictionary *)dictionaryInfo {
    NSMutableArray<FragmentData *> *fragmentArray = [[NSMutableArray alloc]init];
    NSArray<NSDictionary *> * fragments = [dictionaryInfo objectForKey:@"fragments"];
    if ([dictionaryInfo objectForKey:@"templateType"]) {
        FragmentData * fragmentData = [[TemplateFragmentData alloc] initWith:dictionaryInfo];
        [fragmentArray addObject: fragmentData];
    } else if (fragments) {
        for (int i=0; i< fragments.count; i++) {
            NSMutableArray<FragmentData *> *fragmentTempArray = [self setFragment:fragments[i]];
            [fragmentArray addObjectsFromArray:fragmentTempArray];
        }
    } else {
        FragmentData * fragmentData = [[FragmentData alloc] initWith:dictionaryInfo];
        [fragmentArray addObject: fragmentData];
    }
    return fragmentArray;
}

-(NSDictionary*)dictionaryValue {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]init];
    if (self.name) {
        dictionary[@"name"] = self.name;
    }
    if (self.fragments && self.fragments.count > 0) {
        NSMutableArray *fragmentArray = [[NSMutableArray alloc]init];
        for (int i= 0;i< self.fragments.count; i++) {
            [fragmentArray addObject:self.fragments[i].dictionaryValue];
        }
        dictionary[@"fragments"] = fragmentArray;
    }
    return dictionary;
}

@end
