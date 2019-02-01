//
//  PixelView.m
//  SciEx
//
//  Created by ches on 2/1/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "PixelView.h"

@interface PixelView ()


@end

@implementation PixelView

@synthesize buffer;
@synthesize width, height;

-(void)drawLayer:(CALayer*)layer
       inContext:(CGContextRef)context {
    CGContextSaveGState(context);
//    CGContextRef context = UIGraphicsGetCurrentContext();
    
    u_char *p = buffer;
    
    for (int x=0; x<width; x++) {
        for (int y=0; y<height; y++) {
            int r = p[0];
            int g = p[1];
            int b = p[2];
            CGContextSetRGBFillColor(context, r/255.0, g/255.0, b/255.0, 1.0);
            CGContextFillRect(context, CGRectMake(x, y, 1, 1));
            p += 4;
        }
        CGContextFlush(context);
    }
    CGContextRestoreGState(context);


#ifdef nope
    float scaleFactor = [[UIScreen mainScreen] scale];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 rect.size.width * scaleFactor,
                                                 rect.size.height * scaleFactor,
                                                 8, rect.size.width * scaleFactor * 4,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    
    CGContextScaleCTM(context, scaleFactor, scaleFactor);    CGContextSaveGState(context);
    
#ifdef notdef
    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
    CGContextFillRect(context,self.bounds);
#endif
    CGContextAddRect(<#CGContextRef  _Nullable c#>, <#CGRect rect#>)
    CGContextRef bitmapContext = CGBitmapContextCreate(
                                                       buffer,
                                                       width,
                                                       height,
                                                       8, // bitsPerComponent
                                                       4*width, // bytesPerRow
                                                       colorSpace,
                                                       kCGImageAlphaNoneSkipLast);
    
    CFRelease(colorSpace);
    
    CFRelease(cgImage);
    CFRelease(bitmapContext);
#endif
}

@end
