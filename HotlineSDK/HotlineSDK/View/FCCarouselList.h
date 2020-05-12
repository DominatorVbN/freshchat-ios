//
//  FCCarouselList.h
//  HotlineSDK
//
//  Created by Sanjith Kanagavel on 02/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "FCCarouselCard.h"
#import "FCTemplateFactory.h"
#import "FCTemplateSection.h"

@interface FCCarouselCardsList : UICollectionView <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
- (instancetype)initWithTemplateFragment:(TemplateFragmentData *)fragmentData  inReplyTo:(NSNumber*)messageID withDelegate:(id<FCTemplateDelegate>) delegate;
@end
