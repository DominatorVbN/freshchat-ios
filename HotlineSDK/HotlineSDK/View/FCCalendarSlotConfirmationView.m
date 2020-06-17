//
//  FCCalendarSlotConfirmationView.m
//  FreshchatSDK
//
//  Created by Harish kumar on 20/05/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCalendarSlotConfirmationView.h"
#import "FCTheme.h"
#import "FCAutolayoutHelper.h"
#import "FCDateUtil.h"
#import "FCAnimatedImageView.h"
#import "FCParticipants.h"
#import "FCSecureStore.h"
#import "FCUtilities.h"
#import "FCLocalization.h"

#define IMAGE_SIZE 110

@interface FCCalendarSlotConfirmationView()<UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *contentScrollView;
@property (nonatomic, strong) NSDictionary *inviteTimeInfo;
@property (strong, nonatomic) UIView *contentView;

@end

@implementation FCCalendarSlotConfirmationView

-(id) initWithConfirmationData: (NSDictionary *) data {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.inviteTimeInfo = data;
        [self setSubViews];
    }
    return self;
}

- (void) setSubViews {
    
    FCTheme *theme = [FCTheme sharedInstance];
    
    self.contentScrollView = [[UIScrollView alloc]init];
    self.contentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentScrollView.delegate = self;
    self.contentScrollView.backgroundColor = [UIColor clearColor];
    [self.contentScrollView setShowsHorizontalScrollIndicator:NO];
    [self.contentScrollView setShowsVerticalScrollIndicator:YES];
    self.contentScrollView.userInteractionEnabled= YES;
    self.contentScrollView.scrollEnabled = YES;
    self.contentScrollView.contentOffset = CGPointZero;
    self.contentScrollView.bounces = false;
    self.contentScrollView.contentInset = UIEdgeInsetsZero;

    [self addSubview:self.contentScrollView];
    
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.contentScrollView addSubview:self.contentView];
    
    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:content];
    
    UIView *imagesView = [[UIView alloc] init];
    imagesView.translatesAutoresizingMaskIntoConstraints = NO;
    imagesView.backgroundColor = [UIColor clearColor];
    [content addSubview:imagesView];
    
    FCAnimatedImageView *userImageView = [[FCAnimatedImageView alloc] initWithFrame:CGRectZero];
    userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    userImageView.backgroundColor = [UIColor clearColor];
    userImageView.clipsToBounds = YES;
    userImageView.contentMode = UIViewContentModeScaleAspectFill;
    userImageView.layer.cornerRadius = IMAGE_SIZE/2;
    userImageView.layer.borderWidth = 3.0f;
    userImageView.layer.borderColor = [theme getCalendarConfirmAvatarsBorderColor].CGColor;
    userImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CALENDAR_CUSTOMER_AVATAR];
    [imagesView addSubview:userImageView];
    
    FCAnimatedImageView *agentImageView = [[FCAnimatedImageView alloc] initWithFrame:CGRectZero];
    agentImageView.translatesAutoresizingMaskIntoConstraints = NO;
    agentImageView.backgroundColor = [UIColor redColor];
    agentImageView.clipsToBounds = YES;
    agentImageView.contentMode = UIViewContentModeScaleAspectFill;
    agentImageView.layer.cornerRadius = IMAGE_SIZE/2;
    agentImageView.layer.borderWidth = 3.0f;
    agentImageView.layer.borderColor = [theme getCalendarConfirmAvatarsBorderColor].CGColor;
    agentImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CALENDAR_AGENT_AVATAR];
    [imagesView addSubview:agentImageView];
    
    UILabel *descriptionLbl = [[UILabel alloc]init];
    descriptionLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [descriptionLbl setBackgroundColor:[UIColor clearColor]];
    [descriptionLbl setFont:[theme getCalendarConfirmDescriptionTextFont]];
    [descriptionLbl setTextColor:[theme getCalendarConfirmDescriptionTextColor]];
    descriptionLbl.textAlignment = NSTextAlignmentCenter;
    [content addSubview:descriptionLbl];
    descriptionLbl.numberOfLines = 1;
    descriptionLbl.text = HLLocalizedString(LOC_CALENDAR_INVITE_SCHEDULED_DESCRIPTION);
    
    UILabel *timeLbl = [[UILabel alloc]init];
    timeLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [timeLbl setBackgroundColor:[UIColor clearColor]];
    [timeLbl setFont:[theme getCalendarConfirmTimeTextFont]];
    [timeLbl setTextColor:[theme getCalendarConfirmTimeTextColor]];
    timeLbl.textAlignment = NSTextAlignmentCenter;
    [content addSubview:timeLbl];
    timeLbl.numberOfLines = 1;
    
    UILabel *dateLbl = [[UILabel alloc]init];
    dateLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [dateLbl setBackgroundColor:[UIColor clearColor]];
    [dateLbl setFont:[theme getCalendarConfirmDateTextFont]];
    [dateLbl setTextColor:[theme getCalendarConfirmDateTextColor]];
    dateLbl.textAlignment = NSTextAlignmentCenter;
    [content addSubview:dateLbl];
    dateLbl.numberOfLines = 1;
    
    if (self.inviteTimeInfo[@"startMillis"] && self.inviteTimeInfo[@"endMillis"]) {
        NSTimeInterval startMillis = [self.inviteTimeInfo[@"startMillis"] doubleValue];
        NSTimeInterval endMillis = [self.inviteTimeInfo[@"endMillis"] doubleValue];
        
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startMillis/1000];
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:endMillis/1000];
        
        dateLbl.text = [FCDateUtil getDetailedDateStringWithFormat:HLLocalizedString(LOC_CALENDAR_SLOTS_DATE_FORMAT) forDate:startDate];
        
        timeLbl.text = [NSString stringWithFormat:@"%@ - %@",
                        [FCDateUtil getDateStringWithFormat:HLLocalizedString(LOC_CALENDAR_SLOTS_TIME_FORMAT) forDate:startDate],
                        [FCDateUtil getDateStringWithFormat:HLLocalizedString(LOC_CALENDAR_SLOTS_TIME_FORMAT) forDate:endDate]];
    }
    if (self.inviteTimeInfo && self.inviteTimeInfo[@"calendarAgentAlias"]) {
        [FCUtilities setAgentImage:agentImageView forAlias:self.inviteTimeInfo[@"calendarAgentAlias"]];
    }
    
    NSDictionary *views = @{
        @"contentScroll" : self.contentScrollView,
        @"contentView" : self.contentView,
        @"content" : content,
        @"images" : imagesView,
        @"agentImage" : agentImageView,
        @"userImage" : userImageView,
        @"description" : descriptionLbl,
        @"time" : timeLbl,
        @"date" : dateLbl};
    
    NSDictionary *paddingMetrics = @{@"padding":@15,
                                     @"profileImgSize" : @(IMAGE_SIZE)};
    
    [imagesView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[agentImage(profileImgSize)]-(-25)-[userImage(profileImgSize)]|" options:0 metrics:paddingMetrics views:views]];
    [imagesView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[agentImage(profileImgSize)]|" options:0 metrics:paddingMetrics views:views]];
    [imagesView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[userImage(profileImgSize)]|" options:0 metrics:paddingMetrics views:views]];
    
    [FCAutolayoutHelper centerX:imagesView onView:content];
    
    [FCAutolayoutHelper centerX:descriptionLbl onView:content];
    
    [FCAutolayoutHelper centerX:timeLbl onView:content];
    
    [FCAutolayoutHelper centerX:dateLbl onView:content];
    
    [content addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[images(profileImgSize)]-(25)-[description]-(padding)-[time]-(padding)-[date]-(>=0)-|" options:0 metrics:paddingMetrics views:views]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[content]-(>=0)-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[content]-|" options:0 metrics:nil views:views]];
    
    [FCAutolayoutHelper centerX:content onView:self.contentView];
    [FCAutolayoutHelper centerY:content onView:self.contentView];
    
    if (@available(iOS 11.0, *)) {
        [NSLayoutConstraint activateConstraints:@[[self.contentScrollView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor], [self.contentScrollView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor], [self.contentScrollView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor], [self.contentScrollView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]]];
    } else {
        [self.contentScrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[contentView]-|" options:0 metrics:paddingMetrics views:views]];
        [self.contentScrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[contentView]-|" options:0 metrics:paddingMetrics views:views]];
    }
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                           toItem:self.contentScrollView
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1
                                                                         constant:0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.contentScrollView
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1
                                                                        constant:0];
    [self.contentScrollView addConstraint:heightConstraint];
    [self.contentScrollView addConstraint:widthConstraint];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[contentScroll]-|" options:0 metrics:paddingMetrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[contentScroll]-|" options:0 metrics:paddingMetrics views:views]];
    
}

@end
