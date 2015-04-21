//
//  OTKBasicVideoCapturer.m
//  Getting Started
//
//  Created by rpc on 03/03/15.
//  Copyright (c) 2015 OpenTok. All rights reserved.
//

#import "OTKBasicVideoCapturer.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#define kFramesPerSecond 15
#define kTimerInterval dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1 / kFramesPerSecond) * NSEC_PER_SEC))

@interface OTKBasicVideoCapturer ()
@property (nonatomic, assign) BOOL captureStarted;
@property (nonatomic, strong) OTVideoFormat *format;
@property (nonatomic, strong) id<OTVideoCaptureConsumer> consumer;
- (void)produceFrame;
- (UIImage *)screenshot;
- (void)fillPixelBufferFromCGImage:(CGImageRef)image;
@end

@implementation OTKBasicVideoCapturer {
    CVPixelBufferRef pixelBuffer;
}

- (void)initCapture
{
    self.format = [[OTVideoFormat alloc] init];
    self.format.pixelFormat = OTPixelFormatARGB;
}

- (void)releaseCapture
{
    self.format = nil;
}

- (int32_t)startCapture
{
    self.captureStarted = YES;
    dispatch_after(kTimerInterval,
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                   ^{
                       @autoreleasepool {
                           [self produceFrame];
                       }
                   });
    
    return 0;
}

- (int32_t)stopCapture
{
    self.captureStarted = NO;
    return 0;
}

- (BOOL)isCaptureStarted
{
    return self.captureStarted;
}

- (int32_t)captureSettings:(OTVideoFormat*)videoFormat
{
    return 0;
}

- (void)setVideoCaptureConsumer:(id<OTVideoCaptureConsumer>)videoCaptureConsumer
{
    // Save consumer instance in order to use it to send frames to the session
    self.consumer = videoCaptureConsumer;
}

- (void)produceFrame
{
    OTVideoFrame *frame = [[OTVideoFrame alloc] initWithFormat:self.format];
    
    static mach_timebase_info_data_t time_info;
    uint64_t time_stamp = 0;
    
    time_stamp = mach_absolute_time();
    time_stamp *= time_info.numer;
    time_stamp /= time_info.denom;
    
    CGImageRef screenshot = [[self screenshot] CGImage];
    [self fillPixelBufferFromCGImage:screenshot];
    
    CMTime time = CMTimeMake(time_stamp, 1000);

    frame.timestamp = time;
    frame.format.estimatedFramesPerSecond = kFramesPerSecond;
    frame.format.estimatedCaptureDelay = 100;
    frame.format.imageWidth = CVPixelBufferGetWidth(pixelBuffer);
    frame.format.imageHeight = CVPixelBufferGetHeight(pixelBuffer);
    frame.format.bytesPerRow = [@[@(frame.format.imageWidth * 4)] mutableCopy];
    frame.orientation = OTVideoOrientationUp;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *planes[1];
    
    planes[0] = CVPixelBufferGetBaseAddress(pixelBuffer);
    [frame setPlanesWithPointers:planes numPlanes:1];
    
    [self.consumer consumeFrame:frame];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    if (self.captureStarted) {
        dispatch_after(kTimerInterval,
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                       ^{
                           @autoreleasepool {
                               [self produceFrame];
                           }
                       });
    }
}

#pragma mark - Private methods

- (UIImage *)screenshot
{
    CGSize imageSize = CGSizeZero;
    
    imageSize = [UIScreen mainScreen].bounds.size;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    if ([window respondsToSelector:
         @selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
    }
    else {
        [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)fillPixelBufferFromCGImage:(CGImageRef)image
{
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    CGSize frameSize = CGSizeMake(width, height);
    if (pixelBuffer == nil || CVPixelBufferGetHeight(pixelBuffer) != height ||
        CVPixelBufferGetWidth(pixelBuffer) != width) {
        
        NSDictionary *options = @{
                                  (NSString *)kCVPixelBufferCGImageCompatibilityKey: @NO,
                                  (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @NO
                                  };
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                            frameSize.width,
                            frameSize.height,
                            kCVPixelFormatType_32ARGB,
                            (__bridge CFDictionaryRef)(options),
                            &(pixelBuffer));
    }
    
    
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context =
    CGBitmapContextCreate(pxdata,
                          frameSize.width,
                          frameSize.height,
                          8,
                          CVPixelBufferGetBytesPerRow(pixelBuffer),
                          rgbColorSpace,
                          kCGImageAlphaPremultipliedFirst |
                          kCGBitmapByteOrder32Little);
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

@end
