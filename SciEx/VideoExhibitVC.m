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
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    return YES;
}

- (void) setLiveFrameAndOrientation: (CGRect) frame  {
    captureVideoPreviewLayer.frame = frame;
    
    // I am not sure what to do with this, or even if it is used at all:
    //    captureVideoPreviewLayer.connection.videoOrientation =
    //    [[UIDevice currentDevice] orientation];
    
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
    captureVideoPreviewLayer.connection.videoOrientation = newOrientation;
    [captureConnection setVideoOrientation: newOrientation];

#ifdef fileonly
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

- (void) startVideoCapture:(CGSize) capSize liveView:(nullable UIView *)liveView {
    NSError *error;
    
    AVCaptureDeviceInput *capInput = [AVCaptureDeviceInput
                                      deviceInputWithDevice:captureDevice
                                      error:&error];
    if (capInput)
        [captureSession addInput:capInput];
    
    if (liveView) {
        liveLayer = [AVCaptureVideoPreviewLayer layerWithSession: captureSession];
        liveLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [liveView.layer addSublayer: liveLayer];
    }

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

static BOOL first = YES;

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    size_t bpr = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t stride = bpr/bufferWidth;
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    if (first) {
        NSLog(@"%zu x %zu, %zu stride %lu", bufferWidth, bufferHeight, bpr, stride);
        first = NO;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self->caller processImage:pixel w:bufferWidth h:bufferHeight];
    });

#ifdef notdef
    for( int row = 0; row < bufferHeight; row++ ) {
        for( int column = 0; column < bufferWidth; column++ ) {
            int r = pixel[0];
            int g = pixel[1];
            int b = pixel[2];
//            NSLog(@"%4d %4d %4d", r, g, b);
//            pixel[1] = 0; //  it sets the green element of each pixel to zero, which gives the entire frame a purple tint.
            pixel += stride;
        }
    }
#endif

    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
}

#ifdef notdef
- (void) startVideoCaptureToBuffer {
    AVCaptureDeviceInput *capInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (capInput) [AVsession addInput:capInput];
    
    for(AVCaptureDeviceFormat *vFormat in [videoDevice formats] )
    {
        CMFormatDescriptionRef description= vFormat.formatDescription;
        float maxrate=((AVFrameRateRange*)[vFormat.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
        
        if(maxrate>59 && CMFormatDescriptionGetMediaSubType(description)==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        {
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
    
    if (videoOut)
    {
        [AVsession addOutput:videoOut];
        videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    }
}
#endif

@end
