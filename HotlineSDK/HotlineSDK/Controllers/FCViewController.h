//
//  HLViewController.h
//  HotlineSDK
//
//  Created by Hrishikesh on 05/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef HLViewController_h
#define HLViewController_h

#import <UIKit/UIKit.h>

@interface FCViewController : UIViewController

@property BOOL embedded;

-(void)configureBackButton;
-(UIViewController <UIGestureRecognizerDelegate> *) gestureDelegate;

-(void)jwtStateChange;
-(void)addJWTObservers;
-(void)removeJWTObservers;

@end



#endif /* HLViewController_h */
