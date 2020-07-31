//
//  FCCalendarTableViewController.h
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 10/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCCalendarModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCCalendarTableViewController : UITableViewController

@property (nonatomic, assign) long selectedSlotMillis;
@property (nonatomic, strong) NSString *timeZone;

-(id)initWithFullDays:(BOOL)showFullDays andDays:(NSArray<FCCalendarDay *>*)days;
-(void)showFullDays:(BOOL)fullDays;
-(void)changeSource:(NSArray<FCCalendarDay *>*)days;
@end

NS_ASSUME_NONNULL_END
