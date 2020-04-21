//
//  FCAnimatedImage.m
//  Flipboard
//
//  Created by Raphael Schaad on 7/8/13.
//  Copyright (c) 2013-2015 Flipboard. All rights reserved.
//


#import "FCAnimatedImage.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>


// From vm_param.h, define for iOS 8.0 or higher to build on device.
#ifndef BYTE_SIZE
    #define BYTE_SIZE 8 // byte size in bits
#endif

#define MEGABYTE (1024 * 1024)

// This is how the fastest browsers do it as per 2012: http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser-compatibility
const NSTimeInterval kFLAnimatedImageDelayTimeIntervalMinimum = 0.02;

// An animated image's data size (dimensions * frameCount) category; its value is the max allowed memory (in MB).
// E.g.: A 100x200px GIF with 30 frames is ~2.3MB in our pixel format and would fall into the `FLAnimatedImageDataSizeCategoryAll` category.
typedef NS_ENUM(NSUInteger, FLAnimatedImageDataSizeCategory) {
    FLAnimatedImageDataSizeCategoryAll = 10,       // All frames permanently in memory (be nice to the CPU)
    FLAnimatedImageDataSizeCategoryDefault = 75,   // A frame cache of default size in memory (usually real-time performance and keeping low memory profile)
    FLAnimatedImageDataSizeCategoryOnDemand = 250, // Only keep one frame at the time in memory (easier on memory, slowest performance)
    FLAnimatedImageDataSizeCategoryUnsupported     // Even for one frame too large, computer says no.
};

typedef NS_ENUM(NSUInteger, FLAnimatedImageFrameCacheSize) {
    FLAnimatedImageFrameCacheSizeNoLimit = 0,                // 0 means no specific limit
    FLAnimatedImageFrameCacheSizeLowMemory = 1,              // The minimum frame cache size; this will produce frames on-demand.
    FLAnimatedImageFrameCacheSizeGrowAfterMemoryWarning = 2, // If we can produce the frames faster than we consume, one frame ahead will already result in a stutter-free playback.
    FLAnimatedImageFrameCacheSizeDefault = 5                 // Build up a comfy buffer window to cope with CPU hiccups etc.
};


#if defined(DEBUG) && DEBUG
@protocol FLAnimatedImageDebugDelegate <NSObject>
@optional
- (void)debug_animatedImage:(FCAnimatedImage *)animatedImage didUpdateCachedFrames:(NSIndexSet *)indexesOfFramesInCache;
- (void)debug_animatedImage:(FCAnimatedImage *)animatedImage didRequestCachedFrame:(NSUInteger)index;
- (CGFloat)debug_animatedImagePredrawingSlowdownFactor:(FCAnimatedImage *)animatedImage;
@end
#endif


@interface FCAnimatedImage ()

@property (nonatomic, assign, readonly) NSUInteger frameCacheSizeOptimal; // The optimal number of frames to cache based on image size & number of frames; never changes
@property (nonatomic, assign, readonly, getter=isPredrawingEnabled) BOOL predrawingEnabled; // Enables predrawing of images to improve performance.
@property (nonatomic, assign) NSUInteger frameCacheSizeMaxInternal; // Allow to cap the cache size e.g. when memory warnings occur; 0 means no specific limit (default)
@property (nonatomic, assign) NSUInteger requestedFrameIndex; // Most recently requested frame index
@property (nonatomic, assign, readonly) NSUInteger posterImageFrameIndex; // Index of non-purgable poster image; never changes
@property (nonatomic, strong, readonly) NSMutableDictionary *cachedFramesForIndexes;
@property (nonatomic, strong, readonly) NSMutableIndexSet *cachedFrameIndexes; // Indexes of cached frames
@property (nonatomic, strong, readonly) NSMutableIndexSet *requestedFrameIndexes; // Indexes of frames that are currently produced in the background
@property (nonatomic, strong, readonly) NSIndexSet *allFramesIndexSet; // Default index set with the full range of indexes; never changes
@property (nonatomic, assign) NSUInteger memoryWarningCount;
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t serialQueue; // this is for Xcode 4.5 with LLVM 4.1 and iOS 6 SDK
#else
@property (nonatomic, assign) dispatch_queue_t serialQueue; // this is for older Xcodes with older SDKs
#endif

@property (nonatomic, strong, readonly) __attribute__((NSObject)) CGImageSourceRef imageSource;

@property (nonatomic, strong, readonly) FCAnimatedImage *weakProxy;

#if defined(DEBUG) && DEBUG
@property (nonatomic, weak) id<FLAnimatedImageDebugDelegate> debug_delegate;
#endif

@end

static NSHashTable *allAnimatedImagesWeak;

@implementation FCAnimatedImage

#pragma mark - Accessors
#pragma mark Public

// This is the definite value the frame cache needs to size itself to.
- (NSUInteger)frameCacheSizeCurrent
{
    NSUInteger frameCacheSizeCurrent = self.frameCacheSizeOptimal;
    
    // If set, respect the caps.
    if (self.frameCacheSizeMax > FLAnimatedImageFrameCacheSizeNoLimit) {
        frameCacheSizeCurrent = MIN(frameCacheSizeCurrent, self.frameCacheSizeMax);
    }
    
    if (self.frameCacheSizeMaxInternal > FLAnimatedImageFrameCacheSizeNoLimit) {
        frameCacheSizeCurrent = MIN(frameCacheSizeCurrent, self.frameCacheSizeMaxInternal);
    }
    
    return frameCacheSizeCurrent;
}


- (void)setFrameCacheSizeMax:(NSUInteger)frameCacheSizeMax
{
    if (_frameCacheSizeMax != frameCacheSizeMax) {
        BOOL willFrameCacheSizeShrink = (frameCacheSizeMax < self.frameCacheSizeCurrent);
        
        // Update the value
        _frameCacheSizeMax = frameCacheSizeMax;
        
        if (willFrameCacheSizeShrink) {
            [self purgeFrameCacheIfNeeded];
        }
    }
}


#pragma mark Private

- (void)setFrameCacheSizeMaxInternal:(NSUInteger)frameCacheSizeMaxInternal
{
    if (_frameCacheSizeMaxInternal != frameCacheSizeMaxInternal) {
        BOOL willFrameCacheSizeShrink = (frameCacheSizeMaxInternal < self.frameCacheSizeCurrent);
        
        _frameCacheSizeMaxInternal = frameCacheSizeMaxInternal;
        
        if (willFrameCacheSizeShrink) {
            [self purgeFrameCacheIfNeeded];
        }
    }
}


#pragma mark - Life Cycle

+ (void)initialize
{
    if (self == [FCAnimatedImage class]) {
        // UIKit memory warning notification handler shared by all of the instances
        allAnimatedImagesWeak = [NSHashTable weakObjectsHashTable];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSAssert([NSThread isMainThread], @"Received memory warning on non-main thread");
            
            NSArray *images = nil;
            @synchronized(allAnimatedImagesWeak) {
                images = [[allAnimatedImagesWeak allObjects] copy];
            }
            [images makeObjectsPerformSelector:@selector(didReceiveMemoryWarning:) withObject:note];
        }];
    }
}


- (instancetype)init
{
    FCAnimatedImage *animatedImage = [self initWithAnimatedGIFData:nil];
    if (!animatedImage) {
    }
    return animatedImage;
}


- (instancetype)initWithAnimatedGIFData:(NSData *)data
{
    return [self initWithAnimatedGIFData:data optimalFrameCacheSize:0 predrawingEnabled:YES];
}

- (instancetype)initWithAnimatedGIFData:(NSData *)data optimalFrameCacheSize:(NSUInteger)optimalFrameCacheSize predrawingEnabled:(BOOL)isPredrawingEnabled
{
    // Early return if no data supplied!
    BOOL hasData = ([data length] > 0);
    if (!hasData) {
        FCLog(FLLogLevelError, @"No animated GIF data supplied.");
        return nil;
    }
    
    self = [super init];
    if (self) {
        _data = data;
        _predrawingEnabled = isPredrawingEnabled;
        
        // Initialize internal data structures
        _cachedFramesForIndexes = [[NSMutableDictionary alloc] init];
        _cachedFrameIndexes = [[NSMutableIndexSet alloc] init];
        _requestedFrameIndexes = [[NSMutableIndexSet alloc] init];

        _imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data,
                                                   (__bridge CFDictionaryRef)@{(NSString *)kCGImageSourceShouldCache: @NO});
        // Early return on failure!
        if (!_imageSource) {
            return nil;
        }
        
        // Early return if not GIF!
        CFStringRef imageSourceContainerType = CGImageSourceGetType(_imageSource);
        BOOL isGIFData = UTTypeConformsTo(imageSourceContainerType, kUTTypeGIF);
        if (!isGIFData) {
            return nil;
        }
        
        NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(_imageSource, NULL);
        _loopCount = [[[imageProperties objectForKey:(id)kCGImagePropertyGIFDictionary] objectForKey:(id)kCGImagePropertyGIFLoopCount] unsignedIntegerValue];
        
        // Iterate through frame images
        size_t imageCount = CGImageSourceGetCount(_imageSource);
        NSUInteger skippedFrameCount = 0;
        NSMutableDictionary *delayTimesForIndexesMutable = [NSMutableDictionary dictionaryWithCapacity:imageCount];
        for (size_t i = 0; i < imageCount; i++) {
            @autoreleasepool {
                CGImageRef frameImageRef = CGImageSourceCreateImageAtIndex(_imageSource, i, NULL);
                if (frameImageRef) {
                    UIImage *frameImage = [UIImage imageWithCGImage:frameImageRef];
                    if (frameImage) {
                        // Set poster image
                        if (!self.posterImage) {
                            _posterImage = frameImage;
                            // Set its size to proxy our size.
                            _size = _posterImage.size;
                            _posterImageFrameIndex = i;
                            [self.cachedFramesForIndexes setObject:self.posterImage forKey:@(self.posterImageFrameIndex)];
                            [self.cachedFrameIndexes addIndex:self.posterImageFrameIndex];
                        }
                        
                        NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(_imageSource, i, NULL);
                        NSDictionary *framePropertiesGIF = [frameProperties objectForKey:(id)kCGImagePropertyGIFDictionary];
                        
                        // Try to use the unclamped delay time; fall back to the normal delay time.
                        NSNumber *delayTime = [framePropertiesGIF objectForKey:(id)kCGImagePropertyGIFUnclampedDelayTime];
                        if (!delayTime) {
                            delayTime = [framePropertiesGIF objectForKey:(id)kCGImagePropertyGIFDelayTime];
                        }
                        const NSTimeInterval kDelayTimeIntervalDefault = 0.1;
                        if (!delayTime) {
                            if (i == 0) {
                                delayTime = @(kDelayTimeIntervalDefault);
                            } else {
                                delayTime = delayTimesForIndexesMutable[@(i - 1)];
                            }
                        }
                        if ([delayTime floatValue] < ((float)kFLAnimatedImageDelayTimeIntervalMinimum - FLT_EPSILON)) {
                            delayTime = @(kDelayTimeIntervalDefault);
                        }
                        delayTimesForIndexesMutable[@(i)] = delayTime;
                    } else {
                        skippedFrameCount++;
                    }
                    CFRelease(frameImageRef);
                } else {
                    skippedFrameCount++;
                }
            }
        }
        _delayTimesForIndexes = [delayTimesForIndexesMutable copy];
        _frameCount = imageCount;
        
        if (self.frameCount == 0) {
            return nil;
        } else if (self.frameCount == 1) {
        } else {
            // We have multiple frames, rock on!
        }
        
        if (optimalFrameCacheSize == 0) {
            CGFloat animatedImageDataSize = CGImageGetBytesPerRow(self.posterImage.CGImage) * self.size.height * (self.frameCount - skippedFrameCount) / MEGABYTE;
            if (animatedImageDataSize <= FLAnimatedImageDataSizeCategoryAll) {
                _frameCacheSizeOptimal = self.frameCount;
            } else if (animatedImageDataSize <= FLAnimatedImageDataSizeCategoryDefault) {
                _frameCacheSizeOptimal = FLAnimatedImageFrameCacheSizeDefault;
            } else {
                _frameCacheSizeOptimal = FLAnimatedImageFrameCacheSizeLowMemory;
            }
        } else {
            // Use the provided value.
            _frameCacheSizeOptimal = optimalFrameCacheSize;
        }
        // In any case, cap the optimal cache size at the frame count.
        _frameCacheSizeOptimal = MIN(_frameCacheSizeOptimal, self.frameCount);
        
        _allFramesIndexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, self.frameCount)];
        
        _weakProxy = (id)[FLWeakProxy weakProxyForObject:self];
        
        @synchronized(allAnimatedImagesWeak) {
            [allAnimatedImagesWeak addObject:self];
        }
    }
    return self;
}


+ (instancetype)animatedImageWithGIFData:(NSData *)data
{
    FCAnimatedImage *animatedImage = [[FCAnimatedImage alloc] initWithAnimatedGIFData:data];
    return animatedImage;
}


- (void)dealloc
{
    if (_weakProxy) {
        [NSObject cancelPreviousPerformRequestsWithTarget:_weakProxy];
    }
    
    if (_imageSource) {
        CFRelease(_imageSource);
    }
}


#pragma mark - Public Methods

- (UIImage *)imageLazilyCachedAtIndex:(NSUInteger)index
{
    if (index >= self.frameCount) {
        return nil;
    }
    
    self.requestedFrameIndex = index;
#if defined(DEBUG) && DEBUG
    if ([self.debug_delegate respondsToSelector:@selector(debug_animatedImage:didRequestCachedFrame:)]) {
        [self.debug_delegate debug_animatedImage:self didRequestCachedFrame:index];
    }
#endif
    
    // Quick check to avoid doing any work if we already have all possible frames cached, a common case.
    if ([self.cachedFrameIndexes count] < self.frameCount) {
        NSMutableIndexSet *frameIndexesToAddToCacheMutable = [self frameIndexesToCache];
        [frameIndexesToAddToCacheMutable removeIndexes:self.cachedFrameIndexes];
        [frameIndexesToAddToCacheMutable removeIndexes:self.requestedFrameIndexes];
        [frameIndexesToAddToCacheMutable removeIndex:self.posterImageFrameIndex];
        NSIndexSet *frameIndexesToAddToCache = [frameIndexesToAddToCacheMutable copy];
        
        // Asynchronously add frames to our cache.
        if ([frameIndexesToAddToCache count] > 0) {
            [self addFrameIndexesToCache:frameIndexesToAddToCache];
        }
    }
    
    // Get the specified image.
    UIImage *image = self.cachedFramesForIndexes[@(index)];
    
    // Purge if needed based on the current playhead position.
    [self purgeFrameCacheIfNeeded];
    
    return image;
}

- (void)addFrameIndexesToCache:(NSIndexSet *)frameIndexesToAddToCache
{
    NSRange firstRange = NSMakeRange(self.requestedFrameIndex, self.frameCount - self.requestedFrameIndex);
    NSRange secondRange = NSMakeRange(0, self.requestedFrameIndex);
    if (firstRange.length + secondRange.length != self.frameCount) {
        FCLog(FLLogLevelWarn, @"Two-part frame cache range doesn't equal full range.");
    }
    
    // Add to the requested list before we actually kick them off, so they don't get into the queue twice.
    [self.requestedFrameIndexes addIndexes:frameIndexesToAddToCache];
    
    if (!self.serialQueue) {
        _serialQueue = dispatch_queue_create("com.freshworks.freshchat.animatecachingqueue", DISPATCH_QUEUE_SERIAL);
    }
    
    FCAnimatedImage * __weak weakSelf = self;
    dispatch_async(self.serialQueue, ^{
        // Produce and cache next needed frame.
        void (^frameRangeBlock)(NSRange, BOOL *) = ^(NSRange range, BOOL *stop) {
            for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
#if defined(DEBUG) && DEBUG
                CFTimeInterval predrawBeginTime = CACurrentMediaTime();
#endif
                UIImage *image = [weakSelf imageAtIndex:i];
#if defined(DEBUG) && DEBUG
                CFTimeInterval predrawDuration = CACurrentMediaTime() - predrawBeginTime;
                CFTimeInterval slowdownDuration = 0.0;
                if ([self.debug_delegate respondsToSelector:@selector(debug_animatedImagePredrawingSlowdownFactor:)]) {
                    CGFloat predrawingSlowdownFactor = [self.debug_delegate debug_animatedImagePredrawingSlowdownFactor:self];
                    slowdownDuration = predrawDuration * predrawingSlowdownFactor - predrawDuration;
                    [NSThread sleepForTimeInterval:slowdownDuration];
                }
                
#endif
                
                if (image && weakSelf) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.cachedFramesForIndexes[@(i)] = image;
                        [weakSelf.cachedFrameIndexes addIndex:i];
                        [weakSelf.requestedFrameIndexes removeIndex:i];
#if defined(DEBUG) && DEBUG
                        if ([weakSelf.debug_delegate respondsToSelector:@selector(debug_animatedImage:didUpdateCachedFrames:)]) {
                            [weakSelf.debug_delegate debug_animatedImage:weakSelf didUpdateCachedFrames:weakSelf.cachedFrameIndexes];
                        }
#endif
                    });
                }
            }
        };
        
        [frameIndexesToAddToCache enumerateRangesInRange:firstRange options:0 usingBlock:frameRangeBlock];
        [frameIndexesToAddToCache enumerateRangesInRange:secondRange options:0 usingBlock:frameRangeBlock];
    });
}


+ (CGSize)sizeForImage:(id)image
{
    CGSize imageSize = CGSizeZero;
    
    if (!image) {
        return imageSize;
    }
    
    if ([image isKindOfClass:[UIImage class]]) {
        UIImage *uiImage = (UIImage *)image;
        imageSize = uiImage.size;
    } else if ([image isKindOfClass:[FCAnimatedImage class]]) {
        FCAnimatedImage *animatedImage = (FCAnimatedImage *)image;
        imageSize = animatedImage.size;
    } else {
        // Bear trap to capture bad images; we have seen crashers cropping up on iOS 7.
        FCLog(FLLogLevelError, @"`image` isn't of expected types `UIImage` or `FLAnimatedImage`: %@", image);
    }
    
    return imageSize;
}


#pragma mark - Private Methods
#pragma mark Frame Loading

- (UIImage *)imageAtIndex:(NSUInteger)index
{
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSource, index, NULL);

    // Early return for nil
    if (!imageRef) {
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CFRelease(imageRef);
    
    if (self.isPredrawingEnabled) {
        image = [[self class] predrawnImageFromImage:image];
    }
    
    return image;
}


#pragma mark Frame Caching

- (NSMutableIndexSet *)frameIndexesToCache
{
    NSMutableIndexSet *indexesToCache = nil;
    if (self.frameCacheSizeCurrent == self.frameCount) {
        indexesToCache = [self.allFramesIndexSet mutableCopy];
    } else {
        indexesToCache = [[NSMutableIndexSet alloc] init];
        
        NSUInteger firstLength = MIN(self.frameCacheSizeCurrent, self.frameCount - self.requestedFrameIndex);
        NSRange firstRange = NSMakeRange(self.requestedFrameIndex, firstLength);
        [indexesToCache addIndexesInRange:firstRange];
        NSUInteger secondLength = self.frameCacheSizeCurrent - firstLength;
        if (secondLength > 0) {
            NSRange secondRange = NSMakeRange(0, secondLength);
            [indexesToCache addIndexesInRange:secondRange];
        }
        // Double check our math, before we add the poster image index which may increase it by one.
        if ([indexesToCache count] != self.frameCacheSizeCurrent) {
            FCLog(FLLogLevelWarn, @"Number of frames to cache doesn't equal expected cache size.");
        }
        
        [indexesToCache addIndex:self.posterImageFrameIndex];
    }
    
    return indexesToCache;
}


- (void)purgeFrameCacheIfNeeded
{
    if ([self.cachedFrameIndexes count] > self.frameCacheSizeCurrent) {
        NSMutableIndexSet *indexesToPurge = [self.cachedFrameIndexes mutableCopy];
        [indexesToPurge removeIndexes:[self frameIndexesToCache]];
        [indexesToPurge enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
            // Iterate through contiguous indexes; can be faster than `enumerateIndexesInRange:options:usingBlock:`.
            for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
                [self.cachedFrameIndexes removeIndex:i];
                [self.cachedFramesForIndexes removeObjectForKey:@(i)];
                // Note: Don't `CGImageSourceRemoveCacheAtIndex` on the image source for frames that we don't want cached any longer to maintain O(1) time access.
#if defined(DEBUG) && DEBUG
                if ([self.debug_delegate respondsToSelector:@selector(debug_animatedImage:didUpdateCachedFrames:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.debug_delegate debug_animatedImage:self didUpdateCachedFrames:self.cachedFrameIndexes];
                    });
                }
#endif
            }
        }];
    }
}


- (void)growFrameCacheSizeAfterMemoryWarning:(NSNumber *)frameCacheSize
{
    self.frameCacheSizeMaxInternal = [frameCacheSize unsignedIntegerValue];
    const NSTimeInterval kResetDelay = 3.0;
    [self.weakProxy performSelector:@selector(resetFrameCacheSizeMaxInternal) withObject:nil afterDelay:kResetDelay];
}


- (void)resetFrameCacheSizeMaxInternal
{
    self.frameCacheSizeMaxInternal = FLAnimatedImageFrameCacheSizeNoLimit;
}


#pragma mark System Memory Warnings Notification Handler

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    self.memoryWarningCount++;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self.weakProxy selector:@selector(growFrameCacheSizeAfterMemoryWarning:) object:@(FLAnimatedImageFrameCacheSizeGrowAfterMemoryWarning)];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.weakProxy selector:@selector(resetFrameCacheSizeMaxInternal) object:nil];
    
    self.frameCacheSizeMaxInternal = FLAnimatedImageFrameCacheSizeLowMemory;
    
    const NSUInteger kGrowAttemptsMax = 2;
    const NSTimeInterval kGrowDelay = 2.0;
    if ((self.memoryWarningCount - 1) <= kGrowAttemptsMax) {
        [self.weakProxy performSelector:@selector(growFrameCacheSizeAfterMemoryWarning:) withObject:@(FLAnimatedImageFrameCacheSizeGrowAfterMemoryWarning) afterDelay:kGrowDelay];
    }
    
    // Note: It's not possible to get the level of a memory warning with a public API: http://stackoverflow.com/questions/2915247/iphone-os-memory-warnings-what-do-the-different-levels-mean/2915477#2915477
}


#pragma mark Image Decoding

+ (UIImage *)predrawnImageFromImage:(UIImage *)imageToPredraw
{
    CGColorSpaceRef colorSpaceDeviceRGBRef = CGColorSpaceCreateDeviceRGB();
    
    if (!colorSpaceDeviceRGBRef) {
        FCLog(FLLogLevelError, @"Failed to `CGColorSpaceCreateDeviceRGB` for image %@", imageToPredraw);
        return imageToPredraw;
    }
    
    size_t numberOfComponents = CGColorSpaceGetNumberOfComponents(colorSpaceDeviceRGBRef) + 1; // 4: RGB + A
    
    // "In iOS 4.0 and later, and OS X v10.6 and later, you can pass NULL if you want Quartz to allocate memory for the bitmap." (source: docs)
    void *data = NULL;
    size_t width = imageToPredraw.size.width;
    size_t height = imageToPredraw.size.height;
    size_t bitsPerComponent = CHAR_BIT;
    
    size_t bitsPerPixel = (bitsPerComponent * numberOfComponents);
    size_t bytesPerPixel = (bitsPerPixel / BYTE_SIZE);
    size_t bytesPerRow = (bytesPerPixel * width);
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageToPredraw.CGImage);
    
    if (alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaOnly) {
        alphaInfo = kCGImageAlphaNoneSkipFirst;
    } else if (alphaInfo == kCGImageAlphaFirst) {
        alphaInfo = kCGImageAlphaPremultipliedFirst;
    } else if (alphaInfo == kCGImageAlphaLast) {
        alphaInfo = kCGImageAlphaPremultipliedLast;
    }
    bitmapInfo |= alphaInfo;
    
    CGContextRef bitmapContextRef = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpaceDeviceRGBRef, bitmapInfo);
    CGColorSpaceRelease(colorSpaceDeviceRGBRef);
    // Early return on failure!
    if (!bitmapContextRef) {
        return imageToPredraw;
    }
    
    // Draw image in bitmap context and create image by preserving receiver's properties.
    CGContextDrawImage(bitmapContextRef, CGRectMake(0.0, 0.0, imageToPredraw.size.width, imageToPredraw.size.height), imageToPredraw.CGImage);
    CGImageRef predrawnImageRef = CGBitmapContextCreateImage(bitmapContextRef);
    UIImage *predrawnImage = [UIImage imageWithCGImage:predrawnImageRef scale:imageToPredraw.scale orientation:imageToPredraw.imageOrientation];
    CGImageRelease(predrawnImageRef);
    CGContextRelease(bitmapContextRef);
    
    // Early return on failure!
    if (!predrawnImage) {
        return imageToPredraw;
    }
    
    return predrawnImage;
}


#pragma mark - Description

- (NSString *)description
{
    NSString *description = [super description];
    
    description = [description stringByAppendingFormat:@" size=%@", NSStringFromCGSize(self.size)];
    description = [description stringByAppendingFormat:@" frameCount=%lu", (unsigned long)self.frameCount];
    
    return description;
}


@end

#pragma mark - Logging

@implementation FCAnimatedImage (Logging)

static void (^_logBlock)(NSString *logString, FLLogLevel logLevel) = nil;
static FLLogLevel _logLevel;

+ (void)setLogBlock:(void (^)(NSString *logString, FLLogLevel logLevel))logBlock logLevel:(FLLogLevel)logLevel
{
    _logBlock = logBlock;
    _logLevel = logLevel;
}

+ (void)logStringFromBlock:(NSString *(^)(void))stringBlock withLevel:(FLLogLevel)level
{
    if (level <= _logLevel && _logBlock && stringBlock) {
        _logBlock(stringBlock(), level);
    }
}

@end


#pragma mark - FLWeakProxy

@interface FLWeakProxy ()

@property (nonatomic, weak) id target;

@end


@implementation FLWeakProxy

#pragma mark Life Cycle

+ (instancetype)weakProxyForObject:(id)targetObject
{
    FLWeakProxy *weakProxy = [FLWeakProxy alloc];
    weakProxy.target = targetObject;
    return weakProxy;
}


#pragma mark Forwarding Messages

- (id)forwardingTargetForSelector:(SEL)selector
{
    return _target;
}


#pragma mark - NSWeakProxy Method Overrides
#pragma mark Handling Unimplemented Methods

- (void)forwardInvocation:(NSInvocation *)invocation
{
    void *nullPointer = NULL;
    [invocation setReturnValue:&nullPointer];
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}


@end
