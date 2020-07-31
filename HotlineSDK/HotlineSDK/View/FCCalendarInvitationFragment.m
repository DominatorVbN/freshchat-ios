//
//  FCCalendarInvitationFragment.m
//  FreshchatSDK
//
//  Created by Harish kumar on 23/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCalendarInvitationFragment.h"
#import "FCTheme.h"
#import "FCAutolayoutHelper.h"
#import "FCUtilities.h"
#import "FCParticipants.h"
#import "FCSecureStore.h"
#import "FCAnimatedImageView.h"
#import "FCLocaleUtil.h"
#import "FCDateUtil.h"
#import "FCLocalization.h"

@implementation FCCalendarInvitationFragment

-(id) initWithFragment: (FragmentData *) fragment uploadStatus:(BOOL)uploadStatus andInternalMeta:(nonnull NSString *)internalMeta {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        FCTheme *theme = [FCTheme sharedInstance];
        self.backgroundColor = [theme getInvitationBackgroundColor];
        self.layer.cornerRadius = 4;
        self.clipsToBounds = YES;
        self.layer.masksToBounds = NO;
        self.layer.shadowColor = UIColor.lightGrayColor.CGColor;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowOpacity = 0.5f;
        
        self.fragmentData = fragment;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSData *extraJSONData = [fragment.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
        
        if(extraJSONDict && extraJSONDict[@"extraJSON"]) {
            extraJSONData = [extraJSONDict[@"extraJSON"] dataUsingEncoding:NSUTF8StringEncoding];
            extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
        }
        
        NSData *internalMetaData = [internalMeta dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *internalDict;
        if (internalMetaData) {
            internalDict = [NSJSONSerialization JSONObjectWithData:internalMetaData options:0 error:nil];
            internalDict = internalDict[@"calendarMessageMeta"];
        }
        
        UIView *scheduleLblView = [[UIView alloc] init];
        scheduleLblView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:scheduleLblView];
        
        UIImageView *calendarIcon = [[UIImageView alloc] init];
        calendarIcon.translatesAutoresizingMaskIntoConstraints = NO;
        [calendarIcon setContentMode:UIViewContentModeScaleAspectFit];
        calendarIcon.image = [[FCTheme sharedInstance]
                                 getImageWithKey:IMAGE_CALENDAR_PENDING_CONFIRMATION_ICON];
        [scheduleLblView addSubview:calendarIcon];
        
        UILabel *scheduleLbl = [[UILabel alloc]init];
        scheduleLbl.translatesAutoresizingMaskIntoConstraints = NO;
        [scheduleLbl setBackgroundColor:[UIColor clearColor]];
        [scheduleLbl setFont:[theme getInvitationStatusTextFont]];
        [scheduleLbl setTextColor:[theme getInvitationStatusTextColor]];
        [scheduleLblView addSubview:scheduleLbl];
        scheduleLbl.numberOfLines = 1;
        if(uploadStatus && internalDict && internalDict[@"retryCalendarEvent"]) {
            if (![internalDict[@"retryCalendarEvent"] boolValue] && internalDict[@"calendarEventLink"]){
                calendarIcon.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CALENDAR_SCHEDULED_ICON];
                scheduleLbl.text = HLLocalizedString(LOC_CALENDAR_INVITE_SCHEDULED);
            } else {
                calendarIcon.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CALENDAR_CANCELLED_ICON];
                scheduleLbl.text = HLLocalizedString(LOC_CALENDAR_INVITE_FAILED);
            }
        } else {
            scheduleLbl.text = HLLocalizedString(LOC_CALENDAR_INVITE_PENDING);
        }
        
        UILabel *durationLbl = [[UILabel alloc]init];
        durationLbl.translatesAutoresizingMaskIntoConstraints = NO;
        [durationLbl setBackgroundColor:[UIColor clearColor]];
        [durationLbl setFont:[theme getInvitationDurationTextFont]];
        [durationLbl setTextColor:[theme getInvitationDurationTextColor]];
        durationLbl.textAlignment = NSTextAlignmentCenter;
        [self addSubview:durationLbl];
        durationLbl.numberOfLines = 1;
        
        UIView *participantsView = [[UIView alloc] init];
        participantsView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:participantsView];
        
        FCAnimatedImageView *userImageView=[[FCAnimatedImageView alloc] initWithFrame:CGRectZero];
        userImageView.translatesAutoresizingMaskIntoConstraints = NO;
        userImageView.backgroundColor = [UIColor clearColor];
        userImageView.clipsToBounds = YES;
        userImageView.contentMode = UIViewContentModeScaleAspectFill;
        userImageView.layer.cornerRadius=FC_PROFILEIMAGE_DIMENSION/2;
        userImageView.layer.borderWidth = 2;
        userImageView.layer.borderColor = [theme getInvitationAvatarsBorderColor].CGColor;
        userImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CALENDAR_CUSTOMER_AVATAR];
        [participantsView addSubview:userImageView];
        
        FCAnimatedImageView *agentImageView=[[FCAnimatedImageView alloc] initWithFrame:CGRectZero];
        agentImageView.translatesAutoresizingMaskIntoConstraints = NO;
        agentImageView.backgroundColor = [UIColor clearColor];
        agentImageView.clipsToBounds = YES;
        agentImageView.contentMode = UIViewContentModeScaleAspectFill;
        agentImageView.layer.cornerRadius=FC_PROFILEIMAGE_DIMENSION/2;
        agentImageView.layer.borderWidth = 2;
        agentImageView.layer.borderColor = [theme getInvitationAvatarsBorderColor].CGColor;
        agentImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_CALENDAR_AGENT_AVATAR];
        [participantsView addSubview:agentImageView];
        
        UILabel *meetingLabel = [[UILabel alloc]init];
        meetingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [meetingLabel setBackgroundColor:[UIColor clearColor]];
        [meetingLabel setFont:[theme getInvitationDescriptionTextFont]];
        [meetingLabel setTextColor:[theme getInvitationDescriptionTextColor]];
        meetingLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:meetingLabel];
        meetingLabel.numberOfLines = 1;
        meetingLabel.text = HLLocalizedString(LOC_CALENDAR_INVITE_SCHEDULED_DESCRIPTION);
        
        UILabel *dateLbl = [[UILabel alloc]init];
        dateLbl.translatesAutoresizingMaskIntoConstraints = NO;
        [dateLbl setBackgroundColor:[UIColor clearColor]];
        [dateLbl setFont:[theme getInvitationDateTextFont]];
        [dateLbl setTextColor:[theme getInvitationDateTextColor]];
        dateLbl.textAlignment = NSTextAlignmentCenter;
        [self addSubview:dateLbl];
        dateLbl.numberOfLines = 1;
        
        UILabel *timeLbl = [[UILabel alloc]init];
        timeLbl.translatesAutoresizingMaskIntoConstraints = NO;
        [timeLbl setBackgroundColor:[UIColor clearColor]];
        [timeLbl setFont:[theme getInvitationTimeTextFont]];
        [timeLbl setTextColor:[theme getInvitationTimeTextColor]];
        timeLbl.textAlignment = NSTextAlignmentCenter;
        [self addSubview:timeLbl];
        timeLbl.numberOfLines = 1;
        
        NSDictionary *views = @{@"scheduleLblView" : scheduleLblView, @"calendarIcon" : calendarIcon,
                                @"scheduleLbl" : scheduleLbl, @"durationLbl" : durationLbl,
                                @"participantsView" : participantsView,
                                @"agentImageView" : agentImageView,
                                @"userImageView" : userImageView,
                                @"meetingLbl" : meetingLabel,
                                @"dateLbl" : dateLbl,
                                @"timeLbl" : timeLbl};
        
        NSDictionary *paddingMetrics = @{@"padding":@8, @"iconWidth" : @20, @"iconHeight": @20, @"scheduleLblWidth": @(scheduleLbl.intrinsicContentSize.width), @"durationLblWidth" : @(durationLbl.intrinsicContentSize.width), @"dateLblWidth" : @(dateLbl.intrinsicContentSize.width)};
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[scheduleLblView]-(>=0)-|" options:0 metrics:nil views:views]];
        [scheduleLblView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[calendarIcon(iconWidth)]-padding-[scheduleLbl]-|"
                                                                                options:0 metrics:paddingMetrics views:views]];
        
        [FCAutolayoutHelper centerY:calendarIcon onView:scheduleLblView];
        [FCAutolayoutHelper centerY:scheduleLbl onView:scheduleLblView];

        [scheduleLblView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[scheduleLbl]-(>=0)-|"
                                                                                options:0 metrics:paddingMetrics views:views]];
        
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[durationLbl]-|"
                                                                     options:0 metrics:paddingMetrics views:views]];
        
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[scheduleLblView(>=iconHeight)]-5-[durationLbl]-8-[participantsView(42)]-padding-[meetingLbl]-padding-[timeLbl]-padding-[dateLbl]-(20@500)-|" options:0 metrics:paddingMetrics views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[participantsView]-(>=0)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[dateLbl]-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[meetingLbl]-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[timeLbl]-|" options:0 metrics:nil views:views]];
        
        [FCAutolayoutHelper centerX:scheduleLblView onView:self];
        [FCAutolayoutHelper centerX:participantsView onView:self];
        
        [participantsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[agentImageView]|"
                                                                                 options:0 metrics:paddingMetrics views:views]];
        [participantsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[userImageView]|"
                                                                                 options:0 metrics:paddingMetrics views:views]];
        [participantsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[agentImageView(42)]-(-5)-[userImageView(42)]-|"
                                                                                 options:0 metrics:paddingMetrics views:views]];
        if (extraJSONDict[@"startMillis"] && extraJSONDict[@"endMillis"]) {
            NSTimeInterval startMillis = [extraJSONDict[@"startMillis"] doubleValue];
            NSTimeInterval endMillis = [extraJSONDict[@"endMillis"] doubleValue];
            durationLbl.text = [FCUtilities intervalStrFromMillis:startMillis toMillis:endMillis];
            
            NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startMillis/1000];
            NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:endMillis/1000];
            
            dateLbl.text = [FCDateUtil getDetailedDateStringWithFormat:HLLocalizedString(LOC_CALENDAR_SLOTS_DATE_FORMAT) forDate:startDate];
            
            timeLbl.text = [NSString stringWithFormat:@"%@ - %@",
                            [FCDateUtil getDateStringWithFormat:HLLocalizedString(LOC_CALENDAR_SLOTS_TIME_FORMAT) forDate:startDate],
                            [FCDateUtil getDateStringWithFormat:HLLocalizedString(LOC_CALENDAR_SLOTS_TIME_FORMAT) forDate:endDate]];
        }
        BOOL showteamMemberInfo = [[FCSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
        if (showteamMemberInfo && internalDict && internalDict[@"calendarAgentAlias"]) {
            FCParticipants *participant = [FCParticipants fetchParticipantForAlias:internalDict[@"calendarAgentAlias"] inContext:[FCDataManager sharedInstance].mainObjectContext];
            if (participant.profilePicURL) {
                [FCUtilities loadImageWithUrl:participant.profilePicURL forView:agentImageView andErrorImage:[[FCTheme sharedInstance] getImageWithKey:IMAGE_CAROUSEL_ERROR_IMAGE]];
            }
        }
        
        if (internalDict && internalDict[@"calendarAgentAlias"]) {
            [FCUtilities setAgentImage:agentImageView forAlias:internalDict[@"calendarAgentAlias"]];
        }
        
    }
    return self;
}

@end
