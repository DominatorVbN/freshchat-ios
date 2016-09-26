//
//  FDPlistManager.h
//  HotlineSDK
//
//  Created by user on 23/09/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDPlistManager : NSObject

-(BOOL)micUsageEnabled;

-(BOOL)photoLibraryUsageEnabled;

-(BOOL)cameraUsageEnabled;

-(BOOL)isVoiceMessageEnabled;

-(BOOL)isPictureMessageEnabled;

@end
