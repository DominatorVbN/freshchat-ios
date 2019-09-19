//
//  FDAttachmentImageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCAttachmentImageController.h"
#import "FCInputToolbarView.h"
#import "FCMessageHelper.h"
#import "FCBarButtonItem.h"
#import "FCTheme.h"
#import "FCLocalization.h"
#import "FCAutolayoutHelper.h"
#import "FCLocalNotification.h"
#import "FCUtilities.h"
#import "FCFooterView.h"

@interface FCAttachmentImageController (){
    int footerViewHeight;
}

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) FCInputToolbarView *inputToolbar;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGRect viewFrame;
@end

@implementation FCAttachmentImageController

-(instancetype)initWithImage:(UIImage *)image{
    self = [super init];
    if (self) {
        self.image = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationItem];
    self.navigationItem.title = HLLocalizedString(LOC_PIC_MSG_ATTACHMENT_TITLE_TEXT);
    self.view.backgroundColor = [UIColor whiteColor];
    self.imageView = [[UIImageView alloc]initWithImage:self.image];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.keyboardHeight = 0;
    self.viewFrame = CGRectNull;
    self.inputToolbar = [[FCInputToolbarView alloc]initWithDelegate:self];
    self.inputToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputToolbar.isFromAttachmentScreen = YES;
    [self.inputToolbar setSendButtonEnabled:YES];
    [self setHeightForTextView:self.inputToolbar.textView];
    [self.inputToolbar prepareView];
    
    FCFooterView *footerView = [[FCFooterView alloc] initFooterViewWithEmbedded:false];
    footerView.translatesAutoresizingMaskIntoConstraints = false;
    
    [footerView setViewColor: [[FCTheme sharedInstance] inputToolbarBackgroundColor]];
    
    [self.view addSubview:self.inputToolbar];
    [self.view addSubview:self.imageView];
    [self.view addSubview:footerView];
    CGFloat messageHeight = [self.inputToolbar.textView sizeThatFits:CGSizeMake(self.inputToolbar.textView.frame.size.width, CGFLOAT_MAX)].height;
    
    NSDictionary *views = @{ @"imageView"        : self.imageView,
                             @"inputToolbar"     : self.inputToolbar,
                             @"footerView"       : footerView
                             };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView]-10-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[inputToolbar]-0-|" options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[footerView]-0-|" options:0 metrics:nil views:views]];
    footerViewHeight = 20;
    if([FCUtilities hasNotchDisplay]){
        footerViewHeight = 33;
    }
    if([FCUtilities isPoweredByFooterViewHidden] && ![FCUtilities hasNotchDisplay]){
        footerViewHeight = 0;
    }
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-10-[imageView(>=0)]-10-[inputToolbar(==%d)][footerView(%d)]-0-|",(int)messageHeight + 10, footerViewHeight]  options:0 metrics:nil views:views]];
    
    [self localNotificationSubscription];
}

-(void)inputToolbar:(FCInputToolbarView *)toolbar attachmentButtonPressed:(id)sender {
    
}
-(void)inputToolbar:(FCInputToolbarView *)toolbar sendButtonPressed:(id)sender {
    [self sendMessage];
}
-(void)inputToolbar:(FCInputToolbarView *)toolbar micButtonPressed:(id)sender {
    
}

-(void)inputToolbar:(FCInputToolbarView *)toolbar textViewDidChange:(UITextView *)textView{
    //[self setHeightForTextView:textView];
}

-(void)setHeightForTextView:(UITextView *)textView{
    CGFloat NUM_OF_LINES = 1;
    CGFloat MAX_HEIGHT = textView.font.lineHeight * NUM_OF_LINES;
    CGFloat preferredTextViewHeight = 0;
    CGFloat messageHeight = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, CGFLOAT_MAX)].height;
    if(messageHeight > MAX_HEIGHT)
    {
        preferredTextViewHeight = MAX_HEIGHT;
        textView.scrollEnabled=YES;
    }
    else{
        preferredTextViewHeight = messageHeight;
        textView.scrollEnabled=NO;
    }
    self.inputToolbar.textViewHt = messageHeight;
    textView.frame=CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, preferredTextViewHeight);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)localNotificationSubscription {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self localNotificationUnSubscription];
}

-(void)localNotificationUnSubscription {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];// this will do the trick
}


-(void)setNavigationItem{
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [[FCTheme sharedInstance] imgAttachBackButtonFontColor];
    
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [[FCTheme sharedInstance] navigationBarTitleColor],
                                                                    NSFontAttributeName: [[FCTheme sharedInstance] navigationBarTitleFont]
                                                                    };

    FCBarButtonItem *backButton;
    UIImage *closeImage = [[FCTheme sharedInstance] getImageWithKey:IMAGE_SOLUTION_CLOSE_BUTTON];
    if (closeImage) {
        backButton = [FCUtilities getCloseBarBtnItemforCtr:self withSelector:@selector(dismissPresentedView)];
    }
    else {
        backButton = [[FCBarButtonItem alloc] initWithTitle:HLLocalizedString(LOC_PIC_MSG_ATTACHMENT_CLOSE_BTN) style:UIBarButtonItemStylePlain target:self action:@selector(dismissPresentedView)];
        
        [backButton setTitleTextAttributes:@{
                                             NSFontAttributeName :[[FCTheme sharedInstance] imgAttachBackButtonFont],
                                             NSForegroundColorAttributeName :[[FCTheme sharedInstance] imgAttachBackButtonFontColor]
                                             } forState:UIControlStateNormal];
    }
    self.navigationItem.leftBarButtonItem = backButton;
}

-(void)sendMessage {
    [self dismissPresentedView];
    if(self.delegate){
        NSCharacterSet *trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *toSend = [self.inputToolbar.textView.text stringByTrimmingCharactersInSet:trimChars];
        if (([toSend isEqualToString:@""]) || ([toSend isEqualToString:HLLocalizedString(LOC_MESSAGE_PLACEHOLDER_TEXT)])) {
            toSend = @"";
        }
        [self.delegate attachmentController:self didFinishSelectingImage:self.image withCaption:toSend];
    }
}

- (void) dismissPresentedView {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark Orientation Change delegate


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}


#pragma mark Keyboard delegate

-(void) keyboardWillShow:(NSNotification *)notification {
    if(CGRectIsNull(self.viewFrame) || self.keyboardHeight == 0) {
        self.viewFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    }
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    self.keyboardHeight = keyboardRect.size.height;
    self.view.frame = CGRectMake(self.view.frame.origin.x , (self.viewFrame.origin.y - self.keyboardHeight)+footerViewHeight, self.view.frame.size.width, self.view.frame.size.height);
}

-(void) keyboardWillHide:(NSNotification *)notification {
    self.view.frame = CGRectMake(self.view.frame.origin.x , self.viewFrame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    self.keyboardHeight = 0;
}

-(void)dealloc{
    self.inputToolbar.delegate = nil;
}


@end

