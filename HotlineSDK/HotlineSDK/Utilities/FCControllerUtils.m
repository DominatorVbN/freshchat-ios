//
//  HLControllerUtils.m
//  HotlineSDK
//
//  Created by user on 03/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCControllerUtils.h"
#import "FCViewController.h"
#import "FCDataManager.h"
#import "FCContainerController.h"
#import "FCMessageController.h"
#import "FCChannelViewController.h"
#import "FCBarButtonItem.h"
#import "FCLocalization.h"
#import "FCInterstitialViewController.h"
#import "FCCategoryGridViewController.h"
#import "FCCategoryListController.h"
#import "FCFAQUtil.h"
#import "FCUtilities.h"

@implementation FCControllerUtils

+(UIViewController *)getConvController:(BOOL)isEmbeded
                           withOptions:(ConversationOptions *)options
                           andChannels:(NSArray *)channels{
    UIViewController *controller;
    FCViewController *innerController;
    BOOL isModal = !isEmbeded;
    
    if (channels.count == 1) {
        FCChannelInfo *channelInfo = [channels firstObject];
        innerController = [[FCMessageController alloc]initWithChannelID:channelInfo.channelID andPresentModally:isModal];
    }else{
        innerController = [[FCChannelViewController alloc]init];
    }
    [FCConversationUtil setConversationOptions:options  andViewController:innerController];
    controller = [[FCContainerController alloc]initWithController:innerController andEmbed:isEmbeded];
    return controller;
}

+(void) configureBackButtonForController:(UIViewController *) controller
                            withEmbedded:(BOOL) isEmbedded{
    BOOL isBackButtonImageExist = [[FCTheme sharedInstance]getImageWithKey:IMAGE_BACK_BUTTON] ? YES : NO;
    if (isBackButtonImageExist && !isEmbedded) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[[FCTheme sharedInstance] getImageWithKey:IMAGE_BACK_BUTTON]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:controller.navigationController
                                                                      action:@selector(popViewControllerAnimated:)];
        controller.parentViewController.navigationItem.leftBarButtonItem = backButton;
    }else{
        controller.parentViewController.navigationItem.backBarButtonItem = [[FCBarButtonItem alloc] initWithTitle:@""
                                                                                                            style:controller.parentViewController.navigationItem.backBarButtonItem.style
                                                                                                           target:nil action:nil];
    }
}

+(void) configureCloseButton:(UIViewController *) controller
                   forTarget:(id)targetObj
                    selector: (SEL) actionSelector
                       title: (NSString *)title {
    UIImage *closeImage = [[FCTheme sharedInstance] getImageWithKey:IMAGE_SOLUTION_CLOSE_BUTTON];
    FCBarButtonItem *closeButton;
    if (closeImage) {
        closeButton = [FCUtilities getCloseBarBtnItemforCtr:targetObj withSelector:actionSelector];
    }
    else{
        closeButton = [[FCBarButtonItem alloc]initWithTitle:title
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:targetObj
                                                                  action:actionSelector];
    }
    if(!controller.parentViewController.navigationItem.leftBarButtonItem ) {
        controller.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
}

+(void) configureGestureDelegate:(UIViewController <UIGestureRecognizerDelegate> *)gestureDelegate
                   forController:(UIViewController *) controller
                    withEmbedded:(BOOL) isEmbedded{
    
    BOOL isBackButtonImageExist = [[FCTheme sharedInstance]getImageWithKey:IMAGE_BACK_BUTTON] ? YES : NO;
    UINavigationController *naviController = (controller.parentViewController) ? controller.parentViewController.navigationController : controller.navigationController;
    
    if([FCUtilities isDeviceLanguageRTL]){
        [naviController.view setSemanticContentAttribute:UISemanticContentAttributeForceRightToLeft];
        [naviController.navigationBar setSemanticContentAttribute:UISemanticContentAttributeForceRightToLeft];
    }
    if (isBackButtonImageExist && !isEmbedded) {
        if([controller conformsToProtocol:@protocol(UIGestureRecognizerDelegate)] && gestureDelegate){
            [naviController.interactivePopGestureRecognizer setEnabled:YES];
            naviController.interactivePopGestureRecognizer.delegate = gestureDelegate;
            
        }else{
            [naviController.interactivePopGestureRecognizer setEnabled:NO];
        }
        
    }else{
        [naviController.interactivePopGestureRecognizer setEnabled:NO];
    }
}

+(UIViewController *)getEmbedded:(id)option{
    FCInterstitialViewController* interstitialCtr = [[FCInterstitialViewController alloc] initViewControllerWithOptions:option andIsEmbed:YES];
    interstitialCtr.isStartingControllerInStack = true;
    return interstitialCtr;
}

+(void)presentOn:(UIViewController *)controller option:(id)options{
    FCInterstitialViewController *interstitialCtr = [[FCInterstitialViewController alloc]
                                                   initViewControllerWithOptions:options andIsEmbed:NO];
    interstitialCtr.isStartingControllerInStack = true;
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:interstitialCtr];
    [navigationController setModalPresentationStyle:UIModalPresentationFullScreen];
    [controller presentViewController:navigationController animated:YES completion:nil];
}

+(FCViewController *) getCategoryController:(FAQOptions *)options {
    FCViewController *controller = nil;
    if (options.showFaqCategoriesAsGrid) {
        controller = [[FCCategoryGridViewController alloc]init];
    }else{
        controller = [[FCCategoryListController alloc]init];
    }
    [FCFAQUtil setFAQOptions:options onController:controller];
    return controller;
}

@end
