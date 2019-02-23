//
//  SpectrumView.m
//  CrackleCounter
//
//  Created by William Cheswick on 9/6/14.
//  Copyright (c) 2014 William Cheswick. All rights reserved.
//

#import "SpectrumView.h"
#import "AudioDefines.h"


#define BIG_TICK    10
#define SMALL_TICK  4

#define BELOW_T     30
#define LEFT_Y  50
#define RIGHT_Y 50


const unsigned char hotIronPalette[] = {
    0, 0, 0,
    2, 0, 0,
    4, 0, 0,
    6, 0, 0,
    8, 0, 0,
    10, 0, 0,
    12, 0, 0,
    14, 0, 0,
    16, 0, 0,
    18, 0, 0,
    20, 0, 0,
    22, 0, 0,
    24, 0, 0,
    26, 0, 0,
    28, 0, 0,
    30, 0, 0,
    32, 0, 0,
    34, 0, 0,
    36, 0, 0,
    38, 0, 0,
    40, 0, 0,
    42, 0, 0,
    44, 0, 0,
    46, 0, 0,
    48, 0, 0,
    50, 0, 0,
    52, 0, 0,
    54, 0, 0,
    56, 0, 0,
    58, 0, 0,
    60, 0, 0,
    62, 0, 0,
    64, 0, 0,
    66, 0, 0,
    68, 0, 0,
    70, 0, 0,
    72, 0, 0,
    74, 0, 0,
    76, 0, 0,
    78, 0, 0,
    80, 0, 0,
    82, 0, 0,
    84, 0, 0,
    86, 0, 0,
    88, 0, 0,
    90, 0, 0,
    92, 0, 0,
    94, 0, 0,
    96, 0, 0,
    98, 0, 0,
    100, 0, 0,
    102, 0, 0,
    104, 0, 0,
    106, 0, 0,
    108, 0, 0,
    110, 0, 0,
    112, 0, 0,
    114, 0, 0,
    116, 0, 0,
    118, 0, 0,
    120, 0, 0,
    122, 0, 0,
    124, 0, 0,
    126, 0, 0,
    128, 0, 0,
    130, 0, 0,
    132, 0, 0,
    134, 0, 0,
    136, 0, 0,
    138, 0, 0,
    140, 0, 0,
    142, 0, 0,
    144, 0, 0,
    146, 0, 0,
    148, 0, 0,
    150, 0, 0,
    152, 0, 0,
    154, 0, 0,
    156, 0, 0,
    158, 0, 0,
    160, 0, 0,
    162, 0, 0,
    164, 0, 0,
    166, 0, 0,
    168, 0, 0,
    170, 0, 0,
    172, 0, 0,
    174, 0, 0,
    176, 0, 0,
    178, 0, 0,
    180, 0, 0,
    182, 0, 0,
    184, 0, 0,
    186, 0, 0,
    188, 0, 0,
    190, 0, 0,
    192, 0, 0,
    194, 0, 0,
    196, 0, 0,
    198, 0, 0,
    200, 0, 0,
    202, 0, 0,
    204, 0, 0,
    206, 0, 0,
    208, 0, 0,
    210, 0, 0,
    212, 0, 0,
    214, 0, 0,
    216, 0, 0,
    218, 0, 0,
    220, 0, 0,
    222, 0, 0,
    224, 0, 0,
    226, 0, 0,
    228, 0, 0,
    230, 0, 0,
    232, 0, 0,
    234, 0, 0,
    236, 0, 0,
    238, 0, 0,
    240, 0, 0,
    242, 0, 0,
    244, 0, 0,
    246, 0, 0,
    248, 0, 0,
    250, 0, 0,
    252, 0, 0,
    254, 0, 0,
    255, 0, 0,
    255, 2, 0,
    255, 4, 0,
    255, 6, 0,
    255, 8, 0,
    255, 10, 0,
    255, 12, 0,
    255, 14, 0,
    255, 16, 0,
    255, 18, 0,
    255, 20, 0,
    255, 22, 0,
    255, 24, 0,
    255, 26, 0,
    255, 28, 0,
    255, 30, 0,
    255, 32, 0,
    255, 34, 0,
    255, 36, 0,
    255, 38, 0,
    255, 40, 0,
    255, 42, 0,
    255, 44, 0,
    255, 46, 0,
    255, 48, 0,
    255, 50, 0,
    255, 52, 0,
    255, 54, 0,
    255, 56, 0,
    255, 58, 0,
    255, 60, 0,
    255, 62, 0,
    255, 64, 0,
    255, 66, 0,
    255, 68, 0,
    255, 70, 0,
    255, 72, 0,
    255, 74, 0,
    255, 76, 0,
    255, 78, 0,
    255, 80, 0,
    255, 82, 0,
    255, 84, 0,
    255, 86, 0,
    255, 88, 0,
    255, 90, 0,
    255, 92, 0,
    255, 94, 0,
    255, 96, 0,
    255, 98, 0,
    255, 100, 0,
    255, 102, 0,
    255, 104, 0,
    255, 106, 0,
    255, 108, 0,
    255, 110, 0,
    255, 112, 0,
    255, 114, 0,
    255, 116, 0,
    255, 118, 0,
    255, 120, 0,
    255, 122, 0,
    255, 124, 0,
    255, 126, 0,
    255, 128, 4,
    255, 130, 8,
    255, 132, 12,
    255, 134, 16,
    255, 136, 20,
    255, 138, 24,
    255, 140, 28,
    255, 142, 32,
    255, 144, 36,
    255, 146, 40,
    255, 148, 44,
    255, 150, 48,
    255, 152, 52,
    255, 154, 56,
    255, 156, 60,
    255, 158, 64,
    255, 160, 68,
    255, 162, 72,
    255, 164, 76,
    255, 166, 80,
    255, 168, 84,
    255, 170, 88,
    255, 172, 92,
    255, 174, 96,
    255, 176, 100,
    255, 178, 104,
    255, 180, 108,
    255, 182, 112,
    255, 184, 116,
    255, 186, 120,
    255, 188, 124,
    255, 190, 128,
    255, 192, 132,
    255, 194, 136,
    255, 196, 140,
    255, 198, 144,
    255, 200, 148,
    255, 202, 152,
    255, 204, 156,
    255, 206, 160,
    255, 208, 164,
    255, 210, 168,
    255, 212, 172,
    255, 214, 176,
    255, 216, 180,
    255, 218, 184,
    255, 220, 188,
    255, 222, 192,
    255, 224, 196,
    255, 226, 200,
    255, 228, 204,
    255, 230, 208,
    255, 232, 212,
    255, 234, 216,
    255, 236, 220,
    255, 238, 224,
    255, 240, 228,
    255, 242, 232,
    255, 244, 236,
    255, 246, 240,
    255, 248, 244,
    255, 250, 248,
    255, 252, 252,
    255, 255, 255,

};

@interface SpectrumView ()

@property (assign)              size_t firstDisplay; // in samples, not bytes
@property (assign)              size_t numberDisplayed; // in samples, not bytes

@end

@implementation SpectrumView

@synthesize audioClip;
@synthesize firstDisplay, numberDisplayed;

- (void) displayPixels:(NSData *)spectrumPixels {
    CGDataProviderRef provider = CGDataProviderCreateWithData(
                                                              NULL,
                                                              spectrumPixels.bytes,
                                                              spectrumPixels.length,
                                                              NULL);
    
//    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGColorSpaceRef RGB = CGColorSpaceCreateDeviceRGB();
    CGColorSpaceRef hotIron = CGColorSpaceCreateIndexed(RGB,
                                                        SPECTRUM_MAX_PIXEL, hotIronPalette);
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
//    NSLog(@"spectrumPixels: at %p, %zu", spectrumPixels.bytes, spectrumPixels.length);

    CGImageRef imageRef = CGImageCreate(self.frame.size.width,
                                        self.frame.size.height,
                                        8,
                                        sizeof(SpectrumPixel) * 8,
                                        self.frame.size.width*sizeof(SpectrumPixel),
                                        hotIron,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    
    self.image = [UIImage imageWithCGImage:imageRef];
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(hotIron);
    CGColorSpaceRelease(RGB);
    CGImageRelease(imageRef);
    [self setNeedsDisplay];
}

- (void) showSamplesFrom:(size_t) startSample count:(size_t) nSamples {
    assert(audioClip);
    assert(audioClip.samples);
    firstDisplay = startSample;
    numberDisplayed = nSamples;
    assert(startSample + nSamples <= audioClip.sampleCount);
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self setNeedsDisplay];
    });
}

@end
