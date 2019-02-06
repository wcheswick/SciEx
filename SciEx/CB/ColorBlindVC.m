//
//  ColorBlind.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "ColorBlindVC.h"
#import "Defines.h"
#import "Pixel.h"
#import "cb.h"

@interface ColorBlindVC ()

@property (nonatomic, strong)   UILabel *top;
@property (nonatomic, strong)   UIView *liveView;
@property (nonatomic, strong)   UIImageView *liveImageView;
@property (nonatomic, strong)   UIView *cbView;
@property (nonatomic, strong)   UIImageView *cbImageView;

@end


static Pixel *abgr = 0;
static size_t w = 0;
static size_t h = 0;

static BOOL busy = NO;
static int busyCount = 0;

@implementation ColorBlindVC

@synthesize top;
@synthesize liveView, liveImageView;
@synthesize cbView, cbImageView;

- (id)init {
    self = [super init];
    if (self) {
        exhibitTitle = @"What do the colorblind see?";
        exhibitAvailable = YES;
        self.caller = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBarHidden = NO;
//    self.navigationController.navigationBar.opaque = YES;
    self.navigationController.toolbarHidden = YES;
    
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doDone:)];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    top = [[UILabel alloc] init];
    top.text = self.exhibitTitle;
    top.textColor = [UIColor blueColor];
    top.numberOfLines = 0;
    top.lineBreakMode = NSLineBreakByWordWrapping;
    top.textAlignment = NSTextAlignmentCenter;
    top.font = [UIFont boldSystemFontOfSize:20];
    top.layer.borderWidth = 0.5;
    top.layer.borderColor = [UIColor blackColor].CGColor;
    top.layer.cornerRadius = 10.0;
    [self.view addSubview:top];
    
    liveView = [[UIView alloc] init];
    liveView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:liveView];
    
    liveImageView = [[UIImageView alloc] init];
    [liveView addSubview:liveImageView];
    
    cbView = [[UIView alloc] init];
    cbView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:cbView];
    
    cbImageView = [[UIImageView alloc] init];
    [cbView addSubview:cbImageView];

    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    SET_VIEW_Y(self.view, BELOW(self.navigationController.navigationBar.frame));
    SET_VIEW_HEIGHT(self.view, self.view.frame.size.height - self.view.frame.origin.y);
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.opaque = YES;
    
    top.frame = self.view.frame;
    SET_VIEW_HEIGHT(top, 50);
    SET_VIEW_X(top, 0);
    [top setNeedsDisplay];
    
    CGRect f;
    f.origin = CGPointMake(INSET, BELOW(top.frame) + SEP);
    f.size = CGSizeMake(self.view.frame.size.width - 2*INSET,
                        (self.view.frame.size.height - f.origin.y)/2);
    liveView.frame = f;
    [liveView setNeedsDisplay];
    
    liveImageView.frame = CGRectMake(0, 0, f.size.width, f.size.height);
    [liveImageView setNeedsDisplay];
    
    cbView.frame = liveView.frame;
    SET_VIEW_Y(cbView, BELOW(liveView.frame) + SEP);
    [cbView setNeedsDisplay];
    
    cbImageView.frame = liveImageView.frame;
    [cbImageView setNeedsDisplay];

    if ([self selectCamera:AVCaptureDevicePositionFront]) {
        [self setLiveFrameAndOrientation:liveView.frame];
        [self startVideoCapture:liveView.frame.size liveView:nil];
    } else {
        NSLog(@"XXX no camera available");
    }

    init_colorblind(DEUTERANOPIA);
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
    if (abgr) {
        free(abgr);
        NSLog(@"Freed");
        abgr = 0;
    }
    end_colorblind();
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self stopVideoCapture];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (busy) {
        if ((busyCount++ % 100) == 0)
            NSLog(@"busy %d", busyCount);
        return;
    }
    if (finished)
        return;
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    size_t nw = CVPixelBufferGetWidth(pixelBuffer);
    size_t nh = CVPixelBufferGetHeight(pixelBuffer);
    
    if (!w || !h || nw != w || nh != h) {   // new frame, or size change
        abgr = realloc(abgr, nw * nh * sizeof(Pixel));
        assert(abgr);
        w = nw; h = nh;
    }
    
    CIImage *ciLiveImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *liveContext = [CIContext contextWithOptions:nil];
    CGImageRef liveImageRef = [liveContext
                          createCGImage:ciLiveImage
                          fromRect:[ciLiveImage extent]];
    
    UIImage *liveImage = [UIImage imageWithCGImage:liveImageRef];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.liveImageView.image = liveImage;
        [self.liveImageView setNeedsDisplay];
    });
    
    CFDataRef  rawData = CGDataProviderCopyData(CGImageGetDataProvider(liveImageRef));
    const Pixel *livePixels = (Pixel *)CFDataGetBytePtr(rawData);
    
    for (size_t i=0; i < h*w; i++) {
        abgr[i] = livePixelToColorBlind(&livePixels[i]);
    }
    CGImageRelease(liveImageRef);
    CFRelease(rawData);
    
//    NSLog(@" pixel 2 = %08x:", pixels[1]);
          
    // create the bitmap context:
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef gtx = CGBitmapContextCreate(abgr, w, h,
                                             8, BYTES_PER_PIXEL*w, colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    assert(gtx);
    CGColorSpaceRelease(colorSpace);

    // create the image:
    CGImageRef cbImageRef = CGBitmapContextCreateImage(gtx);
    UIImage *cbImage = [[UIImage alloc] initWithCGImage:cbImageRef];
    CGImageRelease(cbImageRef);
    
    CGContextRelease(gtx);
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );

    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.cbImageView.image = cbImage;
        [self.cbImageView setNeedsDisplay];
        busy = NO;
    });
}

@end
