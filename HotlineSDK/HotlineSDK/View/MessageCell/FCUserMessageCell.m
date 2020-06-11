//
//  HLUserMessageCell.m
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCUserMessageCell.h"
#import "FCUtilities.h"
#import "FCTheme.h"
#import "FCLocalization.h"
#import "FCSecureStore.h"

#import "FCDeeplinkFragment.h"
#import "FCHtmlFragment.h"
#import "FCImageFragment.h"
#import "FCVideoFragment.h"
#import "FCAudioFragment.h"
#import "FCFileFragment.h"
#import "FCDateUtil.h"
#import "FCUnsupportedFragment.h"
#import "FCCarouselCard.h"
#import "FCConstants.h"
#import "FCCalendarInvitationFragment.h"

@interface  FCUserMessageCell()

@property (nonatomic, assign) NSInteger maxContentWidth;

@end

@implementation FCUserMessageCell

@synthesize messageSentTimeLabel,contentEncloser,maxContentWidth,customFontName,
            showsTimeStamp,showsUploadStatus,sentImage,sendingImage,
            chatBubbleImageView,uploadStatusImageView,
            senderNameLabel,messageTextFont;

@synthesize userChatBubble,userChatBubbleInsets;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<HLMessageCellDelegate>)delegate{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        self.delegate = delegate;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self initCell];
    }
    return self;
}

- (void) initCell{
    self.sentImage=[[FCTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENT_ICON];
    self.sendingImage=[[FCTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENDING_ICON];
    //self.customFontName=[[FCTheme sharedInstance] userMessageFont];
    self.showsUploadStatus=YES;
    self.showsTimeStamp=YES;
    self.chatBubbleImageView=[[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
    self.senderNameLabel=[[UITextView alloc] initWithFrame:CGRectZero];
    
    [senderNameLabel setFont:[[FCTheme sharedInstance] agentNameFont]];
    [senderNameLabel setBackgroundColor:[UIColor clearColor]];
    [senderNameLabel setTextAlignment:NSTextAlignmentLeft];
    senderNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    senderNameLabel.textColor = [[FCTheme sharedInstance] agentNameFontColor];
    [senderNameLabel setEditable:NO];
    [senderNameLabel setScrollEnabled:NO];
    [senderNameLabel setSelectable:NO];
    
    messageSentTimeLabel=[[UILabel alloc] initWithFrame:CGRectZero];
    messageSentTimeLabel.textColor = [[FCTheme sharedInstance] getUserMessageTimeFontColor];
    [messageSentTimeLabel setFont:[[FCTheme sharedInstance] getUserMessageTimeFont]];
    [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
    [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
    messageSentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    chatBubbleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    chatBubbleImageView.clipsToBounds = YES;
    
    uploadStatusImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
    [uploadStatusImageView setImage:sentImage];
    uploadStatusImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setClipsToBounds:YES];
    
    userChatBubble = [[FCTheme sharedInstance]getImageValueWithKey:IMAGE_BUBBLE_CELL_RIGHT];
    userChatBubbleInsets= [[FCTheme sharedInstance] getUserBubbleInsets];
    
}


- (void) drawMessageViewForMessage:(FCMessageData*)currentMessage parentView:(UIView*)parentView {
    
    [self clearAllSubviews];
    maxContentWidth = (NSInteger) self.messageViewBounds.size.width - ((self.messageViewBounds.size.width/100)*20);
    contentEncloser = [[UIView alloc] init];
    contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    [contentEncloser setLayoutMargins:UIEdgeInsetsMake(0,0,0,0)];
    [self.contentView addSubview:contentEncloser];
    FCTheme *theme = [FCTheme sharedInstance];
    NSString *topPadding = [theme userMessageTopPadding] ? [theme userMessageTopPadding] : @"10";
    NSString *bottomPadding = [theme userMessageBottomPadding] ? [theme userMessageBottomPadding] : @"10";
    NSString *leftPadding = [theme userMessageLeftPadding] ? [theme userMessageLeftPadding] : @"10";
    NSString *rightPadding = [theme userMessageRightPadding] ? [theme userMessageRightPadding] : @"10";
    NSString *internalPadding = @"5";
    
    NSMutableArray *fragmensViewArr = [[NSMutableArray alloc]init];
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
    
    messageSentTimeLabel.text = [FCDateUtil stringRepresentationForDate:date];
    [chatBubbleImageView setImage:[userChatBubble resizableImageWithCapInsets:userChatBubbleInsets]];
    if([currentMessage uploadStatus].integerValue==2)  {
        [uploadStatusImageView setImage:sentImage];
    }
    else {
        [uploadStatusImageView setImage:sendingImage];
    }
    
    [views setObject:uploadStatusImageView forKey:@"uploadStatusImageView"];
    [views setObject:self.contentEncloser forKey:@"contentEncloser"];
    [views setObject:self.chatBubbleImageView forKey:@"chatBubbleImageView"];
    [views setObject:messageSentTimeLabel forKey:@"messageSentTimeLabel"];
    [contentEncloser addSubview:chatBubbleImageView];
    [contentEncloser addSubview:uploadStatusImageView];
    [contentEncloser addSubview:messageSentTimeLabel];
    [self.contentView addSubview:contentEncloser];
    
    
    [self.chatBubbleImageView setHidden:NO];
    for(int i=0; i<currentMessage.fragments.count; i++) {
        FragmentData *fragment = currentMessage.fragments[i];
        if ([fragment.type isEqualToString:@"1"] || [fragment.type isEqualToString: [@(FRESHCHAT_QUICK_REPLY_FRAGMENT) stringValue]]) {
            //HTML
            FCHtmlFragment *htmlFragment = [[FCHtmlFragment alloc]initFragment:fragment withFont:[[FCTheme sharedInstance] userMessageFont] andType:2];
            if([currentMessage.messageType isEqualToNumber:FC_CALENDAR_CANCEL_MSG]){
                htmlFragment.attributedText = [self appendImage:[[FCTheme sharedInstance] getImageWithKey:IMAGE_CALENDAR_CANCELLED_ICON] withText: htmlFragment.attributedText];
            }
            htmlFragment.mcDelegate = self.delegate;
            [views setObject:htmlFragment forKey:[@"text_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:htmlFragment];
            [fragmensViewArr addObject:[@"text_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"HTML");
        } else if([fragment.type isEqualToString:@"2"]) {
            //IMAGE
            FCImageFragment *imageFragment = [[FCImageFragment alloc]initWithFragment:fragment ofMessage:currentMessage];
            imageFragment.delegate = self.delegate;
            [views setObject:imageFragment forKey:[@"image_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:imageFragment];
            [fragmensViewArr addObject:[@"image_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"IMAGE");
        } else if([fragment.type isEqualToString:@"5"] ) {
            FCDeeplinkFragment *fileFragment = [[FCDeeplinkFragment alloc] initWithFragment:fragment];
            [views setObject:fileFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:fileFragment];
            fileFragment.delegate = self.delegate;
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"Button");
        }else if([fragment.type isEqualToString:@"7"]) {
            //calender confirmation fragment
            FCCalendarInvitationFragment *invitationFragment = [[FCCalendarInvitationFragment alloc] initWithFragment:fragment uploadStatus: [currentMessage uploadStatus].integerValue==2 andInternalMeta:currentMessage.internalMeta];
            [views setObject:invitationFragment forKey:@"calendarInvitationView"];
            [contentEncloser addSubview:invitationFragment];
            [fragmensViewArr addObject:@"calendarInvitationView"];
            [self.chatBubbleImageView setHidden:YES];
        } else if ([fragment.type integerValue] == FRESHCHAT_TEMPLATE_FRAGMENT) {
            TemplateFragmentData *templateFragment = [[TemplateFragmentData alloc]initWith:fragment.dictionaryValue];
            FCCarouselCard *carouselFragment = [[FCCarouselCard alloc] initWithTemplateFragmentData:templateFragment isCardSelected:YES inReplyTo:currentMessage.messageId withDelegate:nil];
            [views setObject:carouselFragment forKey:[@"carousel_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:carouselFragment];
            [fragmensViewArr addObject:[@"carousel_" stringByAppendingFormat:@"%d",i]];            
            [self.chatBubbleImageView setHidden:YES];
        } else {
            //For Unknown fragment
            FCUnsupportedFragment *unknownFragment = [[FCUnsupportedFragment alloc] initWithFragment:fragment];
            [views setObject:unknownFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:unknownFragment];
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
        }
    }
    
    //All details are in contentview but no constrains set
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[contentEncloser(<=%ld)]-8-|",(long)self.maxContentWidth] options:0 metrics:nil views: views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[contentEncloser(>=50)]-2-|" options:0 metrics:nil views:views]];
    //Constraints for profileview and contentEncloser are done.
    
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    //Constraints for chatbubble are done.
    

    NSMutableString *veriticalConstraint = [[NSMutableString alloc]initWithString:@"V:|"];
    for(int i=0;i<fragmensViewArr.count;i++) { //Set Constraints here
        NSString *str = fragmensViewArr[i];
        if([str containsString:@"image_"]) {
            FCImageFragment *imageFragment = views[str];
            NSString *imageHeight = [NSString stringWithFormat:@"%d",(int)imageFragment.imgFrame.size.height];
            NSString *imageWidth = [NSString stringWithFormat:@"%d",(int)imageFragment.imgFrame.size.width];
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-(>=%@)-[%@(%@)]-(>=%@)-|",leftPadding,str,imageWidth,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:imageFragment
                                                                                attribute:NSLayoutAttributeCenterX
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:contentEncloser
                                                                                attribute:NSLayoutAttributeCenterX
                                                                               multiplier:1
                                                                                 constant:0];
            [contentEncloser addConstraint:centerConstraint];
            
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-(%@)-[%@(<=%@)]",[self isTopFragment:fragmensViewArr currentIndex:i] ? topPadding : internalPadding,str,imageHeight]];
        } else if([str containsString:@"text_"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(<=%ld)]-%@-|",leftPadding,str,(long)self.maxContentWidth,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-(%@)-[%@(>=0)]",[self isTopFragment:fragmensViewArr currentIndex:i] ? topPadding : internalPadding,str]];
        } else if([str containsString:@"button_"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(>=75)]-(>=%@)-|",leftPadding,str,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-%@-[%@]",[self isTopFragment:fragmensViewArr currentIndex:i]? topPadding : internalPadding, str]];
        }else if([str containsString:@"calendarInvitationView"]) {
            int width = [FCUtilities calendarMsgWidthInBounds:self.messageViewBounds] - ([rightPadding floatValue] + [leftPadding floatValue]);
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(%d)]-(>=%@)-|",leftPadding,str,width,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-%@-[calendarInvitationView]",topPadding]];
        } else if([str containsString:@"carousel_"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(212@999)]-(>=%@)-|",leftPadding,str,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-%@-[%@]",[self isTopFragment:fragmensViewArr currentIndex:i]? topPadding : internalPadding, str]];
        }
    }
    
    if(!currentMessage.isWelcomeMessage) { //Show time for non welcome messages.
        [veriticalConstraint appendString:[NSString stringWithFormat:@"-(%@)-[messageSentTimeLabel]",internalPadding]];
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : [NSString stringWithFormat:@"H:|-(>=%@)-[messageSentTimeLabel]-5-[uploadStatusImageView(10)]-(%@)-|",leftPadding,rightPadding] options:0 metrics:nil views:views]];
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : [NSString stringWithFormat:@"V:[uploadStatusImageView(10)]-(%@)-|",bottomPadding] options:0 metrics:nil views:views]];
    }
    
    [veriticalConstraint appendString:[NSString stringWithFormat:@"-(%@)-|",bottomPadding]];
    //Constraints for details inside contentEncloser is done.
    if(![veriticalConstraint isEqualToString:[NSString stringWithFormat:@"v:|-(%@)-|",bottomPadding]]) {
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : veriticalConstraint options:0 metrics:nil views:views]];
    }
    self.tag=[currentMessage.messageId hash];
}

-(NSAttributedString *) appendImage :(UIImage *) image withText :(NSAttributedString *) content {
    NSTextAttachment *imageAttachment = [[NSTextAttachment alloc] init];
    imageAttachment.image = image;
    CGFloat aspect = image.size.width / image.size.height;
    CGSize newSize;
    CGFloat maxDim = [[FCTheme sharedInstance] userMessageFont].pointSize;
    if (image.size.width > image.size.height) {
        newSize = CGSizeMake(maxDim, [[FCTheme sharedInstance] userMessageFont].pointSize / aspect);
    } else {
        newSize = CGSizeMake(maxDim * aspect, maxDim);
    }
    CGFloat imageOffsetY = -2.0;
    imageAttachment.bounds = CGRectMake(0, imageOffsetY, newSize.width, newSize.height);
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:imageAttachment];
    NSMutableAttributedString *completeText = [[NSMutableAttributedString alloc] initWithString:@""];
    [completeText appendAttributedString:attachmentString];
    [completeText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];// To add extra space
    [completeText appendAttributedString:content];
    return  completeText;
}

-(BOOL) isTopFragment :(NSArray *)array currentIndex:(int)currentIndex {
    if (array.count > 0) {
        return (int)currentIndex == 0;
    }
    return false;
}

-(void) clearAllSubviews {
    NSArray *subViewArr = [self.contentView subviews];
    for (UIView *subUIView in subViewArr) {
        [subUIView removeFromSuperview];
    }
}

@end
