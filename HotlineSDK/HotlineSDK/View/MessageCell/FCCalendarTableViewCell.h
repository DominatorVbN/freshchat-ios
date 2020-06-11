//
//  FCCalendarTableViewCell.h
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 11/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCCalendarModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CellDelegate <NSObject>
- (void)clickedSlotDate:(NSDate *)date withTimeZone:(NSTimeZone *)zone;
@end

@interface FCCalendarTableViewCell : UITableViewCell

@property (weak, nonatomic) id<CellDelegate>delegate;
@property (assign, nonatomic) NSInteger cellIndex;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier;
-(void) updateView:(NSArray<FCCalendarSession *>*)sessions forLastCellInRow:(BOOL)isLastCell andLastRow:(BOOL)isLastRow;

@end

@interface SlotButton : UIButton

@property (nonatomic, strong) NSDate *dateVal;
@property (nonatomic, strong) NSTimeZone *timeZoneVal;

@end

NS_ASSUME_NONNULL_END
