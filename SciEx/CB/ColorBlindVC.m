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
@property (assign)              BOOL transformReady;
@property (assign)              BOOL fullScreenCB;

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
@synthesize transformReady;
@synthesize fullScreenCB;

- (id)init {
    self = [super init];
    if (self) {
        exhibitTitle = @"Color blind simulator";
        exhibitAvailable = YES;
        self.caller = self;
        fullScreenCB = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBarHidden = NO;
//    self.navigationController.navigationBar.opaque = YES;
    self.navigationController.toolbarHidden = YES;
    
    self.title = exhibitTitle;
    
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
    
    liveView = [[UIView alloc] init];
    liveView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:liveView];
    liveImageView = [[UIImageView alloc] init];
    liveImageView.contentMode = UIViewContentModeScaleAspectFit;
    [liveView addSubview:liveImageView];
    
    cbView = [[UIView alloc] init];
    cbView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:cbView];
    cbImageView = [[UIImageView alloc] init];
    cbImageView.contentMode = UIViewContentModeScaleAspectFit;
    [cbView addSubview:cbImageView];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(doSwipe:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
 
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self
                                            action:@selector(doSwipe:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    SET_VIEW_Y(self.view, BELOW(self.navigationController.navigationBar.frame));
    SET_VIEW_HEIGHT(self.view, self.view.frame.size.height - self.view.frame.origin.y);
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.opaque = YES;
    
#ifdef OLD
    top.frame = self.view.frame;
    SET_VIEW_HEIGHT(top, 50);
    SET_VIEW_X(top, 0);
    [top setNeedsDisplay];
#endif
    
    [self layoutViews];

    transformReady = NO;
    
    if ([self selectCamera:AVCaptureDevicePositionFront]) {
        [self setLiveFrameAndOrientation:liveView.frame];
        [self startVideoCapture:liveView.frame.size];
    } else {
        NSLog(@"XXX no camera available");
    }
}

- (void) layoutViews {
    CGRect f;
    if (fullScreenCB) {
        f = liveView.frame;
        f.size.width = 0;
        liveView.frame = f;
        f = liveImageView.frame;
        f.size.width = 0;
        liveImageView.frame = f;

        f = cbView.frame;
        f.origin.x = INSET;
        f.size = CGSizeMake(self.view.frame.size.width - 2*INSET,
                            (self.view.frame.size.height - f.origin.y));
        cbView.frame = f;
        cbImageView.frame = CGRectMake(0, 0, f.size.width, f.size.height);
    } else {
        f.origin = CGPointMake(INSET, self.view.frame.origin.y);
        f.size = CGSizeMake((self.view.frame.size.width - 2*INSET - INSET)/2.0,
                            (self.view.frame.size.height - f.origin.y)/2);
        liveView.frame = f;
        liveImageView.frame = CGRectMake(0, 0, f.size.width, f.size.height);
        [liveImageView setNeedsDisplay];
        
        cbView.frame = liveView.frame;
        SET_VIEW_X(cbView, RIGHT(liveView.frame) + INSET);
        cbImageView.frame = liveImageView.frame;
    }
    [liveView setNeedsDisplay];
    [cbView setNeedsDisplay];
    [cbImageView setNeedsDisplay];
}

- (IBAction)doSwipe:(UISwipeGestureRecognizer *)sender {
    if (sender.direction == UISwipeGestureRecognizerDirectionRight && !fullScreenCB)
        return;
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft && fullScreenCB)
        return;
    
    fullScreenCB = !fullScreenCB;
    [UIView animateWithDuration:0.5
                     animations:^(void) {
                         [self layoutViews];
                     }
                     completion:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    UIActivityIndicatorView *busy = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    busy.frame = CGRectMake(0, 0, cbView.frame.size.width, cbView.frame.size.height);
    busy.hidesWhenStopped = YES;
    [busy startAnimating];
    busy.backgroundColor = [UIColor whiteColor];
    [cbView addSubview:busy];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        init_colorblind(PROTANOPIA);
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [busy stopAnimating];
            self.cbView.backgroundColor = [UIColor whiteColor];
            self.transformReady = YES;
        });
    });
}

- (void) viewDidDisappear:(BOOL)animated {
    transformReady = NO;
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
    
//    NSLog(@"o: %ld", (long)liveImage.imageOrientation);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.liveImageView.image = [UIImage imageWithCGImage:[liveImage CGImage]
                                                       scale:[liveImage scale]
                                                 orientation: UIImageOrientationRight];
        [self.liveImageView setNeedsDisplay];
    });
    
    if (transformReady) {
        CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(liveImageRef));
        const Pixel *livePixels = (Pixel *)CFDataGetBytePtr(rawData);
        
        for (size_t i=0; i < h*w; i++) {
            abgr[i] = livePixelToColorBlind(&livePixels[i]);
        }
        CFRelease(rawData);
        
        //    NSLog(@" pixel 2 = %08x:", pixels[1]);
        
        // create the bitmap context:
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef gtx = CGBitmapContextCreate(abgr, w, h,
                                                 8, BYTES_PER_PIXEL*w, colorSpace,
                                                 kCGImageAlphaNoneSkipLast);
        assert(gtx);
#ifdef BS
        CGFloat theta = M_PI/2.0;
        CGFloat centerX = w/2.0;
        CGFloat centerY = h/2.0;
        CGFloat newX = centerX*cos(theta) - centerY*sin(theta);
        CGFloat newY = centerX*sin(theta) + centerY*cos(theta);
        
        CGContextTranslateCTM(gtx, newX, newY);
        CGContextRotateCTM(gtx, theta);
#endif
        CGColorSpaceRelease(colorSpace);
        
        // create the image:
        CGImageRef cbImageRef = CGBitmapContextCreateImage(gtx);
        UIImage *cbImage = [[UIImage alloc] initWithCGImage:cbImageRef
                                                      scale:1.0
                                                orientation:UIImageOrientationRight];
        CGImageRelease(cbImageRef);
        CGContextRelease(gtx);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.cbImageView.image = cbImage;
            [self.cbImageView setNeedsDisplay];
            busy = NO;
        });
    }
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    CGImageRelease(liveImageRef);
}

@end
