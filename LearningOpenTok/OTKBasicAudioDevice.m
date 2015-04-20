//
//  OTKBasicAudioDevice.m
//  Getting Started
//
//  Created by rpc on 09/03/15.
//  Copyright (c) 2015 OpenTok. All rights reserved.
//

#import "OTKBasicAudioDevice.h"

#define kSampleRate 16000
#define kOutputFileSampleName @"temp.dat"

@interface OTKBasicAudioDevice ()
@property (strong, nonatomic) id<OTAudioBus> otAudioBus;
@property (strong, nonatomic) OTAudioFormat *otAudioFormat;
@property (assign, nonatomic) BOOL isDeviceCapturing;
@property (assign, nonatomic) BOOL isCaptureInitialized;
@property (assign, nonatomic) BOOL isDeviceRendering;
@property (assign, nonatomic) BOOL isRenderingInitialized;
@property (strong, nonatomic) NSFileHandle *outFile;

- (void)produceSampleCapture;
- (void)consumeSampleCapture;
@end

@implementation OTKBasicAudioDevice

- (id)init
{
    self = [super init];
    if (self) {
        self = [super init];
        if (self) {
            _otAudioFormat = [[OTAudioFormat alloc] init];
            _otAudioFormat.sampleRate = kSampleRate;
            _otAudioFormat.numChannels = 1;
            
            _isDeviceCapturing = NO;
            _isCaptureInitialized = NO;
            _isDeviceRendering = NO;
            _isRenderingInitialized = NO;
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [paths[0] stringByAppendingPathComponent:kOutputFileSampleName];
            
            [[NSFileManager defaultManager] createFileAtPath:path
                                                    contents:nil
                                                  attributes:nil];
            _outFile = [NSFileHandle fileHandleForWritingAtPath:path];
        }
    }
    return self;
}

- (BOOL)setAudioBus:(id<OTAudioBus>)audioBus
{
    self.otAudioBus = audioBus;
    return YES;
}

#pragma mark - Render Methods

- (OTAudioFormat*)renderFormat
{
    return self.otAudioFormat;
}

- (BOOL)renderingIsAvailable
{
    return YES;
}

- (BOOL)initializeRendering
{
    self.isRenderingInitialized = YES;
    return YES;
}

- (BOOL)renderingIsInitialized
{
    return self.isRenderingInitialized;
}

- (BOOL)startRendering
{
    self.isDeviceRendering = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self consumeSampleCapture];
    });
    return YES;
}

- (BOOL)stopRendering
{
    self.isDeviceRendering = NO;
    return YES;
}

- (BOOL)isRendering
{
    return self.isDeviceRendering;
}

- (uint16_t)estimatedRenderDelay
{
    return 1;
}

- (void)consumeSampleCapture
{
    static int num_samples = 0.1 * kSampleRate;
    int16_t *buffer = malloc(sizeof(int16_t) * num_samples);
    
    uint32_t samples_get = [self.otAudioBus readRenderData:buffer numberOfSamples:num_samples];

    NSData *data = [NSData dataWithBytes:buffer
                                  length:(sizeof(int16_t) * samples_get)];
    [self.outFile seekToEndOfFile];
    [self.outFile writeData:data];
    
    free(buffer);
    
    if (self.isDeviceRendering) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self consumeSampleCapture];
        });
    }
}

#pragma mark - Capture Methods

- (OTAudioFormat*)captureFormat
{
    return self.otAudioFormat;
}

- (BOOL)captureIsAvailable
{
    return YES;
}

- (BOOL)initializeCapture
{
    self.isCaptureInitialized = YES;
    return YES;
}

- (BOOL)captureIsInitialized
{
    return self.isCaptureInitialized;
}

- (BOOL)startCapture
{
    self.isDeviceCapturing = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self produceSampleCapture];
    });
    
    return YES;
}

- (BOOL)stopCapture
{
    self.isDeviceCapturing = NO;
    return YES;
}

- (BOOL)isCapturing
{
    return self.isDeviceCapturing;
}

- (uint16_t)estimatedCaptureDelay
{
    return 0;
}

- (void)produceSampleCapture
{
    static int num_frames = 0.1 * kSampleRate;
    int16_t *buffer = malloc(sizeof(int16_t) * num_frames);
    
    for (int frame = 0; frame < num_frames; ++frame) {
        Float32 sample = ((double)arc4random() / 0x100000000);
        buffer[frame] = (sample * 32767.0f);
    }
    
    [self.otAudioBus writeCaptureData:buffer numberOfSamples:num_frames];
    
    free(buffer);
    
    if (self.isDeviceCapturing) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self produceSampleCapture];
        });
    }
}

@end
