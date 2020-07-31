//
//  FDDateUtil.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 14/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCCalendarModel.h"

@interface FCDateUtil : NSObject

+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay;
+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay includeTimeForCurrentYear : (BOOL)includeTimeForCurrentYear;
+(NSNumber *) maxDateOfNumber:(NSNumber *) lastUpdatedTime andStr:(NSString*) lastUpdatedStr;
+(NSMutableArray<FCCalendarDay*> *) getSlotsFromCalendar:(FCCalendarModel*) calendarModel;
+(NSMutableArray<FCCalendarDay*> *) getSlotsFromCalendar:(FCCalendarModel*) calendarModel andTimeZoneIdentifier:(NSString*) timeZoneID;
+(NSString *)getDateStringWithFormat:(NSString *)format forDate:(NSDate *)date;
+(NSString *)getDetailedDateStringWithFormat:(NSString *)format forDate:(NSDate *)date;
@end
