//
//  FCCarouselListCell.h
//  HotlineSDK
//
//  Created by Sanjith Kanagavel on 04/05/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//


#import "UIKit/UIKit.h"
#import "FCTemplateFactory.h"
#import "FCTemplateSection.h"

@interface FCCarouselCardsListCell : UICollectionViewCell
@property (nonatomic, strong) TemplateFragmentData * templateFragment;
@property (nonatomic, weak) id<FCTemplateDelegate> carouselDelegate;
@property (nonatomic, strong) NSNumber *replyToMessageID;
- (void) updateView;
@end
