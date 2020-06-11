//
//  FCCalendarBannerView.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 20/05/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCalendarBannerView.h"
#import "FCLocaleUtil.h"
#import "FCTheme.h"
#import "FCAutolayoutHelper.h"
#import "FCLocalization.h"

@interface FCCalendarBannerView()
@property(nonatomic, strong) UILabel* timeLabel;
@property(nonatomic, strong) NSURL* url;
@property(nonatomic) NSTimeInterval time;
@end

@implementation FCCalendarBannerView

- (id)initWithURL:(NSURL *)url andTime:(NSTimeInterval)time {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.url = url;
        self.time = time;
        FCTheme *theme = [FCTheme sharedInstance];
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.timeLabel = [[UILabel alloc]init];
        [self.timeLabel setFont:[theme getBannerTextFont]];
        self.timeLabel.textColor = [theme getBannerTextColor];
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false;
        [self addSubview:self.timeLabel];
        UIImageView* imageView = [[UIImageView alloc]init];
        imageView.image = [theme getImageWithKey:IMAGE_CALENDAR_BANNER];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        [self addSubview:imageView];
        UILabel* viewLabel = [[UILabel alloc]init];
        viewLabel.translatesAutoresizingMaskIntoConstraints = false;
        [self addSubview:viewLabel];
        NSDictionary *metrics = @{@"parentPadding": @15,
                                  @"interimPadding": @8,
                                  @"topPadding": @13,
                                  @"bottomPadding": @10};
        NSDictionary *view = @{@"img": imageView,
                               @"time": self.timeLabel,
                               @"view": viewLabel};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-parentPadding-[img(13)]-(interimPadding)-[time]-(>=interimPadding)-[view]-parentPadding-|" options:0 metrics:metrics views:view]];
        [FCAutolayoutHelper centerY:imageView onView:self];
        [FCAutolayoutHelper centerY:self.timeLabel onView:self];
        [FCAutolayoutHelper centerY:viewLabel onView:self];

        self.backgroundColor = [theme getBannerBackgroundColor];
        self.timeLabel.text = [self getDateFromTime:time];
        viewLabel.textColor = [theme getBannerTextColor];
        viewLabel.text = HLLocalizedString(LOC_CALENDAR_INVITE_BANNER_VIEW_LABEL);
        [viewLabel setFont:[theme getBannerTextFont]];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        tapRecognizer.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;;
}

-(void)handleTap {
    if(self.url != nil){
        BOOL isHandled = [self.delegate handleLinkDelegate:self.url];
        if (!isHandled) {
            if([[UIApplication sharedApplication] canOpenURL:self.url]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:self.url];
                });
            }
        }
    }
}

-(void)updateViewWithTime:(NSTimeInterval)time andURL:(NSURL *) url{
    if (self.time > time) {
        self.time = time;
        self.url = url;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timeLabel.text = [self getDateFromTime:time];
        });
    }
}

-(NSString *)getDateFromTime:(NSTimeInterval) time {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone defaultTimeZone];
    
    NSLocale *locale =[[NSLocale alloc] initWithLocaleIdentifier:[FCLocaleUtil getUserLocale]];
    [dateFormatter setLocale:locale];
    [dateFormatter setDateFormat:[NSString stringWithFormat:@"%@ %@",HLLocalizedString(LOC_CALENDAR_SLOTS_DATE_FORMAT), HLLocalizedString(LOC_CALENDAR_SLOTS_TIME_FORMAT)]];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time/1000];
    return [dateFormatter stringFromDate:date];
}

@end
