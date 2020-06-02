//
//  KonotorImageInput.m
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 10/03/14.
//  Copyright (c) 2014 Demach. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FCImageInput.h"
#import <QuartzCore/QuartzCore.h>
#import "FCAttachmentImageController.h"
#import "FCMacros.h"
#import "FCLocalization.h"
#import "FCSecureStore.h"
#import "FCRemoteConfig.h"
#import "FCUserUtil.h"
#import "Photos/Photos.h"
#import "FCUtilities.h"

@interface FCImageInput () <FDAttachmentImageControllerDelegate, UIPopoverPresentationControllerDelegate>{
    BOOL isCameraCaptureEnabled;
    BOOL isGallerySelectionEnabled;
}

@property (weak, nonatomic) UIView* sourceView;
@property (weak, nonatomic) UIViewController* sourceViewController;
@property (strong, nonatomic) NSData* pickedImageData;
@property (strong, nonatomic) UIPopoverPresentationController* popover;

@property (nonatomic, strong) FCConversations *conversation;
@property (nonatomic, strong) FCChannels *channel;
@property (nonatomic, strong) FCAttachmentImageController *imageController;
@property (nonatomic, strong) UIAlertController *inputOptions;

@end

@implementation FCImageInput

@synthesize sourceView,sourceViewController,pickedImageData,popover;

- (instancetype)initWithConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.channel = channel;
    }
    return self;
}

- (void) showInputOptions:(UIViewController*) viewController{
   
    if(![[FCRemoteConfig sharedInstance] isActiveInboxAndAccount]){
        return;
    }
    FCSecureStore *store = [FCSecureStore sharedInstance];
    isCameraCaptureEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
    isGallerySelectionEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_GALLERY_SELECTION_ENABLED];

    self.inputOptions = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    if(isGallerySelectionEnabled){
        [self.inputOptions addAction:[UIAlertAction actionWithTitle:HLLocalizedString(LOC_IMAGE_ATTACHMENT_EXISTING_IMAGE_BUTTON_TEXT) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self checkLibraryAccessPermission];
        }]];
    }
    if(isCameraCaptureEnabled){
        [self.inputOptions addAction:[UIAlertAction actionWithTitle:HLLocalizedString(LOC_IMAGE_ATTACHMENT_NEW_IMAGE_BUTTON_TEXT) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self checkCameraCapturePermission];
        }]];
    }
    
    [self.inputOptions addAction:[UIAlertAction actionWithTitle:HLLocalizedString(LOC_IMAGE_ATTACHMENT_CANCEL_BUTTON_TEXT) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.inputOptions dismissViewControllerAnimated:true completion:nil];
    }]];
    
    
    self.sourceViewController=viewController;
    self.sourceView=viewController.view;
    popover = [self.inputOptions popoverPresentationController];
    popover.delegate = self;
    [popover setPermittedArrowDirections:UIPopoverArrowDirectionDown];
    [self.inputOptions setModalPresentationStyle:UIModalPresentationPopover];
    [viewController presentViewController:self.inputOptions animated:true completion:nil];
}

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    popover.sourceView = self.sourceView;
    CGRect rectInView = CGRectMake(self.sourceViewController.view.frame.origin.x,self.sourceViewController.view.frame.origin.y+sourceViewController.view.frame.size.height-20,40,40);
    popover.sourceRect = CGRectMake(CGRectGetMidX(rectInView), CGRectGetMaxY(rectInView)-40, 1, 1);
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView  * __nonnull * __nonnull)view
{
    CGRect rectInView = CGRectMake(self.sourceViewController.view.frame.origin.x,self.sourceViewController.view.frame.origin.y+sourceViewController.view.frame.size.height-20,40,40);
    *rect = CGRectMake(CGRectGetMidX(rectInView), CGRectGetMaxY(rectInView)-40, 1, 1);
    *view = self.sourceViewController.view;
}

- (void)checkCameraCapturePermission{
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusAuthorized) {
        [self showCamPicker];
    } else if(status == AVAuthorizationStatusDenied){
        // denied
        [self showAccessDeniedAlert];
    } else if(status == AVAuthorizationStatusRestricted){
        // restricted
        [self showAccessDeniedAlert];
    } else if(status == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){
                //user granted
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showCamPicker];
                });
                
            } else {
                //user denied
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showAccessDeniedAlert];
                });
            }
        }];
    }
}

- (void)checkLibraryAccessPermission{
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusAuthorized) {
        [self showImagePicker];
    }
    
    else if (status == PHAuthorizationStatusDenied) {
        [self showLibAccessDeniedAlert];
    }
    
    else if (status == PHAuthorizationStatusNotDetermined) {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self checkLibraryAccessPermission];
            });
        }];
    }
    
    else if (status == PHAuthorizationStatusRestricted) {
        // Restricted access - normally won't happen.
        [self showLibAccessDeniedAlert];
    }
}

- (void) showAccessDeniedAlert{
    [FCUtilities showAlertViewWithTitle:nil
                                message:HLLocalizedString(LOC_CAMERA_PERMISSION_DENIED_TEXT)
                          andCancelText:HLLocalizedString(LOC_CAMERA_PERMISSION_ALERT_CANCEL)
                           inController:self.sourceViewController];
}

- (void) showLibAccessDeniedAlert{
    [FCUtilities showAlertViewWithTitle:nil
                                message:HLLocalizedString(LOC_PHOTO_LIBRARY_PERMISSION_DENIED_TEXT)
                          andCancelText:HLLocalizedString(LOC_PHOTO_LIBRARY_PERMISSION_ALERT_CANCEL)
                           inController:self.sourceViewController];
}

- (void)showImagePicker{
    UIImagePickerController* imagePicker=[[UIImagePickerController alloc] init];
    imagePicker.delegate=self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = NO;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        [imagePicker setModalPresentationStyle:UIModalPresentationPopover];
        popover=[imagePicker popoverPresentationController];
        [popover setPermittedArrowDirections:UIPopoverArrowDirectionDown];
        popover.sourceView = self.sourceView;
        popover.delegate = self;
    }else{
        [imagePicker setModalPresentationStyle:UIModalPresentationFullScreen];
    }
    [self.sourceViewController presentViewController:imagePicker animated:YES completion:NULL];
}

- (void)showCamPicker{
    
    UIImagePickerController* imagePicker=[[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.sourceViewController presentViewController:imagePicker animated:YES completion:NULL];
            
        });
    }else{
        [FCUtilities showAlertViewWithTitle:HLLocalizedString(LOC_CAMERA_UNAVAILABLE_TITLE)
                                    message:HLLocalizedString(LOC_CAMERA_UNAVAILABLE_DESCRIPTION)
                              andCancelText:HLLocalizedString(LOC_CAMERA_UNAVAILABLE_OK_BUTTON)
                               inController:self.sourceViewController];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:NO completion:nil];
    NSURL * refUrl = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (refUrl) {
        PHAsset * asset = [[PHAsset fetchAssetsWithALAssetURLs:@[refUrl] options:nil] lastObject];
        if (asset) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.synchronous = YES;
            options.networkAccessAllowed = NO;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                NSNumber * isError = [info objectForKey:PHImageErrorKey];
                NSNumber * isCloud = [info objectForKey:PHImageResultIsInCloudKey];
                if ([isError boolValue] || [isCloud boolValue] || ! imageData) {
                    ALog("Image picking failed, please try later!");
                } else {
                    [self presentAttachmentControllerWithData:imageData];
                }
            }];
        }
    } else {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (image) {
            [self presentAttachmentControllerWithData:UIImageJPEGRepresentation(image,0.5)];
        }
    }
}

-(void)presentAttachmentControllerWithData:(NSData*) imageData {
    self.imageController = [[FCAttachmentImageController alloc]initWithImageData:imageData];
    self.imageController.delegate = self;
    self.pickedImageData = imageData;
    UINavigationController *navcontroller = [[UINavigationController alloc] initWithRootViewController:self.imageController];
    [navcontroller setModalPresentationStyle:UIModalPresentationFullScreen];
    [self.sourceViewController presentViewController:navcontroller animated:YES completion:nil];
}

- (void) dismissAttachmentActionSheet{
    [self.inputOptions dismissModalViewControllerAnimated:false];
}

-(void)attachmentController:(FCAttachmentImageController *)controller didFinishImgWithCaption:(NSString *)caption {
    
    [FCMessageHelper uploadMessageWithImageData:self.pickedImageData textFeed:caption onConversation:self.conversation andChannel:self.channel];
}

@end
