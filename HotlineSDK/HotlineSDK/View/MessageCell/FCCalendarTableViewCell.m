//
//  FCCalendarTableViewCell.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 11/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCalendarTableViewCell.h"
#import "FCTheme.h"
#import "FCUtilities.h"
#import "FCAutolayoutHelper.h"
#import "FCCalendarModel.h"
#import "FCLocalNotification.h"
#import "FCTheme.h"

@interface FCCalendarTableViewCell()
@property(nonatomic, strong, retain) UILabel *headerLabel;
@property(nonatomic, strong, retain) UIView *buttonView;
@property(nonatomic, strong, retain) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) FCTheme *theme;

@end

@implementation FCCalendarTableViewCell


- (instancetype)initWithReuseIdentifier:(NSString *)identifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self initCell];
    }
    return self;
}

-(void)initCell {
    self.backgroundColor = [UIColor clearColor];
    UIView *topView = [[UIView alloc]init];
    self.theme = [FCTheme sharedInstance];
    topView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:topView];
    UIView *headerView = [[UIView alloc]init];
    headerView.backgroundColor = [UIColor clearColor];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [topView addSubview:headerView];
    self.buttonView = [[UIView alloc]init];
    self.buttonView.translatesAutoresizingMaskIntoConstraints = NO;
    [topView addSubview:self.buttonView];
    
    self.headerLabel = [[UILabel alloc]init];
    self.headerLabel.textColor = [self.theme getCalendarSlotsSessionNameTextColor];
    [self.headerLabel setFont:[self.theme getCalendarSlotsSessionNameTextFont]];
    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerLabel.numberOfLines = 0;
    [headerView addSubview:self.headerLabel];
    NSDictionary *views = @{@"topView":topView,
                            @"headerView":headerView,
                            @"headerLabel":self.headerLabel,
                            @"buttonView":self.buttonView
    };
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[topView]-10-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topView]-10-|" options:0 metrics:nil views:views]];
    [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headerView]|" options:0 metrics:nil views:views]];
    [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[buttonView]|" options:0 metrics:nil views:views]];
    [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headerView][buttonView]-0@500-|" options:0 metrics:nil views:views]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[headerLabel]-2-|" options:0 metrics:nil views:views]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headerLabel]-2-|" options:0 metrics:nil views:views]];
}

-(void) updateView:(NSArray<FCCalendarSession *>*)sessions forLastCellInRow:(BOOL)isLastCell andLastRow:(BOOL)isLastRow {
    [self clearAllButtonSubviews];
    if (sessions.count > 0) {
        self.headerLabel.text = [NSString stringWithFormat:@"%@",[sessions.firstObject getSessionTitle]];
    }
    if (sessions.count == 0) { return; }
    CGFloat safeAreapadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if (UIDeviceOrientationIsLandscape(orientation)) {
            safeAreapadding = window.safeAreaInsets.left + window.safeAreaInsets.right;
        }
    }
    
    int remaining = ((int)[UIScreen mainScreen].bounds.size.width - 25 - (int)(safeAreapadding)) % 90 ;
    int noOfLabels = ((int)[UIScreen mainScreen].bounds.size.width - 25 - (int)(safeAreapadding)) / 90;
    int padding = (10 * (noOfLabels - 1));
    float width = 90;
    if (remaining < padding) {
        noOfLabels -= 1;
        remaining += 80 - (10 * (noOfLabels - 1));
        width = 90 + (remaining /noOfLabels);
    }
    NSMutableArray *sessionsArray = [[NSMutableArray alloc]init];
    for(int i=0; i< sessions.count; i++) {

        SlotButton *button = [[SlotButton alloc]init];
        button.titleLabel.font = [UIFont systemFontOfSize:13];
        button.layer.borderWidth = 0.2;
        button.layer.cornerRadius = 4.0;
        button.layer.borderColor = [[FCTheme sharedInstance] getCalendarSlotsButtonBorderColor].CGColor;
        
        [button setBackgroundImage:[FCUtilities imageWithColor:[self.theme getCalendarSlotsButtonSelectedBackgroundColor]]  forState:UIControlStateHighlighted];
        [button setBackgroundImage:[FCUtilities imageWithColor:[self.theme getCalendarSlotsButtonSelectedBackgroundColor]] forState:UIControlStateSelected];
        
        [button setTitleColor:[self.theme getCalendarSlotsButtonBackgroundColor] forState:UIControlStateHighlighted];
        [button setTitleColor:[self.theme getCalendarSlotsButtonBackgroundColor] forState:UIControlStateSelected];
        
        [button setTitleColor:[self.theme getCalendarSlotsButtonTitleColor] forState:UIControlStateNormal];
        button.titleLabel.font = [self.theme getCalendarSlotsButtonTitleFont];
        button.tag = i;
        button.dateVal = sessions[i].date;
        button.timeZoneVal = sessions[i].timeZone;
        [button setTitle:sessions[i].time forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [sessionsArray addObject:button];
        if ((i+1) % noOfLabels == 0) {
            int height = (i / noOfLabels) * 35 + ((i / noOfLabels) + 1) * 10;
            [self addLabels:sessionsArray inView:self.buttonView height:height width:width];
            [sessionsArray removeAllObjects];
        }
    }
    
    if (sessions.count  % noOfLabels > 0) {
        int height = (int)(((sessions.count - 1) / noOfLabels) * 35 + ((sessions.count / noOfLabels) + 1) * 10);
        [self addLabels:sessionsArray inView:self.buttonView height:height width:width];
    }
    int buttonsHeight = (int)(sessions.count / noOfLabels) + (((sessions.count % noOfLabels) == 0) ? 0 : 1);
    int paddingHeight = buttonsHeight * 10;
    buttonsHeight *= 35;
    buttonsHeight += paddingHeight + (isLastCell ? 10 : 0);
    if(isLastCell && !isLastRow) {
        UIView * separatorLine = [[UIView alloc]init];
        separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
        [separatorLine setBackgroundColor:[self.theme getCalendarSlotsDividerColor]];
        [self.buttonView addSubview:separatorLine];
        NSDictionary *view = @{@"separator" : separatorLine};
        [self.buttonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[separator]|" options:0 metrics:nil views:view]];
        [self.buttonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[separator(0.5)]-5-|" options:0 metrics:nil views:view]];
        buttonsHeight += 31;
    }
    self.bottomConstraint = [FCAutolayoutHelper setHeight:buttonsHeight forView:self.buttonView inView:self.buttonView.superview];
    
}

-(void) clearAllButtonSubviews {
    if(self.bottomConstraint) {
        [self.bottomConstraint setActive:false];
        [self.buttonView removeConstraint:self.bottomConstraint];
    }
    NSArray *subViewArr = [self.buttonView subviews];
    for (UIView *subUIView in subViewArr) {
        [subUIView removeFromSuperview];
        [subUIView removeConstraints: subUIView.constraints];
    }
}

-(void)addLabels:(NSArray<UIButton*>*)buttons inView:(UIView *) view  height:(int)height width:(int)width {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]init];
    NSString *horizontalConstraint = @"";
    for(int i=0; i< buttons.count; i++) {
        UIButton *button = buttons[i];
        button.layer.cornerRadius = 4.0;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        NSString *key = [NSString stringWithFormat:@"button%d",i];
        dictionary[key] = button;
        [view addSubview:button];
        NSString *verticalConstraint = [NSString stringWithFormat:@"V:|-%d-[%@(%d)]",height,key,35];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalConstraint options:0 metrics:nil views:dictionary]];
        NSString *horizontalStringConstraint = i == buttons.count - 1 ? @"%@[%@(%d)]" : @"%@[%@(%d)]-10-";
        horizontalConstraint = [NSString stringWithFormat:horizontalStringConstraint,horizontalConstraint,key,width];
    }
    horizontalConstraint = [NSString stringWithFormat:@"H:|%@-(>=0@500)-|",horizontalConstraint];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontalConstraint options:0 metrics:nil views:dictionary]];
    
}

-(void)buttonClick:(id)sender {
    SlotButton* slot = (SlotButton*)sender;
    if(slot.dateVal && slot.timeZoneVal) {
        NSDictionary *selectedDict = @{ @"startMillis" : [NSNumber numberWithDouble:[slot.dateVal timeIntervalSince1970]*1000], @"userTimeZone" : slot.timeZoneVal.name};
        [FCLocalNotification post:FRESHCHAT_CALENDAR_SLOT_SELECTED info:selectedDict];
    }
}

@end

@implementation SlotButton

- (instancetype)init{
    self = [super init];
    if (self) {
        self.timeZoneVal = [NSTimeZone new];
        self.dateVal = [NSDate new];
    }
    return self;
}

@end
