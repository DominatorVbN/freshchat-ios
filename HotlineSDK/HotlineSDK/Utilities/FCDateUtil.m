//
//  FDDateUtil.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 14/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FCDateUtil.h"
#import "FCSecureStore.h"
#import "FCMacros.h"
#import "FCLocaleUtil.h"
#import "FCLocalization.h"

@implementation FCDateUtil

+(NSDateFormatter *)getDateFormatter{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter            = [[NSDateFormatter alloc]init];
        NSLocale *en_US_POSIX     = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.locale     = en_US_POSIX;
        dateFormatter.timeZone   = [NSTimeZone timeZoneForSecondsFromGMT:0];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    });
    return dateFormatter;
}

+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay {
    return [FCDateUtil stringRepresentationForDate:dateToDisplay includeTimeForCurrentYear:YES];
}

+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay includeTimeForCurrentYear : (BOOL)includeTimeForCurrentYear {
    NSDate* today=[[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSDateComponents *componentsToday = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:today];
    NSDateComponents *componentsForDateToDisplay = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:dateToDisplay];
    
    NSInteger currentDay = [componentsToday day];
    NSInteger dayToDisplay = [componentsForDateToDisplay day];
    
    NSInteger currentMonth = [componentsToday month];
    NSInteger monthToDisplay = [componentsForDateToDisplay month];
    
    NSInteger currentYear = [componentsToday year];
    NSInteger yearToDisplay = [componentsForDateToDisplay year];
    
    NSLocale *locale =[[NSLocale alloc] initWithLocaleIdentifier:[FCLocaleUtil getUserLocale]];
    [dateFormatter setLocale:locale];
    if ((currentDay == dayToDisplay) && (currentYear == yearToDisplay) && (currentMonth == monthToDisplay)){
        [dateFormatter setDateFormat:HLLocalizedString(LOC_CHAT_MESSAGE_TIME_TODAY)];
    }else if(currentYear == yearToDisplay){
        [dateFormatter setDateFormat:includeTimeForCurrentYear ? HLLocalizedString(LOC_CHAT_MESSAGE_TIME_THIS_YEAR_LONG) : HLLocalizedString(LOC_CHAT_MESSAGE_TIME_THIS_YEAR_SHORT)];
    }else{
        [dateFormatter setDateFormat:HLLocalizedString(LOC_CHAT_MESSAGE_TIME_OTHER_YEAR)];
    }
    NSString* timeString = [dateFormatter stringFromDate:dateToDisplay];
    return timeString;
}

+(NSNumber *) maxDateOfNumber:(NSNumber *) lastUpdatedTime andStr:(NSString*) lastUpdatedStr{
    NSNumber *lastUpdatedStrVal = [NSNumber numberWithDouble:[lastUpdatedStr doubleValue]];
    if([lastUpdatedTime compare:lastUpdatedStrVal] != NSOrderedDescending){
        return lastUpdatedStrVal;
    }
    return lastUpdatedTime;
}

+(NSMutableArray<FCCalendarDay*> *) getSlotsFromCalendar:(FCCalendarModel*) calendarModel andTimeZoneIdentifier:(NSString*) timeZoneID {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    NSCalendar *timeZoneCalendar = [NSCalendar currentCalendar];
    calendar.timeZone = [NSTimeZone timeZoneWithName:timeZoneID];
    NSMutableDictionary *dateMap = [[NSMutableDictionary alloc]init];
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:timeZoneID];
    for(int i = 0; i< calendarModel.timeSlots.count; i++) {
        FCCalendarTimeSlot *timeSlot = calendarModel.timeSlots[i];
        NSDate *fromDate = [FCDateUtil nextlandMarkDate:[NSDate dateWithTimeIntervalSince1970:timeSlot.from.longLongValue/1000] andCalendar:calendar];
        NSDate *toDate = [NSDate dateWithTimeIntervalSince1970:timeSlot.to.longLongValue/1000];
        
        NSMutableArray<NSDate*>* dateArray = [FCDateUtil getTimeSlotsFrom:fromDate toDate:toDate andMeetingLength:calendarModel.meetingLength forTimeZone:timeZone];
        for (int j=0; j< dateArray.count; j++) {
            NSDate *currentDate = dateArray[j];
            NSDate *currentStartDate = [timeZoneCalendar startOfDayForDate:currentDate];
            NSMutableArray<NSDate*>* keyArray = [dateMap objectForKey: currentStartDate];
            if (!keyArray) {
                keyArray = [[NSMutableArray alloc]init];
            }
            [keyArray addObject:currentDate];
            [dateMap setObject:keyArray forKey:currentStartDate];
        }
    }
    NSMutableArray<FCCalendarDay*> *calenderDays = [[NSMutableArray alloc] init];
    if (dateMap.allKeys.count > 0) {
        NSArray<NSDate*>* sortedDates = [dateMap.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare: obj2];
        }];
        for(int i=0; i< sortedDates.count ; i++) {
            NSArray<NSDate*>* timeSlots = [dateMap objectForKey:sortedDates[i]];
            if(timeSlots) {
                FCCalendarDay *day = [[FCCalendarDay alloc]initWith:timeSlots andTimeZone:timeZone];
                [calenderDays addObject:day];
            }
        }
    }
    return calenderDays;
}

+(NSMutableArray<FCCalendarDay*> *) getSlotsFromCalendar:(FCCalendarModel*) calendarModel {
    NSString *timeZone = [NSTimeZone defaultTimeZone].name;
    return [FCDateUtil getSlotsFromCalendar:calendarModel andTimeZoneIdentifier:timeZone];
}

+ (NSDate*)nextlandMarkDate:(NSDate*)date andCalendar:(NSCalendar*)calendar {
    NSDateComponents *dateComponent = [calendar components:NSCalendarUnitMinute fromDate:date];
    NSDateComponents *secondComponent = [calendar components:NSCalendarUnitSecond fromDate:date];
    int remaining = dateComponent.minute % 15;
    dateComponent.minute = remaining > 0 ? 15 - remaining : (secondComponent.second > 0 ? 15 : 0);
    NSTimeInterval time = floor([[calendar dateByAddingComponents:dateComponent toDate:date options:NSCalendarMatchStrictly] timeIntervalSinceReferenceDate] / 60.0) * 60.0;
   return [NSDate dateWithTimeIntervalSinceReferenceDate:time];
}

+(NSMutableArray<NSDate *> *)getTimeSlotsFrom:(NSDate*) fromDate toDate:(NSDate*)toDate andMeetingLength:(NSNumber*)length forTimeZone:(NSTimeZone *) timeZone{
    NSMutableArray<NSDate *> *timeArray = [[NSMutableArray alloc]init];
    if([toDate timeIntervalSinceDate:fromDate] >= length.doubleValue) {
        timeArray = [FCDateUtil getTimeSlotsFrom:[fromDate dateByAddingTimeInterval:length.doubleValue] toDate:toDate andMeetingLength:length forTimeZone:timeZone];
        [timeArray insertObject:fromDate atIndex:0];
    }
    return timeArray;
}

+ (NSDateFormatter *) getFormattedDate:(NSDate *) date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    dateFormatter.timeZone = [calendar timeZone];
    NSLocale *locale =[[NSLocale alloc] initWithLocaleIdentifier:[FCLocaleUtil getUserLocale]];
    [dateFormatter setLocale:locale];
    return dateFormatter;
}

+(NSString *)getDateStringWithFormat:(NSString *)format forDate:(NSDate *)date{
    NSDateFormatter *dateFormatter = [FCDateUtil getFormattedDate:date];
    [dateFormatter setDateFormat:format];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)getDetailedDateStringWithFormat:(NSString *)format forDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [FCDateUtil getFormattedDate:date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *today = [calendar startOfDayForDate:[NSDate date]];
    NSDateComponents *diffComponent = [calendar components:NSCalendarUnitDay fromDate:today toDate:date options:0];
    NSString* dateString = @"";
    if (diffComponent.day == 0) {
        dateString = HLLocalizedString(LOC_DEFAULT_DATE_TODAY);
    } else if (diffComponent.day == 1) {
        dateString = HLLocalizedString(LOC_DEFAULT_DATE_TOMORROW);
    } else {
        [dateFormatter setDateFormat:@"EEEE"];
        dateString = [dateFormatter stringFromDate:date];
        [dateFormatter setDateFormat:format];
        dateString = [NSString stringWithFormat:@"%@, %@",dateString,[dateFormatter stringFromDate:date]];
    }
    return dateString;
}

@end
