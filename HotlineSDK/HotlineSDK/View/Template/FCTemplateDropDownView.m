//
//  FCTemplateDropDownView.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 30/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCTemplateDropDownView.h"
#import "FCAutolayoutHelper.h"
#import "FCLocalization.h"
#import "FCEventsHelper.h"
#import "FCTheme.h"



@interface  FCTemplateDropDownView() <UIPickerViewDelegate, UIPickerViewDataSource> {
    bool showingPicker;
}
@property(nonatomic, strong) UIPickerView *pickerView;
@property(nonatomic, strong) UIToolbar *toolBar;
@property(nonatomic, strong) UIView *selectionView;
@property(nonatomic, strong) FCTheme* theme;
@end

@implementation FCTemplateDropDownView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.theme = [FCTheme sharedInstance];
        self.selectionView = [[UIView alloc] initWithFrame:CGRectZero];
        self.selectionView.backgroundColor = UIColor.whiteColor;
        self.selectionView.translatesAutoresizingMaskIntoConstraints = NO;
        UILabel *selectionLabel = [[UILabel alloc]init];
        selectionLabel.accessibilityIdentifier = @"FCDropDownBarSelectLabel";
        selectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        selectionLabel.text = HLLocalizedString(LOC_DROPDOWN_SELECT);
        selectionLabel.font = [self.theme getDropDownBarFont];
        [self.selectionView addSubview:selectionLabel];
        UIImageView *dropDownImageView = [[UIImageView alloc]init];
        dropDownImageView.accessibilityIdentifier = @"FCDropDownBarImageView";
        [dropDownImageView setContentMode:UIViewContentModeScaleAspectFit];
        [dropDownImageView setImage:[[FCTheme sharedInstance] getImageValueWithKey:IMAGE_DROPDOWN_ICON]];
        dropDownImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.selectionView addSubview:dropDownImageView];
        
        self.selectionView.layer.borderWidth = 1;
        self.selectionView.layer.borderColor = [self.theme getDropDownBarBorderColor].CGColor;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(addPickerView)];
        tap.numberOfTapsRequired = 1;
        [self.selectionView addGestureRecognizer: tap];
        
        NSDictionary *views = @{ @"selectionLabel" : selectionLabel,
                                 @"imageView"      : dropDownImageView};
        [self.selectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[selectionLabel]|" options:0 metrics:nil views:views]];
        [self.selectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[selectionLabel]-5-[imageView]-8@500-|" options:0 metrics:nil views:views]];
        [FCAutolayoutHelper centerY:dropDownImageView onView:self.selectionView];
        [self addSelectionView];
        
        self.pickerView = [[UIPickerView alloc] init];
        self.pickerView.accessibilityIdentifier = @"FCDropDownPickerView";
        self.pickerView.dataSource = self;
        self.pickerView.delegate = self;
        self.pickerView.backgroundColor = [UIColor whiteColor];
        [self.pickerView selectRow:0 inComponent:0 animated:YES];
        
        self.toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 44)];
        self.toolBar.barStyle = UIBarStyleDefault;

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
        doneButton.accessibilityIdentifier = @"FCDropDownDoneButton";
        
        UIBarButtonItem *spaceButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
         UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
        cancelButton.accessibilityIdentifier = @"FCDropDownCancelButton";
        

        [self.toolBar setItems:[NSArray arrayWithObjects:cancelButton, spaceButton,doneButton, nil]];
        
        self.toolBar.translatesAutoresizingMaskIntoConstraints = false;
        self.toolBar.translucent = false;
        self.toolBar.backgroundColor = [UIColor whiteColor];
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.pickerView.translatesAutoresizingMaskIntoConstraints = false;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.dropDownViewModel.options.count;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel* label = (UILabel*)view;
    if (!label){
        label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, pickerView.frame.size.width - 10, CGFLOAT_MAX)];
        label.numberOfLines = 2;
        label.text = self.dropDownViewModel.options[row].label;
        label.font = [self.theme getDropDownPickerOptionFont];
    }
    [label sizeToFit];
    return label;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return [self.theme getDropDownPickerOptionHeight];
}

- (void)doneButtonPressed {
    FCDropDownModel *model = self.dropDownViewModel.options[(int)[self.pickerView selectedRowInComponent:0]];
    NSDictionary *eventDict = @{@(FCPropertyOption): model.fragmentContent};
    FCOutboundEvent *outEvent = [[FCOutboundEvent alloc] initOutboundEvent:FCEventDropDownSelect
                                                                withParams:eventDict];
    [FCEventsHelper postNotificationForEvent:outEvent];
    [self.delegate dismissAndSendFragment:@[model.fragmentContent] inReplyTo:self.dropDownViewModel.replyMessageId];
}

- (void)cancelButtonPressed {
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self addSelectionView];
}

- (void)addPickerView {
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    showingPicker = true;
    [self addSubview:self.pickerView];
    [self addSubview:self.toolBar];
    NSDictionary *views = @{ @"picker" : self.pickerView, @"toolbar": self.toolBar};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[toolbar(44)]-[picker]|" options:0 metrics:nil views:views]];
    if (@available(iOS 11.0, *)) {
        UILayoutGuide *guide = self.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[[self.pickerView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor], [self.pickerView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor]]];
        [NSLayoutConstraint activateConstraints:@[[self.toolBar.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor], [self.toolBar.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor]]];
    } else {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[picker]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolbar]|" options:0 metrics:nil views:views]];
    }
    
    [self orientationChange];
}

-(void)addSelectionView {
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    showingPicker = false;
    [self addSubview:self.selectionView];
    NSDictionary *views = @{ @"selectionView" : self.selectionView};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[selectionView]-2-|" options:0 metrics:nil views:views]];
    if (@available(iOS 11.0, *)) {
        UILayoutGuide *guide = self.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[[self.selectionView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:0.5], [self.selectionView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-0.5]]];
    } else {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0.5-[selectionView]-0.5-|" options:0 metrics:nil views:views]];
    }
    [self.delegate updateHeightConstraint:50];
}

- (void)postOutboundEvent {
    FCOutboundEvent *outEvent = [[FCOutboundEvent alloc] initOutboundEvent:FCEventDropDownReceive
                                                                withParams:@{}];
    [FCEventsHelper postNotificationForEvent:outEvent];
}


-(void)orientationChange {
    if (showingPicker) {
        float viewHeight = ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait ? [self.theme getDropDownPickerViewPortraitHeight] : [self.theme getDropDownPickerViewLandScapeHeight]) + 44;
        
        [self.delegate updateHeightConstraint: viewHeight];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

@end
