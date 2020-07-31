//
//  FCCarouselItem.h
//  HotlineSDK
//
//  Created by Sanjith Kanagavel on 02/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "FCTheme.h"
#import "FCMessageFragments.h"
#import "FCTemplateFactory.h"
#import "FCTemplateSection.h"

@interface FCCarouselCard : UIView

- (instancetype)initWithTemplateFragmentData:(TemplateFragmentData *)fragmentData isCardSelected:(BOOL)selected inReplyTo:(NSNumber*)messageID withDelegate:(id<FCTemplateDelegate>) delegate;

@property (nonatomic, strong) TemplateFragmentData *templateFragment;

- (void) updateCardData;

@end
