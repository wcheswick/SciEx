//
//  VideoExhibitVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "VideoExhibitVC.h"

@interface VideoExhibitVC ()

@property (strong, nonatomic)   AVCaptureDevice *captureDevice;
@property (nonatomic, strong)   AVCaptureSession *captureSession;
@property (nonatomic, strong)   AVCaptureConnection *captureConnection;
@property (nonatomic, strong)   AVCaptureVideoPreviewLayer *liveLayer;
@property (nonatomic, strong)   AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@end

@implementation VideoExhibitVC

@synthesize captureDevice, captureSession;
@synthesize captureConnection;
@synthesize captureVideoPreviewLayer;
@synthesize liveLayer;
@synthesize caller;

- (id)init {
    self = [super init];
    if (self) {
        captureDevice = nil;
        captureSession = nil;
    }
    return self;
}

- (BOOL) selectCamera:(AVCaptureDevicePosition) position {
    captureDevice = [AVCaptureDevice
                     defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInDualCamera
                     mediaType: AVMediaTypeVideo
                     position: position];
    if (!captureDevice)
        captureDevice = [AVCaptureDevice
                         defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInWideAngleCamera
                         mediaType: AVMediaTypeVideo
                         position: position];
    if (!captureDevice) {
        return NO;
    }
    
    captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPreset1280x720;    // 720p
    //    captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    //    captureSession.sessionPreset = AVCaptureSessionPreset3840x2160; // 4k
    //    captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540
    //    captureSession.sessionPreset = AVCaptureSessionPreset1920x1080; // 1080p
    
    captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
//    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    return YES;
}

- (void) setLiveFrameAndOrientation: (CGRect) frame  {
    captureVideoPreviewLayer.frame = frame;

    // I am not sure what to do with this, or even if it is used at all:
    //    captureVideoPreviewLayer.connection.videoOrientation =
    //    [[UIDevice currentDevice] orientation];
#ifdef fileonly

    AVCaptureVideoOrientation newOrientation;
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            newOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            newOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            newOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            newOrientation = AVCaptureVideoOrientationPortrait;
    }
//    captureVideoPreviewLayer.connection.videoOrientation = newOrientation;
//    [captureConnection setVideoOrientation: newOrientation];

    for (int i = 0; i < [[movieOutput connections] count]; i++) {
        AVCaptureConnection *capConn = [[movieOutput connections] objectAtIndex:i];
        if ([captureConnection isVideoOrientationSupported]) {
            [captureConnection setVideoOrientation:newOrientation];
        }
    }
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) startVideoCapture:(CGSize) capSize {
    NSError *error;
    
    AVCaptureDeviceInput *capInput = [AVCaptureDeviceInput
                                    deviceInputWithDevice:captureDevice
                                      error:&error];
    if (capInput)
        [captureSession addInput:capInput];
    
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t videoQueue = dispatch_queue_create("videoQueue", NULL);
    [videoOut setSampleBufferDelegate:self queue:videoQueue];
    
    videoOut.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    videoOut.alwaysDiscardsLateVideoFrames=YES;
    
    if (videoOut) {
        [captureSession addOutput:videoOut];
//        captureConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
        [captureSession startRunning];
    }
}

- (void) stopVideoCapture {
    [captureSession stopRunning];
}

#ifdef notdef
- (void) startVideoCaptureToBuffer {
    AVCaptureDeviceInput *capInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (capInput) [AVsession addInput:capInput];
    
    for(AVCaptureDeviceFormat *vFormat in [videoDevice formats] ) {
        CMFormatDescriptionRef description= vFormat.formatDescription;
        float maxrate=((AVFrameRateRange*)[vFormat.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
        
        if(maxrate>59 && CMFormatDescriptionGetMediaSubType(description)==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            if ( YES == [videoDevice lockForConfiguration:NULL] )
            {
                videoDevice.activeFormat = vFormat;
                [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(10,600)];
                [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(10,600)];
                [videoDevice unlockForConfiguration];
                NSLog(@"formats  %@ %@ %@",vFormat.mediaType,vFormat.formatDescription,vFormat.videoSupportedFrameRateRanges);
            }
        }
    }
    
    prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: AVsession];
    prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer: prevLayer];
    
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t videoQueue = dispatch_queue_create("videoQueue", NULL);
    [videoOut setSampleBufferDelegate:self queue:videoQueue];
    
    videoOut.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)};
    videoOut.alwaysDiscardsLateVideoFrames=YES;
    
    if (videoOut) {
        [AVsession addOutput:videoOut];
        videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    }
}
#endif

#ifdef samples
- (UIColor*)pixelColorInImage:(UIImage*)image atX:(int)x atY:(int)y {
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    
    int pixelInfo = ((image.size.width * y) + x ) * 4; // 4 bytes per pixel
    
    UInt8 red   = data[pixelInfo + 0];
    UInt8 green = data[pixelInfo + 1];
    UInt8 blue  = data[pixelInfo + 2];
    UInt8 alpha = data[pixelInfo + 3];
    CFRelease(pixelData);
    
    return [UIColor colorWithRed:red  /255.0f
                           green:green/255.0f
                            blue:blue /255.0f
                           alpha:alpha/255.0f];
}

UIImage * ghostImage = [UIImage imageNamed:@"ghost"];
CGImageRef ghostCGImage = [ghostImage CGImage];

CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height;
NSInteger targetGhostWidth = inputWidth * 0.25;
CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
CGPoint ghostOrigin = CGPointMake(inputWidth * 0.5, inputHeight * 0.2);


NSUInteger ghostBytesPerRow = bytesPerPixel * ghostSize.width;
UInt32 * ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));

CGContextRef ghostContext = CGBitmapContextCreate(ghostPixels, ghostSize.width, ghostSize.height,
                                                  bitsPerComponent, ghostBytesPerRow, colorSpace,
                                                  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height),ghostCGImage);

// Create a new UIImage
CGImageRef newCGImage = CGBitmapContextCreateImage(context);
UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];

return processedImage;

#endif

@end
