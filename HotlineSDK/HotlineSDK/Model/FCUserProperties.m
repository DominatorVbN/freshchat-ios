//
//  KonotorCustomProperty.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCUserProperties.h"
#import "FCDataManager.h"
#import "FCMacros.h"

@implementation FCUserProperties

@dynamic key;
@dynamic serializedData;
@dynamic uploadStatus;
@dynamic value;
@dynamic isUserProperty;

+(FCUserProperties*)createNewPropertyForKey:(NSString *)key WithValue:(NSString *)value isUserProperty:(BOOL)isUserProperty{
    FCUserProperties *property = nil;
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    @try{
        property =  [FCUserProperties getCustomPropertyWithKey:key andUserProperty:isUserProperty withContext:context];
        if (property){
            if ([value isEqualToString:property.value] || (value == nil && property.value == nil)) {
              return property;
            }
        }else{
            property = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_USER_PROPERTIES_ENTITY inManagedObjectContext:context];
            property.key = key;
        }
        property.uploadStatus = @0;
        property.value = value;
        property.isUserProperty = isUserProperty;
        
        //TODO : Too many redundant saves .. Needs refactor - Rex
        [[FCDataManager sharedInstance]save];
    } @catch (NSException *exception) {
        NSString *exceptionDesc = [NSString stringWithFormat:@"COREDATA_EXCEPTION: %@", exception.description];
        FDLog(@"Error in creating properties in table : %@ %@", FRESHCHAT_USER_PROPERTIES_ENTITY, exceptionDesc);
    }
    return property;
}


// (Key + userProperty) is unique
+(FCUserProperties *)getCustomPropertyWithKey:(NSString *)key andUserProperty:(BOOL)userProperty withContext:(NSManagedObjectContext *)context{
    FCUserProperties *property = nil;
    @try {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_USER_PROPERTIES_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"key == %@ && isUserProperty == %@",key,[NSNumber numberWithBool:userProperty]];
        NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
        if (matches.count == 1) {
            property = matches.firstObject;
        }
        if (matches.count > 1) {
            //updated to fix 3.2.2 duplicate set user call
            for (NSManagedObject* object in matches){
                [context deleteObject:object];
            }
            return nil;
        }
    }
    @catch(NSException *exception) {
        NSString *exceptionDesc = [NSString stringWithFormat:@"COREDATA_EXCEPTION: %@", exception.description];
        FDLog(@"Error in handling properties from table : %@ %@ ", FRESHCHAT_USER_PROPERTIES_ENTITY, exceptionDesc);
    }
    return property;
}

+(NSArray *)getUnuploadedProperties{
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_USER_PROPERTIES_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"uploadStatus == NO"];
    __block NSMutableArray *matches = [[NSMutableArray alloc] init];
    [context performBlockAndWait:^{
        NSArray *tempMatches = [context executeFetchRequest:fetchRequest error:nil];
        matches = [tempMatches mutableCopy];
    }];
    return matches;
}

@end
