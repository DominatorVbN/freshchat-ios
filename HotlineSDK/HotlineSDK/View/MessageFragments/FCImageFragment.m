//
//  FDImageFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCImageFragment.h"
#import "FCImagePreviewController.h"
#import "FCAnimatedImage.h"
#import "FDImageView.h"
#import "FCUtilities.h"

#define DEFAULT_THUMBNAIL_HEIGHT 225
#define DEFAULT_THUMBNAIL_WIDTH 225

#define MIN_THUMBNAIL_HEIGHT 75
#define MIN_THUMBNAIL_WIDTH 75


@implementation FCImageFragment

    -(id) initWithFragment: (FragmentData *) fragment ofMessage:(FCMessageData*)message {
        self = [super init];
        if(self) {
            self.fragmentData = fragment;
            self.contentMode = UIViewContentModeScaleAspectFit;
            self.translatesAutoresizingMaskIntoConstraints = NO;
            self.clipsToBounds = YES;
            self.backgroundColor = [UIColor clearColor];
            self.userInteractionEnabled = YES;
            NSData *extraJSONData = [fragment.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
            __block BOOL imageToBeDownloaded = true;
            int thumbnailHeight = DEFAULT_THUMBNAIL_HEIGHT;
            int thumbnailWidth =  DEFAULT_THUMBNAIL_WIDTH ;
            self.imgFrame = CGRectMake(0, 0, thumbnailWidth, thumbnailHeight);
            BOOL isThumbnail = extraJSONDict[@"thumbnail"] != nil;
            if ( (!fragment.binaryData1 && !isThumbnail) || (!fragment.binaryData2 && isThumbnail)) { //Data needed to be downloaded
                [fragment storeImageDataOfMessage:message withCompletion:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageToBeDownloaded = false;
                        [self setImageFromFragmentData:fragment ifAvailable:imageToBeDownloaded andIsThumbnail:isThumbnail];
                    });
                }];
            } else {
                imageToBeDownloaded = false;
            }
            if(isThumbnail) {
                NSDictionary *thumbnailDict = extraJSONDict[@"thumbnail"];
                
                if(thumbnailDict[@"height"] && thumbnailDict[@"width"]) {
                    if ([thumbnailDict[@"height"] intValue] <= DEFAULT_THUMBNAIL_HEIGHT) {
                        thumbnailHeight = [thumbnailDict[@"height"] intValue];
                    }
                    if([thumbnailDict[@"height"] intValue] <= MIN_THUMBNAIL_HEIGHT) {
                        thumbnailHeight = MIN_THUMBNAIL_HEIGHT;
                    }
                    
                    if ([thumbnailDict[@"width"] intValue] <= DEFAULT_THUMBNAIL_WIDTH) {
                        thumbnailWidth = [thumbnailDict[@"width"] intValue];
                    }
                    if([thumbnailDict[@"width"] intValue] <= MIN_THUMBNAIL_WIDTH) {
                        thumbnailWidth = MIN_THUMBNAIL_WIDTH;
                    }
                    self.imgFrame = CGRectMake(0, 0, thumbnailWidth, thumbnailHeight);
                }
            }
            [self setImageFromFragmentData:fragment ifAvailable:imageToBeDownloaded andIsThumbnail:isThumbnail];
            [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(showImagePreview:)]];
        }
        return self;
    }

- (void) setImageFromFragmentData : (FragmentData*) data ifAvailable :(BOOL)isAvail andIsThumbnail: (BOOL) isThumbnail  {
    if (isAvail) {
        [self setImage:[[FCTheme sharedInstance ] getImageWithKey:IMAGE_PLACEHOLDER]];
        //NSLog(@"FRAGMENT::Setting the PLACEHOLDER::::");
    } else {
        NSData * imageData = isThumbnail ? data.binaryData2 : data.binaryData1;
        if ([[FCUtilities contentTypeForImageData:imageData] isEqualToString:@"image/gif"] || [data.contentType isEqualToString: @"image/gif"]) {
            self.animatedImage = [FCAnimatedImage animatedImageWithGIFData:data.binaryData1];
        }
        else{
            [self setImage:[UIImage imageWithData: imageData]];
        }
    }
}

    -(void) showImagePreview:(id) sender {
        if (self.delegate != nil) {
            [self.delegate performActionOn:self.fragmentData];
        }
    }
@end
