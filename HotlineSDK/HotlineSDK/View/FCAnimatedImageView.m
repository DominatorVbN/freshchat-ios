//
//  FCAnimatedImageView.h
//  Flipboard
//
//  Created by Raphael Schaad on 7/8/13.
//  Copyright (c) 2013-2015 Flipboard. All rights reserved.
//


#import "FCAnimatedImageView.h"
#import "FCAnimatedImage.h"
#import <QuartzCore/QuartzCore.h>
#import "FCMacros.h"


#if defined(DEBUG) && DEBUG
@protocol FCAnimatedImageViewDebugDelegate <NSObject>
@optional
- (void)debug_animatedImageView:(FCAnimatedImageView *)animatedImageView waitingForFrame:(NSUInteger)index duration:(NSTimeInterval)duration;
@end
#endif


@interface FCAnimatedImageView ()

// Override of public `readonly` properties as private `readwrite`
@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;

@property (nonatomic, assign) NSUInteger loopCountdown;
@property (nonatomic, assign) NSTimeInterval accumulator;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) BOOL shouldAnimate; // Before checking this value, call `-updateShouldAnimate` whenever the animated image or visibility (window, superview, hidden, alpha) has changed.
@property (nonatomic, assign) BOOL needsDisplayWhenImageBecomesAvailable;

#if defined(DEBUG) && DEBUG
@property (nonatomic, weak) id<FCAnimatedImageViewDebugDelegate> debug_delegate;
#endif

@end


@implementation FCAnimatedImageView
@synthesize runLoopMode = _runLoopMode;

#pragma mark - Initializers

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    self = [super initWithImage:image highlightedImage:highlightedImage];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.runLoopMode = [[self class] defaultRunLoopMode];
    
    if (@available(iOS 11.0, *)) {
        self.accessibilityIgnoresInvertColors = YES;
    }
}


#pragma mark - Accessors
#pragma mark Public

- (void)setAnimatedImage:(FCAnimatedImage *)animatedImage
{
    if (![_animatedImage isEqual:animatedImage]) {
        if (animatedImage) {
            super.image = nil;
            super.highlighted = NO;
            [self invalidateIntrinsicContentSize];
        } else {
            [self stopAnimating];
        }
        
        _animatedImage = animatedImage;
        
        self.currentFrame = animatedImage.posterImage;
        self.currentFrameIndex = 0;
        if (animatedImage.loopCount > 0) {
            self.loopCountdown = animatedImage.loopCount;
        } else {
            self.loopCountdown = NSUIntegerMax;
        }
        self.accumulator = 0.0;
        
        // Start animating after the new animated image has been set.
        [self updateShouldAnimate];
        if (self.shouldAnimate) {
            [self startAnimating];
        }
        
        [self.layer setNeedsDisplay];
    }
}


#pragma mark - Life Cycle

- (void)dealloc
{
    [_displayLink invalidate];
}


#pragma mark - UIView Method Overrides
#pragma mark Observing View-Related Changes

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}


- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];

    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];

    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}


#pragma mark Auto Layout

- (CGSize)intrinsicContentSize
{
    CGSize intrinsicContentSize = [super intrinsicContentSize];
    if (self.animatedImage) {
        intrinsicContentSize = self.image.size;
    }
    
    return intrinsicContentSize;
}

#pragma mark Smart Invert Colors

#pragma mark - UIImageView Method Overrides
#pragma mark Image Data

- (UIImage *)image
{
    UIImage *image = nil;
    if (self.animatedImage) {
        // Initially set to the poster image.
        image = self.currentFrame;
    } else {
        image = super.image;
    }
    return image;
}


- (void)setImage:(UIImage *)image
{
    if (image) {
        self.animatedImage = nil;
    }
    
    super.image = image;
}


#pragma mark Animating Images

- (NSTimeInterval)frameDelayGreatestCommonDivisor
{
    const NSTimeInterval kGreatestCommonDivisorPrecision = 2.0 / kFCAnimatedImageDelayTimeIntervalMinimum;

    NSArray *delays = self.animatedImage.delayTimesForIndexes.allValues;

    NSUInteger scaledGCD = lrint([delays.firstObject floatValue] * kGreatestCommonDivisorPrecision);
    for (NSNumber *value in delays) {
        scaledGCD = gcd(lrint([value floatValue] * kGreatestCommonDivisorPrecision), scaledGCD);
    }
    return scaledGCD / kGreatestCommonDivisorPrecision;
}


static NSUInteger gcd(NSUInteger a, NSUInteger b)
{
    // http://en.wikipedia.org/wiki/Greatest_common_divisor
    if (a < b) {
        return gcd(b, a);
    } else if (a == b) {
        return b;
    }

    while (true) {
        NSUInteger remainder = a % b;
        if (remainder == 0) {
            return b;
        }
        a = b;
        b = remainder;
    }
}


- (void)startAnimating
{
    if (self.animatedImage) {
        // Lazily create the display link.
        if (!self.displayLink) {
            FCWeakProxy *weakProxy = [FCWeakProxy weakProxyForObject:self];
            self.displayLink = [CADisplayLink displayLinkWithTarget:weakProxy selector:@selector(displayDidRefresh:)];
            
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.runLoopMode];
        }

        const NSTimeInterval kDisplayRefreshRate = 60.0; // 60Hz
        self.displayLink.frameInterval = MAX([self frameDelayGreatestCommonDivisor] * kDisplayRefreshRate, 1);

        self.displayLink.paused = NO;
    } else {
        [super startAnimating];
    }
}

- (void)setRunLoopMode:(NSString *)runLoopMode
{
    if (![@[NSDefaultRunLoopMode, NSRunLoopCommonModes] containsObject:runLoopMode]) {
        NSAssert(NO, @"Invalid run loop mode: %@", runLoopMode);
        _runLoopMode = [[self class] defaultRunLoopMode];
    } else {
        _runLoopMode = runLoopMode;
    }
}

- (void)stopAnimating
{
    if (self.animatedImage) {
        self.displayLink.paused = YES;
    } else {
        [super stopAnimating];
    }
}


- (BOOL)isAnimating
{
    BOOL isAnimating = NO;
    if (self.animatedImage) {
        isAnimating = self.displayLink && !self.displayLink.isPaused;
    } else {
        isAnimating = [super isAnimating];
    }
    return isAnimating;
}


#pragma mark Highlighted Image Unsupport

- (void)setHighlighted:(BOOL)highlighted
{
    if (!self.animatedImage) {
        [super setHighlighted:highlighted];
    }
}


#pragma mark - Private Methods
#pragma mark Animation

- (void)updateShouldAnimate
{
    BOOL isVisible = self.window && self.superview && ![self isHidden] && self.alpha > 0.0;
    self.shouldAnimate = self.animatedImage && isVisible;
}


- (void)displayDidRefresh:(CADisplayLink *)displayLink
{

    if (!self.shouldAnimate) {
        return;
    }
    
    NSNumber *delayTimeNumber = [self.animatedImage.delayTimesForIndexes objectForKey:@(self.currentFrameIndex)];
    if (delayTimeNumber) {
        NSTimeInterval delayTime = [delayTimeNumber floatValue];
        // If we have a nil image (e.g. waiting for frame), don't update the view nor playhead.
        UIImage *image = [self.animatedImage imageLazilyCachedAtIndex:self.currentFrameIndex];
        if (image) {
            
            self.currentFrame = image;
            if (self.needsDisplayWhenImageBecomesAvailable) {
                [self.layer setNeedsDisplay];
                self.needsDisplayWhenImageBecomesAvailable = NO;
            }
            
            self.accumulator += displayLink.duration * displayLink.frameInterval;
            
            while (self.accumulator >= delayTime) {
                self.accumulator -= delayTime;
                self.currentFrameIndex++;
                if (self.currentFrameIndex >= self.animatedImage.frameCount) {
                    // If we've looped the number of times that this animated image describes, stop looping.
                    self.loopCountdown--;
                    if (self.loopCompletionBlock) {
                        self.loopCompletionBlock(self.loopCountdown);
                    }
                    
                    if (self.loopCountdown == 0) {
                        [self stopAnimating];
                        return;
                    }
                    self.currentFrameIndex = 0;
                }
                self.needsDisplayWhenImageBecomesAvailable = YES;
            }
        } else {
            
#if defined(DEBUG) && DEBUG
            if ([self.debug_delegate respondsToSelector:@selector(debug_animatedImageView:waitingForFrame:duration:)]) {
                [self.debug_delegate debug_animatedImageView:self waitingForFrame:self.currentFrameIndex duration:(NSTimeInterval)displayLink.duration * displayLink.frameInterval];
            }
#endif
        }
    } else {
        self.currentFrameIndex++;
    }
}

+ (NSString *)defaultRunLoopMode
{
    return [NSProcessInfo processInfo].activeProcessorCount > 1 ? NSRunLoopCommonModes : NSDefaultRunLoopMode;
}


#pragma mark - CALayerDelegate (Informal)
#pragma mark Providing the Layer's Content

- (void)displayLayer:(CALayer *)layer
{
    layer.contents = (__bridge id)self.image.CGImage;
}


@end
