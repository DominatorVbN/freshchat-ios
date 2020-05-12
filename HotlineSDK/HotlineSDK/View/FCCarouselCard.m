//
//  FCCarouselItem.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 02/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCarouselCard.h"
#import "FDWebImageManager.h"
#import "FCLocalization.h"
#import "FCConstants.h"
#import "FCOutboundEvent.h"
#import "FCEventsHelper.h"
#import "FCAnimatedImageView.h"

@interface FCCarouselCard()
@property (nonatomic, weak) id<FCTemplateDelegate> carouselDelegate;
@property (nonatomic,strong) FCAnimatedImageView *cardImageView;
@property (nonatomic,strong) UILabel *cardTitleLable;
@property (nonatomic,strong) UITextView *cardDescTxtView;
@property (nonatomic,strong) UIButton *cardSelectBtn;
@property (nonatomic,strong) UIButton *cardViewBtn;
@property (nonatomic,strong) UILabel *selectedLbl;
@property (nonatomic) BOOL isCardSelected;
@property (nonatomic, strong) NSString *imgUrl,*titleText,*descText,*callbackData,*viewData, *callbackText, *viewText;
@end

@implementation FCCarouselCard

NSNumber *replyToMsgId;

- (instancetype)initWithTemplateFragmentData:(TemplateFragmentData *)fragmentData isCardSelected:(BOOL)selected inReplyTo:(NSNumber*)messageID withDelegate:(id<FCTemplateDelegate>) delegate {
    self = [super init];
    if (self) {
        self.carouselDelegate = delegate;
        self.templateFragment = fragmentData;
        self.isCardSelected = selected;
        replyToMsgId = messageID;
        self.viewText = @"";
        [self updateCardData];
        [self setSubviews];
    }
    return self;
}

-(void) updateCardData {
    if (self.templateFragment) {
         for (int i=0; i<self.templateFragment.section.count;i++) {
            FCTemplateSection *carouselSection = self.templateFragment.section[i];
             FragmentData *carouselFragment = carouselSection.fragments[0];
            if([carouselSection.name isEqual:@"hero_image"]) {
                self.imgUrl = carouselFragment.content;
            }
            else if([carouselSection.name isEqual:@"title"]) {
                self.titleText = carouselFragment.content;
            }
            else if([carouselSection.name isEqual:@"description"]) {
                self.descText = carouselFragment.content;
            }
            else if([carouselSection.name isEqual:@"view"]) {
                self.viewData = carouselFragment.content;
                if(carouselFragment.extraJSON.dictionaryValue[@"label"] != nil && trimString(carouselFragment.extraJSON.dictionaryValue[@"label"]).length > 0) {
                    self.viewText = carouselFragment.extraJSON.dictionaryValue[@"label"];
                } else {
                    self.viewText = HLLocalizedString(LOC_DEFAULT_CAROUSEL_CARD_VIEW_BTN);
                }
            }
            else if([carouselSection.name isEqual:@"callback"]) {
                self.callbackData = carouselFragment.extraJSON.dictionaryValue[@"payload"];
                if(carouselFragment.extraJSON.dictionaryValue[@"label"] != nil && trimString(carouselFragment.extraJSON.dictionaryValue[@"label"]).length > 0) {
                    self.callbackText = carouselFragment.extraJSON.dictionaryValue[@"label"];
                } else {
                    self.callbackText = HLLocalizedString(LOC_DEFAULT_CAROUSEL_CARD_SELECT_BTN);
                }
            }            
        }
    }
}

-(void) setSubviews {
    FCTheme *theme = [FCTheme sharedInstance];
    self.selectedLbl = [[UILabel alloc] init];
    self.selectedLbl.numberOfLines = 1;
    self.cardImageView = [[FCAnimatedImageView alloc] init];
    [self.cardImageView setContentMode: UIViewContentModeScaleAspectFill];
    self.cardImageView.clipsToBounds = true;
    self.cardTitleLable = [[UILabel alloc] init];
    self.cardDescTxtView = [[UITextView alloc] init];
    self.cardDescTxtView.textContainer.maximumNumberOfLines = 2;
    self.cardDescTxtView.scrollEnabled = NO;
    self.cardSelectBtn = [[UIButton alloc] init];
    self.cardSelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.cardViewBtn = [[UIButton alloc] init];
    self.cardViewBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.selectedLbl.textColor = UIColor.grayColor;
    self.selectedLbl.text = HLLocalizedString(LOC_CAROUSEL_CARD_SELECTED_TEXT);
    self.selectedLbl.textAlignment = NSTextAlignmentCenter;
    self.cardImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CAROUSEL_PLACEHOLDER_IMAGE];
    [self loadImage];
    self.cardTitleLable.backgroundColor = UIColor.clearColor;
    self.cardDescTxtView.backgroundColor = UIColor.clearColor;
    self.cardTitleLable.text = self.titleText;
    self.cardDescTxtView.text = self.descText;
    self.cardDescTxtView.editable = NO;
    self.cardDescTxtView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.cardSelectBtn setTitle:self.callbackText forState:UIControlStateNormal];
    [self.cardViewBtn setTitle:self.viewText forState:UIControlStateNormal];
    self.cardDescTxtView.textContainer.lineFragmentPadding = 2;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardTitleLable.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardDescTxtView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardSelectBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardViewBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardViewBtn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.cardSelectBtn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.selectedLbl.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.selectedLbl setHidden:!self.isCardSelected];
    [self.cardViewBtn setHidden:self.isCardSelected];
    [self.cardSelectBtn setHidden:self.isCardSelected];
    
    self.cardTitleLable.font = [theme getCarouselTitleFont];
    self.cardDescTxtView.font = [theme getCarouselDescriptionFont];
    self.selectedLbl.font = [theme getCarouselSelectedTextFont];
    self.cardSelectBtn.titleLabel.font = [theme getCarouselActionButtonFont];
    self.cardViewBtn.titleLabel.font = [theme getCarouselActionButtonFont];
    
    self.cardTitleLable.textColor = [theme getCarouselTitleColor];
    self.cardDescTxtView.textColor = [theme getCarouselDescriptionColor];
    self.selectedLbl.textColor = [theme getCarouselSelectedTextColor];
    UIColor *buttonColor = [theme getCarouselActionButtonColor];
    [self.cardSelectBtn setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.cardViewBtn setTitleColor:buttonColor forState:UIControlStateNormal];
    
    if(!self.isCardSelected) {
        self.backgroundColor = UIColor.whiteColor;
    } else {
        self.backgroundColor = [theme getCarouselSelectedCardBackground];
    }
    
    self.layer.cornerRadius = 4;
    self.clipsToBounds = YES;
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = UIColor.lightGrayColor.CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowOpacity = 0.5f;
    
    [self.cardSelectBtn addTarget:self action:@selector(selectAction) forControlEvents:UIControlEventTouchUpInside];
    [self.cardViewBtn addTarget:self action:@selector(viewAction) forControlEvents:UIControlEventTouchUpInside];
    
    NSDictionary *views = @{
        @"image" : self.cardImageView,
        @"title" : self.cardTitleLable,
        @"desc" : self.cardDescTxtView,
        @"select" : self.cardSelectBtn,
        @"view" : self.cardViewBtn,
        @"selectedLbl" : self.selectedLbl
    };
    [self addSubview:self.cardImageView];
    [self addSubview:self.cardDescTxtView];
    [self addSubview:self.cardTitleLable];
    [self addSubview:self.cardSelectBtn];
    
    if(self.isCardSelected) {
        [self addSubview:self.selectedLbl];
    } else {
        if (![FCStringUtil isEmptyString:trimString(_viewText)] ) {
            [self addSubview:self.cardViewBtn];
        }
        [self addSubview:self.cardSelectBtn];
    }
    
    BOOL shouldPlaceBelow = self.callbackText.length > 7 || self.viewText.length > 7;
    NSDictionary *metrics = @{ @"leadTrailPadding" : @10, @"interElementPadding" :@7, @"imgSize" : @212, @"buttonSpacing" : @30, @"buttonLeadTrail" : @15 };
    NSString *verticalConstraint, *horizontalConstraint;
    NSString *titleConstraint = [FCStringUtil isEmptyString:trimString(_titleText)] ? @"" : @"-interElementPadding-[title]";
    NSString *descConstraint = [FCStringUtil isEmptyString:trimString(_descText)] ? @"" : @"-interElementPadding-[desc(>=0)]";
    NSString *viewBtnConstraint = [FCStringUtil isEmptyString:trimString(_viewText)] ? @"|" : @"[view]";
    if(!self.isCardSelected) {
        if (!shouldPlaceBelow) {
            verticalConstraint = [NSString stringWithFormat:@"V:|[image(imgSize@999)]%@%@-interElementPadding-[select]-leadTrailPadding-|",titleConstraint,descConstraint ] ;
            horizontalConstraint = [NSString stringWithFormat:@"H:|-buttonLeadTrail-[select]-buttonSpacing-%@|",(viewBtnConstraint.length > 1 ? @"[view]->=buttonLeadTrail-" : @"")];
        } else {
            verticalConstraint = [NSString stringWithFormat:@"V:|[image(imgSize@999)]%@%@-interElementPadding-[select]-leadTrailPadding-%@",titleConstraint,descConstraint,viewBtnConstraint] ;
            horizontalConstraint = @"H:|-buttonLeadTrail-[select]-buttonLeadTrail-|";
            if (viewBtnConstraint.length > 1) {
                [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-buttonLeadTrail-[view]-buttonLeadTrail-|" options:0 metrics:metrics views:views]];
            }
        }
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalConstraint options:0 metrics:metrics views:views]];
        if (viewBtnConstraint.length > 1){
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view]-leadTrailPadding-|" options:0 metrics:metrics views:views]];
        }
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontalConstraint options:0 metrics:metrics views:views]];
    } else {
        verticalConstraint = [NSString stringWithFormat:@"V:|[image(imgSize@999)]%@%@-interElementPadding@999-[selectedLbl]-leadTrailPadding-|",titleConstraint,descConstraint ] ;
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalConstraint options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=15)-[selectedLbl(==182)]-(>=15)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    }
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[image(imgSize)]|" options:0 metrics:metrics views:views]];
    if (titleConstraint.length > 0) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leadTrailPadding-[title]-leadTrailPadding-|" options:0 metrics:metrics views:views]];
    }
    if (descConstraint.length > 0) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leadTrailPadding-[desc]-leadTrailPadding-|" options:0 metrics:metrics views:views]];
    }
}

-(void) loadImage {
    __block NSString *imageURL = self.imgUrl;
    if(imageURL) {
        self.cardImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CAROUSEL_PLACEHOLDER_IMAGE];
        [FCUtilities loadImageWithUrl:imageURL forView:_cardImageView andErrorImage:[[FCTheme sharedInstance] getImageWithKey:IMAGE_CAROUSEL_ERROR_IMAGE]];
    } else {
        self.cardImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CAROUSEL_ERROR_IMAGE];
    }
}

-(void) selectAction {
    if(_carouselDelegate && self.callbackData) {
        NSArray *fragmentInfo = @[self.templateFragment.dictionaryValue];
        FCOutboundEvent *event = [[FCOutboundEvent alloc] initOutboundEvent:FCEventCarouselSelect
                                                                    withParams:@{@(FCPropertyOption): fragmentInfo}];
        [FCEventsHelper postNotificationForEvent:event];
        [_carouselDelegate dismissAndSendFragment:fragmentInfo inReplyTo:replyToMsgId];
    }
}

-(void) viewAction {
    if(_carouselDelegate && self.viewData) {
        NSArray *fragmentInfo = @[self.templateFragment.dictionaryValue];
        FCOutboundEvent *event = [[FCOutboundEvent alloc] initOutboundEvent:FCEventCarouselView
                                                                    withParams:@{@(FCPropertyOption): fragmentInfo}];
        [FCEventsHelper postNotificationForEvent:event];
        NSURL *url = [[NSURL alloc] initWithString:self.viewData];
        BOOL isHandled = [_carouselDelegate handleLinkDelegate:url];
        if (!isHandled) {
            if([[UIApplication sharedApplication] canOpenURL:url]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:url];
                });
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.cardImageView.bounds byRoundingCorners:(UIRectCornerTopLeft| UIRectCornerTopRight) cornerRadii:CGSizeMake(4, 4)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    
    maskLayer.path = path.CGPath;

    self.cardImageView.layer.mask = maskLayer;
}

@end
