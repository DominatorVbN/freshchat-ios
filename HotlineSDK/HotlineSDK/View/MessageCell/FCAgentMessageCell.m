//
//  HLMessageCell.m
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCAgentMessageCell.h"
#import "FCUtilities.h"
#import "FCTheme.h"
#import "FCLocalization.h"
#import "FCSecureStore.h"
#import "FCDeeplinkFragment.h"
#import "FCHtmlFragment.h"
#import "FCImageFragment.h"
#import "FCVideoFragment.h"
#import "FCAudioFragment.h"
#import "FCUnsupportedFragment.h"
#import "FCFileFragment.h"
#import "FCAutolayoutHelper.h"
#import "FCParticipants.h"
#import "FDImageView.h"
#import "FCRemoteConfig.h"
#import "FCSecureStore.h"
#import "FCDateUtil.h"
#import "FCCarouselCardsList.h"
#import "FCConstants.h"
#import "FCCalendarOptionsView.h"
#import "FCTemplateFactory.h"
#import "FCTemplateSection.h"


@interface FCAgentMessageCell ()

@property (strong, nonatomic) NSLayoutConstraint *senderLabelHeight;
@property (nonatomic, strong) NSString *agentName;
@property (nonatomic, assign) BOOL showteamMemberInfo; //display team member info
@property (nonatomic, assign) BOOL showAvatarView; //plist flag TeamMemberAvatarStyle.visible
@property (nonatomic, assign) BOOL hasAgentCalenderInvite;

@end

@implementation FCAgentMessageCell

@synthesize contentEncloser,maxcontentWidth,showsProfile,showsSenderName,customFontName,
            showsTimeStamp,showsUploadStatus,sentImage,sendingImage;
@synthesize messageSentTimeLabel,chatBubbleImageView,uploadStatusImageView,
            profileImageView,senderNameLabel,messageTextFont,agentChatBubble,agentChatBubbleInsets;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<HLMessageCellDelegate>)delegate{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        self.delegate = delegate;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self initCell];
    }
    return self;
}

-(BOOL) showAgentAvatarLabelWithAlias : (NSString *)alias {
    if(self.showteamMemberInfo){
        FCParticipants *participant = [FCParticipants fetchParticipantForAlias:alias inContext:[FCDataManager sharedInstance].mainObjectContext];
        if(participant.firstName && trimString(participant.firstName).length > 0){
            self.agentName = participant.firstName;
        }
        else{
            self.agentName = [self getLocalizedAgentName];
        }
    }
    else{
        self.agentName = [self getLocalizedAgentName];
    }
    return [FCStringUtil isNotEmptyString:self.agentName];
}

- (NSString *) getLocalizedAgentName{
    if ([FCLocalization isNotEmpty:LOC_MESSAGES_AGENT_LABEL_TEXT]){
        return HLLocalizedString(LOC_MESSAGES_AGENT_LABEL_TEXT);
    }
    return @"";
}

- (void) initCell{
    self.sentImage=[[FCTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENT_ICON];
    self.sendingImage=[[FCTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENDING_ICON];
    self.showsProfile = NO;
    self.showsSenderName= NO;
    //self.customFontName=[[FCTheme sharedInstance] agentMessageFont];
    self.showsUploadStatus=YES;
    self.showsTimeStamp=YES;
    self.chatBubbleImageView=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.senderNameLabel=[[UILabel alloc] initWithFrame:CGRectZero];
    
    [senderNameLabel setFont:[[FCTheme sharedInstance] agentNameFont]];
    [senderNameLabel setBackgroundColor:[UIColor clearColor]];
    [senderNameLabel setTextAlignment:NSTextAlignmentLeft];
    senderNameLabel.numberOfLines = 1;
    senderNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    senderNameLabel.textColor = [[FCTheme sharedInstance] agentNameFontColor];
    
    messageSentTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    messageSentTimeLabel.numberOfLines = 0;
    messageSentTimeLabel.textColor = [[FCTheme sharedInstance] agentMessageTimeFontColor];
    [messageSentTimeLabel setFont:[[FCTheme sharedInstance] agentMessageTimeFont]];
    [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
    [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
    messageSentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    profileImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
    profileImageView.translatesAutoresizingMaskIntoConstraints = NO;
    profileImageView.backgroundColor = [UIColor clearColor];
    profileImageView.clipsToBounds = YES;
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.layer.cornerRadius=FC_PROFILEIMAGE_DIMENSION/2;
    
    chatBubbleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    chatBubbleImageView.clipsToBounds = YES;
    
    uploadStatusImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
    [uploadStatusImageView setImage:sentImage];
    uploadStatusImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.showAvatarView = [[FCTheme sharedInstance] isTeamMemberAvatarVisibile];
    self.showteamMemberInfo = [[FCSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
    if(self.showteamMemberInfo){
        int agentAvatarRCVal = [FCRemoteConfig sharedInstance].conversationConfig.agentAvatar;
        self.showsProfile = (agentAvatarRCVal <= 2);
    }
    
    agentChatBubble = [[FCTheme sharedInstance]getImageValueWithKey:IMAGE_BUBBLE_CELL_LEFT];
    agentChatBubbleInsets= [[FCTheme sharedInstance] getAgentBubbleInsets];

    [chatBubbleImageView setImage:[agentChatBubble resizableImageWithCapInsets:agentChatBubbleInsets]];
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setClipsToBounds:YES];
}

- (void) drawMessageViewForMessage:(FCMessageData*)currentMessage parentView:(UIView*)parentView withTag:(NSInteger )tag {
    
    [self clearAllSubviews];
    self.hasAgentCalenderInvite = ([currentMessage.messageType isEqualToNumber: FC_CALENDAR_INVITE_MSG]
                                   && currentMessage.hasActiveCalInvite);
    contentEncloser = [[UIView alloc] init];
    contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    [contentEncloser setLayoutMargins:UIEdgeInsetsMake(0,0,0,0)];
    FCTheme *theme = [FCTheme sharedInstance];
    NSString *topPadding = [theme agentMessageTopPadding] ? [theme agentMessageTopPadding] : @"10";
    NSString *bottomPadding = [theme agentMessageBottomPadding] ? [theme agentMessageBottomPadding] : @"10";
    NSString *leftPadding = [theme agentMessageLeftPadding] ? [theme agentMessageLeftPadding] : @"10";
    NSString *rightPadding = [theme agentMessageRightPadding] ? [theme agentMessageRightPadding] : @"10";
    NSString *internalPadding = @"5";
    showsSenderName = [self showAgentAvatarLabelWithAlias:currentMessage.messageUserAlias];
    NSMutableArray *fragmensViewArr = [[NSMutableArray alloc]init];
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    [views setObject:self.contentEncloser forKey:@"contentEncloser"];
    [views setObject:self.chatBubbleImageView forKey:@"chatBubbleImageView"];
    FCParticipants *participant = [FCParticipants fetchParticipantForAlias:currentMessage.messageUserAlias inContext:[FCDataManager sharedInstance].mainObjectContext];
    senderNameLabel.text = self.agentName;
    [contentEncloser addSubview:chatBubbleImageView];
    [views setObject:self.senderNameLabel forKey:@"senderLabel"];
    [self.contentView addSubview:senderNameLabel];
    profileImageView.image = [[FCTheme sharedInstance] getCustomAgentIconComponent];
    profileImageView.frame = CGRectMake(0, 0, FC_PROFILEIMAGE_DIMENSION, FC_PROFILEIMAGE_DIMENSION);
    [self.contentView addSubview:profileImageView];
    [views setObject:profileImageView forKey:@"profileImageView"];
    if(self.showAvatarView){
        if(participant.profilePicURL && self.showteamMemberInfo){
            [FCUtilities loadImageFromURL:participant.profilePicURL withCache:^{
                if(self.tagVal && (tag == self.tagVal)){
                    [profileImageView setImage: [[FDImageCache sharedImageCache] imageFromDiskCacheForKey:participant.profilePicURL]];
                }
            } withError:nil withCompletion:^(UIImage * _Nonnull image) {
                [[FDImageCache sharedImageCache] storeImage:image forKey:participant.profilePicURL completion:^{
                    if(self.tagVal && (tag == self.tagVal)){
                        profileImageView.image = image;
                    }
                }];
            }];
        }
        else if([[FCTheme sharedInstance] getCustomAgentIconComponent]){ // added just to avoid no icon condition
            profileImageView.image = [[FCTheme sharedInstance] getCustomAgentIconComponent];
        }
    }
    
    if(!currentMessage.isWelcomeMessage){
        NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
        messageSentTimeLabel.text = [FCDateUtil stringRepresentationForDate:date];
        [contentEncloser addSubview:messageSentTimeLabel];
        [views setObject:messageSentTimeLabel forKey:@"messageSentTimeLabel"]; //Constraints not yet set.
    }
    
    [self.contentView addSubview:contentEncloser];
    
    NSString *replyFragments = currentMessage.replyFragments;
    FCCarouselCardsList *list;
    if([replyFragments isTemplateFragment] && [self isLastMessage]) {
        NSDictionary *jsonDict = [FCMessageUtil getReplyFragmentsIn:replyFragments].firstObject;
        TemplateFragmentData *templateFragment = [FCTemplateFactory getFragmentFrom:jsonDict];
        if ([templateFragment.templateType isEqualToString:FRESHHCAT_TEMPLATE_CARUOSEL]) {
            list = [[FCCarouselCardsList alloc] initWithTemplateFragment:templateFragment inReplyTo:currentMessage.messageId withDelegate:self.templateDelegate];
            [self.contentView addSubview:list];
            [views setObject:list forKey:@"carouselList"];
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5@999-[carouselList]-5@999-|" options:0 metrics:nil views:views]];
        }
   }

    for(int i=0; i<currentMessage.fragments.count; i++) {
        FragmentData *fragment = currentMessage.fragments[i];
        if ([fragment.type isEqualToString:@"1"] || [fragment.type isEqualToString: [@(FRESHCHAT_QUICK_REPLY_FRAGMENT) stringValue]]) {
            //HTML
            FCHtmlFragment *htmlFragment = [[FCHtmlFragment alloc]initFragment:fragment withFont:[[FCTheme sharedInstance] agentMessageFont] andType:1];
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
        } else if([fragment.type isEqualToString:@"5"]) {
            FCDeeplinkFragment *fileFragment = [[FCDeeplinkFragment alloc] initWithFragment:fragment];
            [views setObject:fileFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:fileFragment];
            fileFragment.delegate = self.delegate;
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"BUTTON");
        } else {
            //For Unknown fragment
            FCUnsupportedFragment *unknownFragment = [[FCUnsupportedFragment alloc] initWithFragment:fragment];
            [views setObject:unknownFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:unknownFragment];
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
        }
    }
    
    if (self.hasAgentCalenderInvite){
        FCCalendarOptionsView *calendarOptions = [[FCCalendarOptionsView alloc] initCalendarOptionsViewForMessage:currentMessage];
        [views setObject:calendarOptions forKey:@"calendarOptions"];
        calendarOptions.delegate = self.delegate;
        [contentEncloser addSubview:calendarOptions];
        [fragmensViewArr addObject:@"calendarOptions"];
    }
    
    //All details are in contentview but no constrains set
    int agentImagedim = self.showAvatarView ? FC_PROFILEIMAGE_DIMENSION : 0;
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[profileImageView(%d)]-5-[contentEncloser(<=%ld)]",agentImagedim ,(long)self.maxcontentWidth] options:0 metrics:nil views:views]];
    NSString *contentViewHorzVertSuffix = @"-2-|";
    if(showsSenderName) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[profileImageView(%d)]-5-[senderLabel(<=%ld)]",agentImagedim ,(long)self.maxcontentWidth] options:0 metrics:nil views:views]]; //Correct
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-2-[senderLabel]-2-[profileImageView(%d)]",agentImagedim] options:0 metrics:nil views:views]];
        NSString *contentViewHorzPrefix = @"V:|-2-[senderLabel]-2-[contentEncloser(>=50)]";
        if(list) {
            NSDictionary *metric = @{@"temp": [NSNumber numberWithFloat:[list getCarousalListMaxHeight]]};
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"%@-15-[carouselList(==temp@999)]%@",contentViewHorzPrefix,contentViewHorzVertSuffix] options:0 metrics:metric views:views]];
        }
        else {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"%@%@",contentViewHorzPrefix,contentViewHorzVertSuffix]  options:0 metrics:nil views:views]];
        }
        
    } else {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-2-[profileImageView(%d)]",agentImagedim] options:0 metrics:nil views:views]];
        NSString *contentViewVertPrefix = @"V:|-2-[contentEncloser(>=50)]";
        if(list) {
            NSDictionary *metric = @{@"temp":  [NSNumber numberWithFloat:[list getCarousalListMaxHeight]]};
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"%@-15-[carouselList(==temp@999)]%@",contentViewVertPrefix,contentViewHorzVertSuffix]  options:0 metrics:metric views:views]];
        } else {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"%@%@",contentViewVertPrefix,contentViewHorzVertSuffix] options:0 metrics:nil views:views]];
        }
    }
    
    //Constraints for profileview and contentEncloser are done.
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    //Constraints for chatbubble are done.
    
    BOOL welcomeTextMsg = (currentMessage.isWelcomeMessage && fragmensViewArr.count == 1);
    
    NSMutableString *veriticalConstraint = [[NSMutableString alloc]initWithString:@"V:|"];
    for(int i=0;i<fragmensViewArr.count;i++) { //Set Constraints here
        NSString *str = fragmensViewArr[i];
        if([str containsString:@"image_"]) {
            FCImageFragment *imageFragment = views[str];
            NSString *imageHeight = [NSString stringWithFormat:@"%d",(int)imageFragment.imgFrame.size.height];
            NSString *imageWidth = [NSString stringWithFormat:@"%d",(int)imageFragment.imgFrame.size.width];
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-(>=%@)-[%@(%@)]-(>=%@)-|",leftPadding,str,imageWidth,rightPadding];
            NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:imageFragment
                                                                                attribute:NSLayoutAttributeCenterX
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:contentEncloser
                                                                                attribute:NSLayoutAttributeCenterX
                                                                               multiplier:1
                                                                                 constant:0];
            [contentEncloser addConstraint:centerConstraint];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-%@-[%@(%@@999)]",[self isTopFragment:fragmensViewArr currentIndex:i]? topPadding : internalPadding,str,imageHeight]];
        } else if([str containsString:@"text_"]) {
            if(welcomeTextMsg) { //If it has only text message in welcome message
                FCHtmlFragment *textFragment = views[str];
                NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(<=%ld)]-%@-|",leftPadding,str,(long)self.maxcontentWidth,rightPadding];
                [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
                NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:textFragment
                                                                                    attribute:NSLayoutAttributeCenterY
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:contentEncloser
                                                                                    attribute:NSLayoutAttributeCenterY
                                                                                   multiplier:1
                                                                                     constant:0];
                [contentEncloser addConstraint:centerConstraint];
                [veriticalConstraint appendString:[NSString stringWithFormat:@"-(>=%@)-[%@(>=0)]",[self isTopFragment:fragmensViewArr currentIndex:i]? topPadding : internalPadding,str]];
            } else {
                NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(<=%ld)]-%@-|",leftPadding,str,(long)self.maxcontentWidth,rightPadding];
                [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
                [veriticalConstraint appendString:[NSString stringWithFormat:@"-%@-[%@(>=0)]",[self isTopFragment:fragmensViewArr currentIndex:i]? topPadding : internalPadding,str]];
            }
        } else if([str containsString:@"button_"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(>=75)]-(>=%@)-|",leftPadding,str,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-%@-[%@]",[self isTopFragment:fragmensViewArr currentIndex:i]? topPadding : internalPadding, str]];
        } else if([str containsString:@"calendarOptions"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(>=75)]-%@-|",leftPadding,str, rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-[%@(>=0)]",str]];
        }
    }
    if(!currentMessage.isWelcomeMessage) { //Show time for non welcome messages.
        [veriticalConstraint appendString:[NSString stringWithFormat:@"-%@-[messageSentTimeLabel]",internalPadding]];
        NSNumber  *adjustedPadding = [NSNumber numberWithInteger: [leftPadding integerValue]];
        if(adjustedPadding != nil) {
            adjustedPadding = @([adjustedPadding intValue] + 5);
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : [NSString stringWithFormat:@"H:|-%@-[messageSentTimeLabel]-(>=%@)-|",[adjustedPadding stringValue],rightPadding] options:0 metrics:nil views:views]];
        } else {
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : [NSString stringWithFormat:@"H:|-%@-[messageSentTimeLabel]-(>=%@)-|",leftPadding,rightPadding] options:0 metrics:nil views:views]];
        }
    }
    if(welcomeTextMsg) {
        [veriticalConstraint appendString:[NSString stringWithFormat:@"-(>=%@)-|",bottomPadding]];
    } else {
        [veriticalConstraint appendString:[NSString stringWithFormat:@"-%@-|",bottomPadding]];
    }
    //Constraints for details inside contentEncloser is done.
    if(![veriticalConstraint isEqualToString:[NSString stringWithFormat:@"V:|-%@-|",bottomPadding]]) {
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : veriticalConstraint options:0 metrics:nil views:views]];
    }
    self.tag=[currentMessage.messageId hash];
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
