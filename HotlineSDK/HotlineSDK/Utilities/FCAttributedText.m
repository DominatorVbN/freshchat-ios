//
//  HLAttributedText.m
//  HotlineSDK
//
//  Created by user on 01/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCAttributedText.h"
#import "FCTheme.h"

@interface FCAttributedText ()

@property (strong, nonatomic) NSMutableDictionary *data;

@end

@implementation FCAttributedText

+ (instancetype)sharedInstance{
    static FCAttributedText *sharedHLAttributedText = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHLAttributedText = [[self alloc]init];
    });
    return sharedHLAttributedText;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.data = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(NSMutableAttributedString *) getAttributedString:(NSString *)string  {
    return self.data[string];
}

-(NSMutableAttributedString *) addAttributedString:(NSString *)string withFont:(UIFont*) font   {
    NSString *stringCheck = (string == nil) ? @"" : string;
    NSString *HTML = [NSString stringWithFormat:@"<span style=\"font-family:'%@'; font-size:%i\">%@</span>",font.fontName,(int)font.pointSize,stringCheck];
    HTML = [HTML stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>" options:NSLiteralSearch range:NSMakeRange(0, stringCheck.length)];
    
    NSMutableAttributedString *attributedTitleString = [[NSMutableAttributedString alloc] initWithData:[HTML dataUsingEncoding:NSUnicodeStringEncoding]
                                                                                               options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                                                    documentAttributes:nil error:nil];
    if (attributedTitleString && attributedTitleString.length > 0) {
        NSAttributedString *last = [attributedTitleString attributedSubstringFromRange:NSMakeRange(attributedTitleString.length - 1, 1)];
        if ([[last string] isEqualToString:@"\n"]) {
            attributedTitleString = [[attributedTitleString attributedSubstringFromRange:NSMakeRange(0, attributedTitleString.length - 1)] mutableCopy];
        }
    }
    self.data[string] = attributedTitleString;
    return attributedTitleString;
}


@end
