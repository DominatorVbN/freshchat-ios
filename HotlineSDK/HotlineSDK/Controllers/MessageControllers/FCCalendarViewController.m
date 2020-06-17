//
//  FCCalendarViewController.m
//  FreshchatSDK
//
//  Created by Harish kumar on 23/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCalendarViewController.h"
#import "FCTheme.h"
#import "FCStringUtil.h"
#import "FCAutolayoutHelper.h"
#import "FCUserDefaults.h"
#import "FreshchatSDK.h"
#import "FCCoreServices.h"
#import "FCMessageUtil.h"
#import "FCCalendarModel.h"
#import "FCCalendarTableViewController.h"
#import "FCDateUtil.h"
#import "FCCalendarSlotConfirmationView.h"
#import "FCLocalNotification.h"
#import "FCLocalization.h"
#import "FCEventsHelper.h"

#define FC_VIEW_WIDTH self.view.frame.size.width
#define FC_VIEW_HEIGHT self.view.frame.size.height

@interface FCCalendarViewController ()<UITextFieldDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) FCTheme *theme;
@property (strong, nonatomic) UIView* emailView;
@property (strong, nonatomic) UITextField *userEmailField;
@property (nonatomic) enum FCCalendarViewState calendarState ;
@property (strong, nonatomic) UILabel *durationLabel;
@property (strong, nonatomic) NSString *duration;
@property (strong, nonatomic) UIView* calendarSlotsView;
@property (strong, nonatomic) UIButton* showSlotsBtn;
@property (strong, nonatomic) UIButton *showMoreSlotsBtn;
@property (strong, nonatomic) UIView* confirmSlotView;
@property (nonatomic, assign) float buttonWidth;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGRect viewFrame;
@property (strong, nonatomic) NSString* prevCalendarEmail;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIView *slotsView;
@property (nonatomic, strong) FCCalendarTableViewController *calendarController;
@property (strong, nonatomic) NSMutableDictionary *metrics;
@property (nonatomic, strong) UIView *emptySlotsErrorView;
@property (nonatomic, strong) UIView *innerContainerView;

@property (strong, nonatomic) NSLayoutConstraint *viewHtConstraint;
@property (strong, nonatomic) NSLayoutConstraint *showMoreBtnHtConstraint;
@property (strong, nonatomic) NSLayoutConstraint *innerContainerWidth;

@property (strong, nonatomic) FCCalendarSlotConfirmationView *confirmationView;
@property (nonatomic, strong) NSDictionary* slotsResponseDict;

@property (nonatomic, strong) NSMutableDictionary *selectedSlot;
@property (nonatomic, strong) UIView *coverView;

@property (nonatomic, strong) NSString *calendarEventId;

@end

@implementation FCCalendarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.theme = [FCTheme sharedInstance];
    self.coverView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.coverView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    self.coverView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.coverView];
    NSDictionary *views = @{@"coverView": self.coverView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[coverView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[coverView]|" options:0 metrics:nil views:views]];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeViewController)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self.coverView addGestureRecognizer:tapRecognizer];
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        self.buttonWidth = MIN((FC_VIEW_WIDTH/2)*0.96, (FC_VIEW_HEIGHT/2)*0.96);
    }
    else{
        self.buttonWidth = MIN(FC_VIEW_WIDTH*0.96, FC_VIEW_HEIGHT*0.96);
    }
    [self setViewsMetrics];
    [self addEmailView];
    
    NSDictionary *jsonDict = [FCMessageUtil getInternalMetaForData:self.message.internalMeta];
    self.calendarEventId = [jsonDict valueForKeyPath:@"calendarMessageMeta.calendarInviteId"];
    [self addCalendarEvent:FCEventCalendarFindTimeSlotClick];
    
    [self localNotificationSubscription];
    // Do any additional setup after loading the view.
}

- (void) addCalendarEvent : (FCEvent) eventName {
    if([FCStringUtil isNotEmptyString:self.calendarEventId]){
        FCOutboundEvent *outEvent = [[FCOutboundEvent alloc] initOutboundEvent:eventName
                                                                    withParams:@{@(FCPropertyInviteId) : self.calendarEventId}];
        [FCEventsHelper postNotificationForEvent:outEvent];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self localNotificationUnSubscription];
}

- (void) closeViewController {
    [self dismissModalViewControllerAnimated:true];
}

- (void) setViewsMetrics {
    self.metrics = [[NSMutableDictionary alloc]init];
    [self.metrics setObject: @15 forKey:@"padding"];
    [self.metrics setObject: @60 forKey:@"navBarHt"];
    [self.metrics setObject: @(self.buttonWidth) forKey:@"btnWidth"];
    [self.metrics setObject: @36 forKey:@"btnHeight"];
    [self.metrics setObject: UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? @(FC_VIEW_HEIGHT*0.9) :@(FC_VIEW_HEIGHT*0.6) forKey:@"semiViewHt"];
    [self.metrics setObject: @(FC_VIEW_HEIGHT*0.9) forKey:@"maxViewHt"];
    [self.metrics setObject: @([FCUtilities hasNotchDisplay] ? 30 : 15) forKey:@"bottomPadding"];
    [self.metrics setObject: @1 forKey: @"dividerHt"];
}

- (void)localNotificationSubscription {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectSlotWithInfo:)
                                                 name:FRESHCHAT_CALENDAR_SLOT_SELECTED
                                               object:nil];
}

- (void) addEmailView
{
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    
    self.prevCalendarEmail = [FCUserDefaults getStringForKey:FRESHCHAT_DEFAULTS_CALENDAR_INVITE_EMAILID];
    
    self.emailView = [[UIView alloc] init];
    self.emailView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emailView.layer.cornerRadius = 10.0f;
    self.emailView.backgroundColor = [self.theme getCalendarPopupBackgroundColor];
    [self.view addSubview:self.emailView];
    [views setObject:self.emailView forKey:@"emailView"];
    
    self.innerContainerView = [[UIView alloc] init];
    self.innerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.innerContainerView.backgroundColor = [UIColor clearColor];
    self.innerContainerView.clipsToBounds = YES;
    [self.emailView addSubview:self.innerContainerView];
    [views setObject:self.innerContainerView forKey:@"innerContainer"];
    
    UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
    [gestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.innerContainerView addGestureRecognizer:gestureRecognizer];
    
    UIView *navBarView = [self getCalendarViewNavBar];
    navBarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.innerContainerView addSubview:navBarView];
    [views setObject:navBarView forKey:@"navBar"];
    
    UIView *dividerView = [[UIView alloc] init];
    dividerView.translatesAutoresizingMaskIntoConstraints = NO;
    dividerView.backgroundColor = [self.theme getCalendarPopupNavBarDividerColor];
    [self.emailView addSubview:dividerView];
    [views setObject:dividerView forKey:@"divider"];
    
    UILabel *descriptionLbl = [[UILabel alloc]init];
    descriptionLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [descriptionLbl setBackgroundColor:[UIColor clearColor]];
    [descriptionLbl setFont:[self.theme getCalendarEmailViewDescTextFont]];
    [descriptionLbl setTextColor:[self.theme getCalendarEmailViewDescTextColor]];
    [self.innerContainerView addSubview:descriptionLbl];
    descriptionLbl.numberOfLines = 2;
    descriptionLbl.text = HLLocalizedString(LOC_CALENDAR_EMAIL_DESCRIPTION);
    [views setObject:descriptionLbl forKey:@"description"];
    
    self.userEmailField = [[UITextField alloc]init];
    self.userEmailField.translatesAutoresizingMaskIntoConstraints = NO;
    self.userEmailField.delegate = self;
    [self.userEmailField setFont:[self.theme getCalendarEmailViewTextFieldTextFont]];
    self.userEmailField.borderStyle = UITextBorderStyleNone;
    [self.userEmailField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.userEmailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.userEmailField setTextColor:[self.theme getCalendarEmailViewTextFieldTextColor]];
    self.userEmailField.textAlignment = NSTextAlignmentNatural;
    
    self.userEmailField.placeholder = HLLocalizedString(LOC_CALENDAR_EMAIL_PLACEHOLDER);
    self.userEmailField.keyboardType = UIKeyboardTypeEmailAddress;
    [self.innerContainerView addSubview:self.userEmailField];
    [views setObject:self.userEmailField forKey:@"userEmail"];
    
    self.showSlotsBtn = [[UIButton alloc] init];
    self.showSlotsBtn.clipsToBounds = YES;
    self.showSlotsBtn.layer.cornerRadius = 4;
    [self enableShowSlotsBtn:NO];
    self.showSlotsBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.showSlotsBtn.titleLabel setFont:[self.theme getCalendarEmailViewNextBtnTitleFont]];
    [self.showSlotsBtn setTitleColor:[self.theme getCalendarEmailViewNextBtnTitleColor] forState:UIControlStateNormal];
    [self.showSlotsBtn setTitle:HLLocalizedString(LOC_CALENDAR_NEXT_BTN) forState:UIControlStateNormal];
    self.showSlotsBtn.backgroundColor = [self.theme getCalendarEmailViewNextBtnBackgroundColor];
    [self.showSlotsBtn addTarget:self action:@selector(showSlotsClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.innerContainerView addSubview:self.showSlotsBtn];
    [views setObject:self.showSlotsBtn forKey:@"next"];
    
    NSString *userEmailId = [FreshchatUser sharedInstance].email;
    self.userEmailField.text = [FCStringUtil isNotEmptyString:self.prevCalendarEmail] ? self.prevCalendarEmail
    :([FCStringUtil isNotEmptyString:userEmailId] ? userEmailId : @"");
    [self validateUserEmail:self.userEmailField.text];
    
    [self.emailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[innerContainer]" options:0 metrics:nil views:views]];
    [self.emailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[innerContainer]|" options:0 metrics:nil views:views]];
    
    [self.emailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[divider]|" options:0 metrics:nil views:views]];
    
    [self.emailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-navBarHt-[divider(dividerHt)]" options:0 metrics:self.metrics views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|" options:0 metrics:nil views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[description]-padding-|" options:0 metrics:self.metrics views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[userEmail]-padding-|" options:0 metrics:self.metrics views:views]];
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[next(btnWidth)]" options:0 metrics:self.metrics views:views]];
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar(navBarHt)]-padding-[description]-padding-[userEmail(30)]-padding-[next(btnHeight)]-bottomPadding-|" options:0 metrics:self.metrics views:views]];
    
    [FCAutolayoutHelper centerX:self.innerContainerView onView:self.emailView];
    [FCAutolayoutHelper centerX:self.showSlotsBtn onView:self.innerContainerView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emailView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[emailView]|" options:0 metrics:nil views:views]];
    
    self.innerContainerWidth = [FCAutolayoutHelper setWidth:(FC_VIEW_WIDTH - (2 *[self layoutPadding]))  forView:self.innerContainerView inView:self.emailView];
}

- (UIView *) getCalendarViewNavBar {
    BOOL showDurationlabl = (self.calendarState > EmailView);
    
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    UIView *barView = [[UIView alloc] init];
    barView.translatesAutoresizingMaskIntoConstraints = NO;
    barView.backgroundColor = [self.theme getCalendarPopupNavBarBackgroundColor];
    
    UIImageView *calendarIcon = [[UIImageView alloc] init];
    calendarIcon.translatesAutoresizingMaskIntoConstraints = NO;
    calendarIcon.image = [[FCTheme sharedInstance]
                             getImageWithKey:IMAGE_CALENDAR_ICON];
    [barView addSubview:calendarIcon];
    [views setObject:calendarIcon forKey:@"icon"];
    
    UILabel *scheduleLbl = [[UILabel alloc]init];
    scheduleLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [scheduleLbl setBackgroundColor:[UIColor clearColor]];
    [scheduleLbl setFont:[self.theme getCalendarPopupNavBarTitleTextFont]];
    [scheduleLbl setTextColor:[self.theme getCalendarPopupNavBarTitleTextColor]];
    [barView addSubview:scheduleLbl];
    scheduleLbl.numberOfLines = 1;
    scheduleLbl.text = HLLocalizedString(LOC_CALENDAR_VIEW_TITLE);
    [views setObject:scheduleLbl forKey:@"schedule"];
    
    if(showDurationlabl) {
        self.durationLabel = [[UILabel alloc]init];
        self.durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.durationLabel setBackgroundColor:[UIColor clearColor]];
        [self.durationLabel setFont:[self.theme getCalendarPopupNavBarDurationTextFont]];
        [self.durationLabel setTextColor:[self.theme getCalendarPopupNavBarDurationTextColor]];
        [barView addSubview:self.durationLabel];
        self.durationLabel.numberOfLines = 1;
        self.durationLabel.text = [FCStringUtil isNotEmptyString:self.duration] ? self.duration : @"";
        [views setObject:self.durationLabel forKey:@"duration"];
    }
    
    UIButton *closeBtn = [[UIButton alloc] init];
    closeBtn.userInteractionEnabled = YES;
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn.titleLabel setFont:[[FCTheme sharedInstance] unsupportedMsgFragmentFont]];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn setImage:[[FCTheme sharedInstance] getImageWithKey:IMAGE_CALENDAR_CLOSE_ICON] forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor clearColor];
    [closeBtn addTarget:self action:@selector(closeClick:) forControlEvents:UIControlEventTouchUpInside];
    [barView addSubview:closeBtn];
    [views setObject:closeBtn forKey:@"close"];
    
    NSDictionary *metrics = @{@"padding":@14, @"internalPadding":@18,
                              @"closeHeight" : @30, @"iconHt":@21,
                              @"mxTextHt":@18
    };
    
    [barView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[icon(iconHt)]-internalPadding-[schedule]" options:0 metrics:metrics views:views]];
    
    [barView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[close(closeHeight)]-padding-|" options:0 metrics:metrics views:views]];
    
    [barView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[icon(25)]" options:0 metrics:metrics views:views]];
    [FCAutolayoutHelper centerY:calendarIcon onView:barView];
    
    if(showDurationlabl){
        [barView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[icon(iconHt)]-internalPadding-[duration]" options:0 metrics:metrics views:views]];
        [barView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[schedule(mxTextHt)]-1-[duration(mxTextHt)]-10-|" options:0 metrics:metrics views:views]];
    }else {
        [FCAutolayoutHelper centerY:scheduleLbl onView:barView];
    }
    
    [barView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[close(closeHeight)]" options:0 metrics:metrics views:views]];
    [FCAutolayoutHelper centerY:closeBtn onView:barView];
    return barView;
}

-(void)swipeHandler:(UISwipeGestureRecognizer *)recognizer {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return NO;
}

- (void) showCalendarSlotsView:(id)sender{
    //Show available Time Zones
    [self.emailView removeFromSuperview];
    self.calendarState = (self.calendarState == AllSlotsView) ? AllSlotsView : LimitedSlotsView;
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    
    self.calendarSlotsView = [[UIView alloc] init];
    self.calendarSlotsView.translatesAutoresizingMaskIntoConstraints = NO;
    self.calendarSlotsView.layer.cornerRadius = 10.0f;
    self.calendarSlotsView.backgroundColor = [self.theme getCalendarPopupBackgroundColor];
    [self.view addSubview:self.calendarSlotsView];
    [views setObject:self.calendarSlotsView forKey:@"slotsView"];
    
    self.innerContainerView = [[UIView alloc] init];
    self.innerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.calendarSlotsView addSubview:self.innerContainerView];
    [views setObject:self.innerContainerView forKey:@"innerContainer"];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.innerContainerView addSubview:self.activityIndicator];
    
    UIView *navBarView = [self getCalendarViewNavBar];
    navBarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.innerContainerView addSubview:navBarView];
    [views setObject:navBarView forKey:@"navBar"];
    
    UIView *dividerView = [[UIView alloc] init];
    dividerView.translatesAutoresizingMaskIntoConstraints = NO;
    dividerView.backgroundColor = [self.theme getCalendarPopupNavBarDividerColor];
    [self.calendarSlotsView addSubview:dividerView];
    [views setObject:dividerView forKey:@"divider"];
    
    self.slotsView = [[UIView alloc] init];
    self.slotsView.translatesAutoresizingMaskIntoConstraints = NO;
    self.slotsView.backgroundColor = [UIColor clearColor];
    [self.innerContainerView addSubview:self.slotsView];
    [views setObject:self.slotsView forKey:@"slots"];

    self.showMoreSlotsBtn = [[UIButton alloc] init];
    self.showMoreSlotsBtn.userInteractionEnabled = YES;
    self.showMoreSlotsBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.showMoreSlotsBtn.layer.cornerRadius = 4;
    self.showMoreSlotsBtn.layer.borderWidth = 1.0f;
    self.showMoreSlotsBtn.layer.borderColor = [self.theme getCalendarSlotsShowMoreButtonBorderColor].CGColor;
    self.showMoreSlotsBtn.clipsToBounds = YES;
    [self.showMoreSlotsBtn.titleLabel setFont:[self.theme getCalendarSlotsShowMoreButtonTitleFont]];
    [self.showMoreSlotsBtn setTitleColor:[self.theme getCalendarSlotsShowMoreButtonTitleColor] forState:UIControlStateNormal];
    [self.showMoreSlotsBtn setTitle:HLLocalizedString(LOC_CALENDAR_SLOTS_SHOW_MORE_BTN) forState:UIControlStateNormal];
    self.showMoreSlotsBtn.backgroundColor = [self.theme getCalendarSlotsShowMoreButtonBackgroundColor];
    [self.showMoreSlotsBtn setHidden:true];
    [self.showMoreSlotsBtn addTarget:self action:@selector(showMoreSlotsClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.innerContainerView addSubview:self.showMoreSlotsBtn];
    [views setObject:self.showMoreSlotsBtn forKey:@"showMore"];
    
    CGSize deviceSize = [[UIScreen mainScreen] bounds].size;
    
    NSDictionary *metrics = @{@"viewHt" : ((deviceSize.width > deviceSize.height) ? @(FC_VIEW_HEIGHT*0.9) : @((self.calendarState == AllSlotsView) ? FC_VIEW_HEIGHT*0.9 : FC_VIEW_HEIGHT*0.6)), @"btnHeight" : @((self.calendarState == AllSlotsView) ? 0 : 36)};
    
    [FCAutolayoutHelper centerX:self.activityIndicator onView:self.innerContainerView];
    [FCAutolayoutHelper centerY:self.activityIndicator onView:self.innerContainerView];
    
    [self.calendarSlotsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[innerContainer]" options:0 metrics:nil views:views]];
    [self.calendarSlotsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[innerContainer]|" options:0 metrics:nil views:views]];
    
    [self.calendarSlotsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[divider]|" options:0 metrics:nil views:views]];
    
    [self.calendarSlotsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-navBarHt-[divider(dividerHt)]" options:0 metrics:self.metrics views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|" options:0 metrics:nil views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[slots]|" options:0 metrics:nil views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[showMore(btnWidth)]" options:0 metrics:self.metrics views:views]];
    
    [FCAutolayoutHelper centerX:self.showMoreSlotsBtn onView:self.innerContainerView];
    [FCAutolayoutHelper centerX:self.innerContainerView onView:self.calendarSlotsView];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar(navBarHt)]-2-[slots]-[showMore(<=btnHeight)]-bottomPadding-|" options:0 metrics:self.metrics views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[slotsView(>=0)]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[slotsView]|" options:0 metrics:nil views:views]];
    
    self.viewHtConstraint = [FCAutolayoutHelper setHeight:[[metrics objectForKey:@"viewHt"] floatValue] forView:self.calendarSlotsView inView:self.view];
    self.showMoreBtnHtConstraint = [FCAutolayoutHelper setHeight: ((self.calendarState == AllSlotsView) ? 0 : [[self.metrics objectForKey:@"btnHeight"]floatValue]) forView:self.showMoreSlotsBtn inView:self.view];
    
    self.innerContainerWidth = [FCAutolayoutHelper setWidth:(FC_VIEW_WIDTH - (2 *[self layoutPadding]))  forView:self.innerContainerView inView:self.calendarSlotsView];
}

- (void) showConfirmSlotView:(id)sender{
    
    [self.calendarSlotsView removeFromSuperview];
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    
    self.confirmSlotView = [[UIView alloc] init];
    self.confirmSlotView.translatesAutoresizingMaskIntoConstraints = NO;
    self.confirmSlotView.backgroundColor = [self.theme getCalendarPopupBackgroundColor];;
    self.confirmSlotView.layer.cornerRadius = 10.0f;
    self.confirmSlotView.layer.masksToBounds = true;
    [self.view addSubview:self.confirmSlotView];
    [views setObject:self.confirmSlotView forKey:@"confirmSlotView"];
    
    self.innerContainerView = [[UIView alloc] init];
    self.innerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.innerContainerView.backgroundColor = [UIColor clearColor];
    [self.confirmSlotView addSubview:self.innerContainerView];
    [views setObject:self.innerContainerView forKey:@"innerContainer"];
    
    UIView *navBarView = [self getCalendarViewNavBar];
    navBarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.innerContainerView addSubview:navBarView];
    [views setObject:navBarView forKey:@"navBar"];
    
    UIView *dividerView = [[UIView alloc] init];
    dividerView.translatesAutoresizingMaskIntoConstraints = NO;
    dividerView.backgroundColor = [FCTheme colorWithHex:@"BDBDBD"];
    [self.confirmSlotView addSubview:dividerView];
    [views setObject:dividerView forKey:@"divider"];
    
    UIView *invitationContainerView = [[UIView alloc] init];
    invitationContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.innerContainerView addSubview:invitationContainerView];
    [views setObject:invitationContainerView forKey:@"invitationContainer"];
    
    self.confirmationView = [[FCCalendarSlotConfirmationView alloc] initWithConfirmationData:self.selectedSlot];
    self.confirmationView.translatesAutoresizingMaskIntoConstraints = NO;
    [invitationContainerView addSubview:self.confirmationView];
    [views setObject:self.confirmationView forKey:@"confirmation"];
    
    UIButton *confirmSlotBtn = [[UIButton alloc] init];
    confirmSlotBtn.userInteractionEnabled = YES;
    confirmSlotBtn.translatesAutoresizingMaskIntoConstraints = NO;
    confirmSlotBtn.clipsToBounds = YES;
    confirmSlotBtn.layer.cornerRadius = 4;
    [confirmSlotBtn.titleLabel setFont:[self.theme getCalendarConfirmButtonTitleFont]];
    [confirmSlotBtn setTitleColor:[self.theme getCalendarConfirmButtonTitleColor] forState:UIControlStateNormal];
    [confirmSlotBtn setTitle:HLLocalizedString(LOC_CALENDAR_INVITE_CONFIRM_BTN) forState:UIControlStateNormal];
    confirmSlotBtn.backgroundColor = [self.theme getCalendarConfirmButtonBackgroundColor];
    [confirmSlotBtn addTarget:self action:@selector(sendCalendarConfirmationMsg:) forControlEvents:UIControlEventTouchUpInside];
    [self.innerContainerView addSubview:confirmSlotBtn];
    [views setObject:confirmSlotBtn forKey:@"confirmSlot"];
    
    UIButton *changeSlotBtn = [[UIButton alloc] init];
    changeSlotBtn.userInteractionEnabled = YES;
    changeSlotBtn.translatesAutoresizingMaskIntoConstraints = NO;
    changeSlotBtn.layer.borderWidth = 1.0f;
    changeSlotBtn.layer.cornerRadius = 4;
    changeSlotBtn.layer.borderColor = [self.theme getCalendarConfirmChangeSlotButtonBorderColor].CGColor;
    [changeSlotBtn.titleLabel setFont:[self.theme getCalendarConfirmChangeSlotButtonTitleFont]];
    [changeSlotBtn setTitleColor:[self.theme getCalendarConfirmChangeSlotButtonTitleColor] forState:UIControlStateNormal];
    [changeSlotBtn setTitle:HLLocalizedString(LOC_CALENDAR_INVITE_CHANGE_SLOT_BTN) forState:UIControlStateNormal];
    changeSlotBtn.backgroundColor = [self.theme getCalendarConfirmChangeSlotButtonBackgroundColor];
    changeSlotBtn.tag = 4;
    [changeSlotBtn addTarget:self action:@selector(editedSelectedCalendarSlot:) forControlEvents:UIControlEventTouchUpInside];
    [self.innerContainerView addSubview:changeSlotBtn];
    [views setObject:changeSlotBtn forKey:@"changeSlot"];
    
    NSDictionary *metrics = @{@"viewHt" : @(FC_VIEW_HEIGHT*0.90)};
    
    [self.confirmSlotView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[innerContainer]" options:0 metrics:nil views:views]];
    [self.confirmSlotView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[innerContainer]|" options:0 metrics:nil views:views]];
    
    [self.confirmSlotView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[divider]|" options:0 metrics:nil views:views]];
    
    [self.confirmSlotView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-navBarHt-[divider(dividerHt)]" options:0 metrics:self.metrics views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|" options:0 metrics:nil views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[invitationContainer]|" options:0 metrics:nil views:views]];
    
    [invitationContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[confirmation]|" options:0 metrics:nil views:views]];
    [invitationContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[confirmation]|" options:0 metrics:nil views:views]];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[confirmSlot(btnWidth)]" options:0 metrics:self.metrics views:views]];
    [FCAutolayoutHelper centerX:confirmSlotBtn onView:self.innerContainerView];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[changeSlot(btnWidth)]" options:0 metrics:self.metrics views:views]];
    [FCAutolayoutHelper centerX:changeSlotBtn onView:self.innerContainerView];
    
    [self.innerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar(navBarHt)]-2-[invitationContainer][confirmSlot(btnHeight)]-padding-[changeSlot(btnHeight)]-bottomPadding-|" options:0 metrics:self.metrics views:views]];
    
    [FCAutolayoutHelper centerX:self.innerContainerView onView:self.confirmSlotView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[confirmSlotView(>=0)]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[confirmSlotView]|" options:0 metrics:nil views:views]];
    
    self.viewHtConstraint = [FCAutolayoutHelper setHeight:[[metrics objectForKey:@"viewHt"] floatValue] forView:self.confirmSlotView inView:self.view];
    
    self.innerContainerWidth = [FCAutolayoutHelper setWidth:(FC_VIEW_WIDTH - (2 *[self layoutPadding])) forView:self.innerContainerView inView:self.confirmSlotView];
}

- (CGFloat) layoutPadding {
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [FCUtilities getAppKeyWindow];
        if(!window) {
            return 0;
        }
        return window.safeAreaInsets.left;
    }
    return 0;
}

-(void)orientationChange :(NSNotification*)notification {
    
    [self.view endEditing:YES];
    CGSize deviceSize = [[UIScreen mainScreen] bounds].size;
    if (deviceSize.height > deviceSize.width) { //potrait
        if ((self.calendarState == LimitedSlotsView) && ([self.selectedSlot count]==0)) {
            self.viewHtConstraint.constant = FC_VIEW_HEIGHT*0.6;
        }else {
            self.viewHtConstraint.constant = FC_VIEW_HEIGHT*0.9;
        }
        self.innerContainerWidth.constant = MIN(FC_VIEW_WIDTH, FC_VIEW_HEIGHT);
    }else {
        self.viewHtConstraint.constant = FC_VIEW_HEIGHT*0.9;
        self.innerContainerWidth.constant = MAX(FC_VIEW_WIDTH, FC_VIEW_HEIGHT)- (2 *[self layoutPadding]);
    }
}


- (void) closeClick:(id)sender{
    [self.view endEditing:YES];
    
    UIAlertController * alert = [UIAlertController
                                  alertControllerWithTitle:HLLocalizedString(LOC_CALENDAR_ALERT_CANCEL_TITLE)
                                  message:HLLocalizedString(LOC_CALENDAR_CANCEL_ALERT_DESCRIPTION)
                                  preferredStyle:UIAlertControllerStyleAlert];
     
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:HLLocalizedString(LOC_CALENDAR_CANCEL_ALERT_CONTINUE_BTN)
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action){
                            [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:HLLocalizedString(LOC_CALENDAR_CANCEL_ALERT_BOOKING_BTN)
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action){
        [FCMessageUtil cancelCalendarInviteForMsg:self.message andConv:self.conversation];
                                [alert dismissViewControllerAnimated:YES completion:nil];
        
                                [self dismissModalViewControllerAnimated:YES];
        
                            }];
    [alert addAction:ok];
    [alert addAction:cancel];
     
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) showSlotsClick:(id)sender{
    [self.emptySlotsErrorView removeFromSuperview];
    [FCUserDefaults setString:self.userEmailField.text forKey: FRESHCHAT_DEFAULTS_CALENDAR_INVITE_EMAILID];
    if(self.showMoreSlotsBtn.tag == 0){
        [self showCalendarSlotsView:sender];
    }
    [self.activityIndicator startAnimating];
    
    NSDictionary *jsonDict = [FCMessageUtil getInternalMetaForData:self.message.internalMeta];
    [FCCoreServices fetchAvilCalendarSlotsForAgent:[jsonDict valueForKeyPath:@"calendarMessageMeta.calendarAgentAlias"] :^(NSDictionary *slotsInfo, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            [self.showMoreSlotsBtn setHidden:false];
            if (!error){
                if ([[slotsInfo valueForKey:@"calendarTimeSlots"] firstObject] == nil || !([[FCCalendarModel alloc]initWith:slotsInfo].timeSlots.count)) // best in performance
                {
                    // The array is empty
                    [self addCalendarEvent:FCEventCalendarNoTimeSlotFound];
                    self.showMoreSlotsBtn.tag = 1; //tag for Cancel
                    [self showEmptyErrorSlotsWithStatus : self.showMoreSlotsBtn.tag];
                    [self.showMoreSlotsBtn setTitle:HLLocalizedString(LOC_CALENDAR_SLOTS_CANCEL_BTN) forState:UIControlStateNormal];
                }else{
                    self.slotsResponseDict = slotsInfo;
                    self.showMoreSlotsBtn.tag = 0;
                    self.duration = [FCUtilities getDurationFromSecs:[[slotsInfo valueForKey:@"meetingLength"] intValue]];
                    self.durationLabel.text = self.duration;
                    [self.showMoreSlotsBtn setTitle:HLLocalizedString(LOC_CALENDAR_SLOTS_SHOW_MORE_BTN) forState:UIControlStateNormal];
                    [self updateViewWithSlots:slotsInfo];
                }
                
            }else {
                self.showMoreSlotsBtn.tag = 2; //tag for retry
                [self showEmptyErrorSlotsWithStatus : self.showMoreSlotsBtn.tag];
            }
        });
    }];
}

- (void) updateViewWithSlots : (NSDictionary *) slotsInfo {
    [self.showMoreSlotsBtn setHidden:(self.calendarState == AllSlotsView)];
    self.calendarController = [[FCCalendarTableViewController alloc]init];
    self.calendarController.view.frame = CGRectMake(0, 0, self.slotsView.frame.size.width, self.slotsView.frame.size.height);
    [self addChildViewController:self.calendarController];
    FCCalendarModel *model = [[FCCalendarModel alloc]initWith:slotsInfo];
    [self.calendarController changeSource:[FCDateUtil getSlotsFromCalendar:model]];
    [self.slotsView addSubview:self.calendarController.view];
    [self.calendarController didMoveToParentViewController:self];
}

- (void) showEmptyErrorSlotsWithStatus : (NSInteger) statusTag {
    if (statusTag == 1){
        [self.showMoreSlotsBtn setTitle:HLLocalizedString(LOC_CALENDAR_SLOTS_CANCEL_BTN) forState:UIControlStateNormal];
        [self addNoSlotsOrErrorViewWithText:HLLocalizedString(LOC_CALENDAR_NO_SLOTS_AVAILABLE_TEXT) withImage:NO];
    }else if (statusTag == 2){
        [self.showMoreSlotsBtn setTitle:HLLocalizedString(LOC_CALENDAR_SLOTS_RETRY_BTN) forState:UIControlStateNormal];
        [self addNoSlotsOrErrorViewWithText:HLLocalizedString(LOC_CALENDAR_SLOTS_ERROR) withImage:YES];
    }
}

- (void) addNoSlotsOrErrorViewWithText : (NSString *) displayText withImage : (BOOL) showImage {
    
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    
    self.emptySlotsErrorView = [[UIView alloc] init];
    self.emptySlotsErrorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.slotsView addSubview:self.emptySlotsErrorView];
    
    UILabel *displayMsgLbl = [[UILabel alloc]init];
    displayMsgLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [displayMsgLbl setBackgroundColor:[UIColor clearColor]];
    [displayMsgLbl setFont:[self.theme getCalendarSlotsStateDescTextFont]];
    [displayMsgLbl setTextColor:[self.theme getCalendarSlotsStateDescTextColor]];
    displayMsgLbl.numberOfLines = 1;
    [self.emptySlotsErrorView addSubview:displayMsgLbl];
    displayMsgLbl.text = displayText;
    [views setObject:displayMsgLbl forKey:@"displayMsg"];
    
    if(showImage) {
        UIImageView *errorImageView = [[UIImageView alloc] init];
        errorImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [errorImageView setContentMode:UIViewContentModeScaleAspectFit];
        errorImageView.image = [[FCTheme sharedInstance]
                                getImageWithKey:IMAGE_CALENDAR_ERROR_ICON];
        [self.emptySlotsErrorView addSubview:errorImageView];
        [views setObject:errorImageView forKey:@"errorImage"];
        [self.emptySlotsErrorView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[errorImage(50)]" options:0 metrics:nil views:views]];
        [FCAutolayoutHelper centerX:errorImageView onView:self.emptySlotsErrorView];
        [self.emptySlotsErrorView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[errorImage(50)]-20-[displayMsg(20)]|" options:0 metrics:nil views:views]];
    } else {
        [self.emptySlotsErrorView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[displayMsg(20)]|" options:0 metrics:nil views:views]];
    }
    
    [self.emptySlotsErrorView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[displayMsg]|" options:0 metrics:nil views:views]];
        
    [FCAutolayoutHelper centerX:self.emptySlotsErrorView onView:self.slotsView];
    [FCAutolayoutHelper centerY:self.emptySlotsErrorView onView:self.slotsView];
}

- (void) showMoreSlotsClick:(id)sender {
    if(self.showMoreSlotsBtn.tag == 1){
        //cancel
        [FCMessageUtil cancelCalendarInviteForMsg:self.message andConv:self.conversation];
        [self dismissModalViewControllerAnimated:YES];
    }else if(self.showMoreSlotsBtn.tag == 2){
        //retry and call API again
        [self showSlotsClick:sender];
    }else{
        self.calendarState = AllSlotsView;
        self.showMoreBtnHtConstraint.constant = 0;
        self.viewHtConstraint.constant = FC_VIEW_HEIGHT*0.9;
        [self.calendarController showFullDays:true];
    }
}

-(void) selectSlotWithInfo:(NSNotification *) notification {
    self.selectedSlot = [notification.userInfo mutableCopy];
    //Table cell click only if when values are available, so not adding key check
    self.selectedSlot[@"endMillis"] = @([self getMeetingEndMillisForStartTime  :[self.selectedSlot objectForKey:@"startMillis"]]);
    self.selectedSlot[@"calendarAgentAlias"] = self.message.messageUserAlias;
    [self showConfirmSlotView:nil];
}

- (long) getMeetingEndMillisForStartTime :(NSNumber *) startTime{
    return ([startTime longLongValue] + ([[self.slotsResponseDict objectForKey:@"meetingLength"] longLongValue] * 1000));
}

- (void) sendCalendarConfirmationMsg :(id)sender {
    [FCMessageUtil sendCalendarInviteForMsg:self.message withSlotInfo:self.selectedSlot andConv:self.conversation];
    [self dismissModalViewControllerAnimated:YES];
}

- (void) editedSelectedCalendarSlot :(id)sender {
    self.selectedSlot = nil;
    [self.confirmSlotView removeFromSuperview];
    [self showCalendarSlotsView:sender];
    [self updateViewWithSlots:self.slotsResponseDict];
    [self.calendarController showFullDays:(self.calendarState == AllSlotsView)];
}

#pragma mark Keyboard delegate

-(void) keyboardWillShow:(NSNotification *)notification {
    if(CGRectIsNull(self.viewFrame) || self.keyboardHeight == 0) {
        self.viewFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, FC_VIEW_WIDTH
                                    , FC_VIEW_HEIGHT);
    }
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    self.keyboardHeight = keyboardRect.size.height;
    self.view.frame = CGRectMake(self.view.frame.origin.x , (self.viewFrame.origin.y - self.keyboardHeight), FC_VIEW_WIDTH, FC_VIEW_HEIGHT);
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self validateUserEmail:textField.text];
}

-(void) validateUserEmail : (NSString*) email {
    if ([FCStringUtil isNotEmptyString:email]) {
        [self enableShowSlotsBtn:[FCStringUtil isValidEmail:email]];
    }
}

- (void) enableShowSlotsBtn : (BOOL) state {
    self.showSlotsBtn.userInteractionEnabled = state;
    self.showSlotsBtn.alpha = state ? 1.0 : 0.6;
}

-(void) keyboardWillHide:(NSNotification *)notification {
    self.view.frame = CGRectMake(self.view.frame.origin.x , self.viewFrame.origin.y, FC_VIEW_WIDTH, FC_VIEW_HEIGHT);
    self.keyboardHeight = 0;
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRESHCHAT_CALENDAR_SLOT_SELECTED object:nil];
}

@end
