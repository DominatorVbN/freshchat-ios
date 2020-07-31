//
//  FCCalendarModel.h
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 09/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCCalendarTimeSlot: NSObject
@property(nonatomic,strong,retain) NSString *identifier;
@property(nonatomic,strong,retain) NSString *prevIdentifier;
@property(nonatomic,strong,retain) NSNumber *from;
@property(nonatomic,strong,retain) NSNumber *to;
-(instancetype)initWith:(NSDictionary *)dictionary;
@end

@interface FCCalendarModel : NSObject
@property(nonatomic,strong,retain) NSString *identifier;
@property(nonatomic,strong,retain) NSArray<FCCalendarTimeSlot *>* timeSlots;
@property(nonatomic,strong,retain) NSNumber *meetingLength;
@property(nonatomic,strong,retain) NSNumber *bufferTime;
@property(nonatomic,strong,retain) NSNumber *minNoticeTime;
@property(nonatomic,strong,retain) NSNumber *calendarType;
-(instancetype)initWith:(NSDictionary *)dictionary;
@end


typedef enum {
    FCMorningSession,
    FCAfterNoonSession,
    FCEveningSession,
    FCNightSession
}FCTimeSession;

@interface FCCalendarSession : NSObject
@property(nonatomic,strong,retain) NSDate *date;
@property(nonatomic) FCTimeSession session;
@property(nonatomic,strong,retain) NSString *time;
@property(nonatomic,strong,retain) NSTimeZone *timeZone;
-(instancetype)initWith:(NSDate *)date session:(FCTimeSession) session andTime:(NSString*) time;
-(NSString*)getSessionTitle;
@end

@interface FCCalendarDay : NSObject<NSCopying>
@property(nonatomic,strong,retain) NSDate *date;
@property(nonatomic,strong,retain) NSTimeZone *timeZone;
@property(nonatomic,strong,retain) NSString *dateString;
@property(nonatomic,strong,retain) NSMutableArray<FCCalendarSession*>* morningSlots;
@property(nonatomic,strong,retain) NSMutableArray<FCCalendarSession*>* afterNoonSlots;
@property(nonatomic,strong,retain) NSMutableArray<FCCalendarSession*>* eveningSlots;
@property(nonatomic,strong,retain) NSMutableArray<FCCalendarSession*>* nightSlots;
-(instancetype)initWith:(NSArray<NSDate*>*) dates andTimeZone:(NSTimeZone*)timeZone;
-(NSMutableArray<FCCalendarSession*>*)getSessionsIn:(int)row;
@end
