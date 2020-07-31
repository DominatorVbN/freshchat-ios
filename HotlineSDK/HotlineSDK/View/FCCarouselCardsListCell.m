//
//  FCCarouselListCell.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 04/05/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCCarouselCardsListCell.h"
#import "FCCarouselCard.h"

@interface FCCarouselCardsListCell()
@property (nonatomic, strong) FCCarouselCard * carouselView;
@end

@implementation FCCarouselCardsListCell

- (void) updateView {
    if(self.carouselView) {
        [self.carouselView removeFromSuperview];
    }
    self.carouselView = [[FCCarouselCard alloc] initWithTemplateFragmentData:self.templateFragment isCardSelected:NO inReplyTo:self.replyToMessageID withDelegate:self.carouselDelegate];
    self.carouselView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.carouselView];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view" : self.carouselView}]];
    NSString *verticalConstraint = @"V:|[view]";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalConstraint options:0 metrics:nil views:@{@"view" : self.carouselView}]];
}

@end
