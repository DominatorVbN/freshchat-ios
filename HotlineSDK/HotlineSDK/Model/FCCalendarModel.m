//
//  FCCalendarModel.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 09/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCalendarModel.h"
#import "FCLocaleUtil.h"
#import "FCDateUtil.h"
#import "FCLocalization.h"

@implementation FCCalendarModel

- (instancetype)initWith:(NSDictionary *)dictionary {
    self = [super init];
    if(self && dictionary) {
        self.identifier = dictionary[@"id"];
        self.meetingLength = dictionary[@"meetingLength"];
        self.bufferTime = dictionary[@"bufferTime"];
        self.calendarType = dictionary[@"calendarType"];
        self.minNoticeTime = dictionary[@"minNoticeTime"];
        NSArray<NSDictionary*> *timeSlots = dictionary[@"calendarTimeSlots"];
        NSMutableArray *calendarSlots = [[NSMutableArray alloc]init];
        if(timeSlots && timeSlots.count > 0) {
            for (int i =0; i<timeSlots.count; i++) {
                NSDictionary *timeSlot = timeSlots[i];
                FCCalendarTimeSlot *calendarSlot = [[FCCalendarTimeSlot alloc] initWith:timeSlot];
                [calendarSlots addObject: calendarSlot];
            }
        }
        self.timeSlots = calendarSlots;
    }
    return self;
}

@end

@implementation FCCalendarTimeSlot
- (instancetype)initWith:(NSDictionary *)dictionary {
    self = [super init];
    if(self && dictionary) {
        self.from = dictionary[@"from"];
        self.to = dictionary[@"to"];
        self.identifier = dictionary[@"id"];
        self.prevIdentifier = dictionary[@"prevTo"];
    }
    return self;
}
@end

@implementation FCCalendarDay: NSObject

- (instancetype)initWith:(NSArray<NSDate *> *)dates andTimeZone:(NSTimeZone *)timeZone {
    self = [super init];
    if(self && dates.count > 0) {
        self.timeZone = timeZone;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        calendar.timeZone = timeZone;
        self.date = [calendar startOfDayForDate:dates.firstObject];
        self.morningSlots = [[NSMutableArray alloc]init];
        self.afterNoonSlots = [[NSMutableArray alloc]init];
        self.eveningSlots = [[NSMutableArray alloc]init];
        self.nightSlots = [[NSMutableArray alloc]init];
        [self updateValueFor:dates];
    }
    return self;
}

-(void)updateValueFor:(NSArray<NSDate *> *)dates {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.timeZone = self.timeZone;
    self.dateString = [FCDateUtil getDetailedDateStringWithFormat:@"d MMM yyyy" forDate:self.date];
    for(int i=0; i< dates.count; i++) {
        NSDate *currentDate = dates[i];
        NSDateComponents *dateComponents = [calendar componentsInTimeZone:self.timeZone fromDate: currentDate];
        NSString *timeString = [FCDateUtil getDateStringWithFormat:HLLocalizedString(LOC_CALENDAR_SLOTS_TIME_FORMAT) forDate:currentDate];
        FCCalendarSession *session;

        if (dateComponents.hour < 12) {
           session = [[FCCalendarSession alloc] initWith:currentDate session:FCMorningSession andTime:timeString];
            [self.morningSlots addObject:session];
        } else if (dateComponents.hour >= 12 && dateComponents.hour < 16) {
            session = [[FCCalendarSession alloc] initWith:currentDate session:FCAfterNoonSession andTime:timeString];
            [self.afterNoonSlots addObject:session];
        } else if (dateComponents.hour >= 16 && dateComponents.hour < 20) {
            session = [[FCCalendarSession alloc] initWith:currentDate session:FCEveningSession andTime:timeString];
            [self.eveningSlots addObject:session];
        } else {
            session = [[FCCalendarSession alloc] initWith:currentDate session:FCNightSession andTime:timeString];
            [self.nightSlots addObject:session];
        }
        session.timeZone = calendar.timeZone;
    }
}

- (NSMutableArray<FCCalendarSession *> *)getSessionsIn:(int)row {
    int currentRows = -1;
    if (self.morningSlots.count > 0) {
        if (currentRows + 1 == row) {
            return self.morningSlots;
        } else {
            currentRows ++;
        }
    }
    if (self.afterNoonSlots.count > 0) {
        if (currentRows + 1 == row) {
            return self.afterNoonSlots;
        } else {
            currentRows ++;
        }
    }
    if (self.eveningSlots.count > 0) {
        if (currentRows + 1 == row) {
            return self.eveningSlots;
        } else {
            currentRows ++;
        }
    }
    if (self.nightSlots.count > 0){
        return self.nightSlots;
    }
    return [@[] mutableCopy];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    FCCalendarDay *another = [[FCCalendarDay alloc] init];
    another.afterNoonSlots = [self.afterNoonSlots mutableCopy];
    another.morningSlots = [self.morningSlots mutableCopy];
    another.eveningSlots = [self.eveningSlots mutableCopy];
    another.nightSlots = [self.nightSlots mutableCopy];
    another.date = [self.date copy];
    another.dateString = [self.dateString copy];
    another.timeZone = [self.timeZone copy];
    return another;
}

@end

@implementation FCCalendarSession: NSObject

- (instancetype)initWith:(NSDate *)date session:(FCTimeSession)session andTime:(NSString *)time{
    self = [super init];
    if(self) {
        self.date = date;
        self.session = session;
        self.time = time;
    }
    return self;
}


-(NSString*)getSessionTitle {
    switch (self.session) {
        case FCMorningSession:
            return HLLocalizedString(LOC_CALENDAR_SLOTS_SESSION_MORNING);
            break;
        case FCAfterNoonSession:
            return HLLocalizedString(LOC_CALENDAR_SLOTS_SESSION_AFTERNOON);
            break;
        case FCEveningSession:
            return HLLocalizedString(LOC_CALENDAR_SLOTS_SESSION_EVENING);
            break;
        case FCNightSession:
            return HLLocalizedString(LOC_CALENDAR_SLOTS_SESSION_NIGHT);
            break;
    }
}

@end
