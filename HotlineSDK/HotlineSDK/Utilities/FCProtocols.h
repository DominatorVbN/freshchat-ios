//
//  FCProtocols.h
//  HotlineSDK
//
//  Created by Sanjith Kanagavel on 27/06/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

@protocol HLMessageCellDelegate <NSObject>
    -(void)performActionOn:(FragmentData *)fragment;
    -(BOOL)handleLinkDelegate: (NSURL *)url;
    -(void) handleCalendarMsg :(FCMessageData*)message forAction :(enum FCCalendarOptionType) actionType;
@end

