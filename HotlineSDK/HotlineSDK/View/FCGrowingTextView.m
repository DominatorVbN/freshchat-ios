//
//  FDGrowingTextView.m
//  HotlineSDK
//
//  Created by user on 14/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCGrowingTextView.h"
#import "FCMacros.h"
#import "FCTheme.h"
#define CSAT_INPUTTEXT_PADDING 5

@interface FCGrowingTextView ()

@property (nonatomic, retain) UILabel *placeHolderLabel;

@end

@implementation FCGrowingTextView

- (id)initWithFrame:(CGRect)frame{
    if( (self = [super initWithFrame:frame]) ){
        [self setPlaceholder:@""];
        self.textContainerInset = UIEdgeInsetsMake(CSAT_INPUTTEXT_PADDING, 0, CSAT_INPUTTEXT_PADDING, 0);
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)textChanged:(NSNotification *)notification{
    if([[self placeholder] length] == 0){
        return;
    }
    
    if([[self text] length] == 0){
        self.placeHolderLabel.alpha = 1;
    }else{
        self.placeHolderLabel.alpha = 0;
    }
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textChanged:nil];
}

- (void)drawRect:(CGRect)rect{
    if( [[self placeholder] length] > 0 ){
        if (_placeHolderLabel == nil ){
            _placeHolderLabel = [[UILabel alloc] init];
            _placeHolderLabel.translatesAutoresizingMaskIntoConstraints = NO;
            NSMutableDictionary *views = [NSMutableDictionary
                                          dictionaryWithDictionary:@{@"placeHolderView" : _placeHolderLabel}];
            _placeHolderLabel.font = [[FCTheme sharedInstance] csatPromptInputTextFont];
            _placeHolderLabel.numberOfLines = 0;
            _placeHolderLabel.backgroundColor = [UIColor clearColor];
            _placeHolderLabel.textColor = self.placeholderColor;
            _placeHolderLabel.alpha = 0;
            
            NSDictionary *metrics = @{@"width" : @(self.frame.size.width-10),
                                      @"padding" : @(CSAT_INPUTTEXT_PADDING)
            };
        
            [self addSubview:_placeHolderLabel];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[placeHolderView(==width)]-padding-|" options:0 metrics:metrics views:views]];
            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-padding-[placeHolderView]-padding-|" options:0 metrics:metrics views:views]];
        }
        
        _placeHolderLabel.text = self.placeholder;
        [self sendSubviewToBack:_placeHolderLabel];
    }
    
    if( [[self text] length] == 0 && [[self placeholder] length] > 0 ){
        _placeHolderLabel.alpha = 1;
    }
    [super drawRect:rect];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
}

@end
