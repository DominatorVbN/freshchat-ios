//
//  FCCalendarOptionsView.m
//  FreshchatSDK
//
//  Created by Harish kumar on 22/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCalendarOptionsView.h"
#import "FCTheme.h"
#import "FCLocalization.h"

@interface FCCalendarOptionsView()

@property (nonatomic, strong) UIView *optionsView;
@property (nonatomic, strong) FCMessageData *message;

@end

@implementation FCCalendarOptionsView

- (id) initCalendarOptionsViewForMessage : (FCMessageData *) message{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.message = message;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addCalendarOptions];
    }
    return self;
}

- (void) addCalendarOptions {
    FCTheme *theme = [FCTheme sharedInstance];// Use for theme customization
    
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    
    self.optionsView = [[UIView alloc] init];
    self.optionsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.optionsView];
    self.optionsView.clipsToBounds = YES;
    [views setObject:self.optionsView forKey:@"options"];
    
    UIButton *selectSlotBtn = [[UIButton alloc] init];
    selectSlotBtn.translatesAutoresizingMaskIntoConstraints = NO;
    selectSlotBtn.userInteractionEnabled = YES;
    [selectSlotBtn.titleLabel setFont:[theme getFindSlotButtonTitleFont]];
    [selectSlotBtn setTitleColor:[theme getFindSlotButtonTitleColor] forState:UIControlStateNormal];
    selectSlotBtn.layer.cornerRadius = 4.0f;
    selectSlotBtn.layer.masksToBounds = true;
    [selectSlotBtn setTitle:HLLocalizedString(LOC_CALENDAR_FIND_SLOTS_BTN) forState:UIControlStateNormal];
    selectSlotBtn.backgroundColor = [theme getFindSlotButtonBackgroundColor];
    [selectSlotBtn addTarget:self action:@selector(selectSlots:) forControlEvents:UIControlEventTouchUpInside];
    [self.optionsView addSubview:selectSlotBtn];
    [views setObject:selectSlotBtn forKey:@"selectSlot"];
    
    UIButton *cancelBtn = [[UIButton alloc] init];
    cancelBtn.userInteractionEnabled = YES;
    cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelBtn.titleLabel setFont:[theme getNotInterestedButtonFont]];
    [cancelBtn setTitleColor:[theme getNotInterestedButtonColor] forState:UIControlStateNormal];
    [cancelBtn setTitle:HLLocalizedString(LOC_CALENDAR_CANCEL_INVITE_BTN) forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelInvite:) forControlEvents:UIControlEventTouchUpInside];
    [self.optionsView addSubview:cancelBtn];
    [views setObject:cancelBtn forKey:@"cancel"];
    
    NSDictionary *metrics = @{@"padding":@4, @"btnHeight" : @36};
    
    [self.optionsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[selectSlot(>=50)]-|" options:0 metrics:nil views:views]];
    [self.optionsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[cancel(>=50)]-|" options:0 metrics:nil views:views]];
    [self.optionsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[selectSlot(<=btnHeight)]-padding-[cancel(<=btnHeight)]|" options:0 metrics:metrics views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[options]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[options]|" options:0 metrics:nil views:views]];
}

- (void)selectSlots:(id)sender{
    //Show available Time Zones
    if (self.delegate != nil) {
        [self.delegate handleCalendarMsg:self.message forAction:BOOK_NOW];
    }
}

- (void)cancelInvite:(id)sender{
    //Disable buttons or hide them
    [self.optionsView removeFromSuperview];
    if (self.delegate != nil) {
        [self.delegate handleCalendarMsg:self.message forAction:CANCEL_NOW];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
