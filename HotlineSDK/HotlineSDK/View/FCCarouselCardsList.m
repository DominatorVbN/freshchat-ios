//
//  FCCarouselList.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 02/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCarouselCardsList.h"
#import "FCCarouselCardsListCell.h"
#import "FCLocalization.h"


@interface FCCarouselCardsList()
@property (nonatomic,strong) NSArray<TemplateFragmentData*> *templateFragmentDataArr;
@end

@implementation FCCarouselCardsList

TemplateFragmentData *templateFragmentData;
NSNumber *replyToMsgID;
__weak id<FCTemplateDelegate> carouselDelegate;

- (instancetype)initWithTemplateFragment:(TemplateFragmentData *)fragmentData  inReplyTo:(NSNumber*)messageID withDelegate:(id<FCTemplateDelegate>) delegate
{
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    self = [super initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    if (self) {
        templateFragmentData = fragmentData;
        carouselDelegate = delegate;
        replyToMsgID = messageID;
        [self setBaseView];
    }
    return self;
}

-(void) setBaseView {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = UIColor.clearColor;
    [self setShowsHorizontalScrollIndicator:NO];
    [self setShowsVerticalScrollIndicator:NO];
    self.delegate = self;
    self.dataSource = self;
    [self loadCards];
    [self registerClass:[FCCarouselCardsListCell class] forCellWithReuseIdentifier:@"Carousel_Cell"];
}

-(void) loadCards {
    if(templateFragmentData) {
        for (int i=0;i < templateFragmentData.section.count; i++){
            FCTemplateSection *section = templateFragmentData.section[i];
            if([section.name isEqualToString:@"cards"]) {
                self.templateFragmentDataArr = (NSArray<TemplateFragmentData*>*) section.fragments;
            }
        }
    }
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return (self.templateFragmentDataArr) ? self.templateFragmentDataArr.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FCCarouselCardsListCell *cell = [self dequeueReusableCellWithReuseIdentifier:@"Carousel_Cell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[FCCarouselCardsListCell alloc] initWithFrame:CGRectZero];
    }
    cell.carouselDelegate = carouselDelegate;
    cell.replyToMessageID = replyToMsgID;
    cell.templateFragment = self.templateFragmentDataArr[indexPath.row];
    [cell updateView];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(212, self.frame.size.height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

-(CGFloat) getCarousalListMaxHeight {
    CGFloat max = 232.0f;
    for (int i=0; i<templateFragmentData.section.count;i++) {
        FCTemplateSection *carouselSection = templateFragmentData.section[i];
        if ([carouselSection.name isEqualToString:@"cards"]) {
            for (int j=0; j<carouselSection.fragments.count;j++) {
                CGFloat cardHeight = 232.0f;
                BOOL hasBiggerButton = false, hasViewButton = false;
                CGFloat buttonHeight = 0.0f;
                TemplateFragmentData *cardFragment = (TemplateFragmentData *) carouselSection.fragments[j];
                for (int k=0; k<cardFragment.section.count;k++) {
                    FCTemplateSection *cardSection = cardFragment.section[k];
                    NSString *label = @"";
                    if([cardSection.name isEqual:@"title"] || [cardSection.name isEqual:@"description"]) {
                        if(cardSection.fragments.firstObject && cardSection.fragments.firstObject.content != nil && trimString(cardSection.fragments.firstObject.content).length > 0 ) {
                            label = trimString(cardSection.fragments.firstObject.content);
                        }
                        if (label.length > 0) {
                            UILabel *custLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 192.0f, MAXFLOAT)];
                            custLabel.text = label;
                            custLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                            custLabel.font = [cardSection.name isEqual:@"title"] ? [[FCTheme sharedInstance] getCarouselTitleFont] : [[FCTheme sharedInstance] getCarouselDescriptionFont];
                            custLabel.numberOfLines = [cardSection.name isEqual:@"title"] ? 1 : 2;
                            [custLabel sizeToFit];
                            cardHeight += custLabel.frame.size.height + 10.0f;
                        }
                    } else if([cardSection.name isEqual:@"view"] || [cardSection.name isEqual:@"callback"]) {
                        if(cardSection.fragments.firstObject && cardSection.fragments.firstObject.extraJSON.dictionaryValue[@"label"] != nil &&
                           trimString(cardSection.fragments.firstObject.extraJSON.dictionaryValue[@"label"]).length > 0) {
                            label = ((NSString *)trimString(cardSection.fragments.firstObject.extraJSON.dictionaryValue[@"label"]));
                        } else {
                            label =  ([carouselSection.name isEqual:@"view"] ? HLLocalizedString(LOC_DEFAULT_CAROUSEL_CARD_VIEW_BTN) : HLLocalizedString(LOC_DEFAULT_CAROUSEL_CARD_SELECT_BTN));
                        }
                        
                        if ([cardSection.name isEqual:@"callback"]) {
                            UIButton *cardViewBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 192.0f, MAXFLOAT)];
                            [cardViewBtn setTitle:label forState:UIControlStateNormal];
                            cardViewBtn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                            cardViewBtn.titleLabel.font = [[FCTheme sharedInstance] getCarouselActionButtonFont];
                            [cardViewBtn sizeToFit];
                            buttonHeight = cardViewBtn.frame.size.height + 10.0f;
                            cardHeight += buttonHeight;
                        } else {
                            hasViewButton = true;
                        }
                        
                        if (label.length > 7) {
                            hasBiggerButton = true;
                        }
                    }
                }
                if (hasBiggerButton && hasViewButton) {
                    cardHeight += buttonHeight;
                }
                if (cardHeight > max) {
                    max = cardHeight;
                }
            }
            return max;
        }
    }
    return max;
}

@end
