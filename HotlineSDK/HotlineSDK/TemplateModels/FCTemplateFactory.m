//
//  FCTemplateFactory.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 18/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCTemplateFactory.h"
#import "FCConstants.h"
#import "FCDropDownViewModel.h"
#import "FCTemplateDropDownView.h"

@interface FragmentData()
-(void)setValueInDictionary:(NSMutableDictionary *)dictionary forObjectKey:(NSString*)objectKey andDictionaryKey:(NSString *)dictionaryKey;
@end

@implementation FCTemplateFactory
+(UIView<FCOutboundDelegate> *)getTemplateDataSourceFrom:(NSDictionary *)fragment andReplyTo:(NSNumber *)messageID withDelegate:(id<FCTemplateDelegate>) templateDelegate {
    TemplateFragmentData *templateFragment = [FCTemplateFactory getFragmentFrom:fragment];
    if (templateFragment && [templateFragment.templateType isEqualToString:FRESHHCAT_TEMPLATE_DROPDOWN]) {
        FCTemplateDropDownView *dropDownView = [[FCTemplateDropDownView alloc]initWithFrame:CGRectZero];
        FCDropDownViewModel *dropDownModel = [[FCDropDownViewModel alloc]initWithFragment:templateFragment inReplyTo:messageID];
        dropDownView.dropDownViewModel = dropDownModel;
        dropDownView.delegate = templateDelegate;
        return dropDownView;
    } 
    return nil;
}

+(TemplateFragmentData *) getFragmentFrom:(NSDictionary *)fragment {
    TemplateFragmentData *templateFragment;
    if (fragment && fragment[@"fragmentType"] && [fragment[@"fragmentType"] integerValue] == FRESHCHAT_TEMPLATE_FRAGMENT) {
    templateFragment = [[TemplateFragmentData alloc]initWith:fragment];
    }
    return templateFragment;
}
@end

@implementation TemplateFragmentData

-(id)initWith:(NSDictionary *)fragmentDictionary {
    self = [super initWith:fragmentDictionary];
    if (self && fragmentDictionary) {
        self.templateType = [fragmentDictionary objectForKey:@"templateType"];
        NSArray<NSDictionary *> * sectionArray = [fragmentDictionary objectForKey:@"sections"];
        self.section = [[NSArray alloc]init];
        if (sectionArray) {
            NSMutableArray<FCTemplateSection*>* sectionTempArray = [[NSMutableArray alloc]init];
            for (int i=0; i< sectionArray.count; i++) {
                FCTemplateSection *section = [[FCTemplateSection alloc] initWith:sectionArray[i]];
                [sectionTempArray addObject: section];
            }
            self.section = sectionTempArray;
        }
        
        NSMutableDictionary *fragmentInfo = [fragmentDictionary mutableCopy];
        
        [fragmentInfo removeObjectsForKeys:@[@"content",
                                             @"contentType",
                                             @"fragmentType",
                                             @"position",
                                             @"sections",
                                             @"templateType"]];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fragmentInfo
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        NSString *jsonString = @"";
        if (jsonData) {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
        }
        self.extraJSON = jsonString;
    }
    return self;
}

- (BOOL)hasReplyFragment {
    return true;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dictionary = [[super dictionaryValue] mutableCopy];
    [self setValueInDictionary:dictionary forObjectKey:@"templateType" andDictionaryKey:@"templateType"];
    if (self.section && self.section.count > 0) {
        NSMutableArray *sectionArray = [[NSMutableArray alloc]init];
        for(int i=0; i< self.section.count; i++) {
            [sectionArray addObject: self.section[i].dictionaryValue];
        }
        dictionary[@"sections"] = sectionArray;
    }
    
    return dictionary;
}

@end
