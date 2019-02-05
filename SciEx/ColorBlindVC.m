//
//  ColorBlind.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "ColorBlindVC.h"
#import "PixelView.h"
#import "Defines.h"

@interface ColorBlindVC ()

@property (nonatomic, strong)   UILabel *top;
@property (nonatomic, strong)   UIView *liveView;
@property (nonatomic, strong)   UIImageView *liveImageView;
@property (nonatomic, strong)   UIView *cbView;
@property (nonatomic, strong)   UIImageView *cbImageView;
@property (nonatomic, strong)   PixelView *cbImage;

@end

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
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self stopVideoCapture];
    if (abgr)
        free(abgr);
    [self.navigationController popViewControllerAnimated:YES];
}

typedef UInt32 Pixel;

#define Z   ((u_char)UINT8_MAX)
#define BYTES_PER_PIXEL sizeof(UInt32) // rgba

#define PIXEL(r,g,b)    ((Pixel)(b)<<16| (Pixel)(g)<<8 | (Pixel)(r))

#define BLUE    PIXEL(0,0,Z)
#define GREEN   PIXEL(0,Z,0)
#define RED     PIXEL(Z,0,0)
#define WHITE   PIXEL(Z,Z,Z)
#define YELLOW  PIXEL(Z,Z,0)

static Pixel *abgr = 0;
static size_t w = 0;
static size_t h = 0;


static BOOL busy = NO;
static int busyCount = 0;

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
//    GCContextRelease(liveContext);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.liveImageView.image = liveImage;
        [self.liveImageView setNeedsDisplay];
    });
    
    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(liveImageRef));
    const Pixel *livePixels = (Pixel *)CFDataGetBytePtr(rawData);
    
    for (size_t i=0; i < h*w; i++) {
        abgr[i] = livePixels[i];
    }
    CGImageRelease(liveImageRef);

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

//    NSData * png = UIImagePNGRepresentation(uiimage);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.cbImageView.image = cbImage;
        [self.cbImageView setNeedsDisplay];
        busy = NO;
    });


#ifdef OLD
    CGContextRef dupContext = CGBitmapContextCreate(pixels, w, h,
                                                      32, bytesPerRow, colorSpace,
                                                      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(dupContext, CGRectMake(0, 0, w, h), myImage);
    
    CGImageRelease(myImage);

    // Create a new UIImage
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];

#ifdef notdef
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.liveImageView.image = liveImage;
        [self.liveImageView setNeedsDisplay];
    });
#endif
    
#ifdef notdef
    UIImage *ui = [UIImage imageWithCIImage:liveImage.CIImage];


//    NSLog(@" w: %zu", CVPixelBufferGetWidth(pixelBuffer));
//    NSLog(@" h: %zu", CVPixelBufferGetHeight(pixelBuffer));
//    NSLog(@" bpr: %zu", CVPixelBufferGetBytesPerRow(pixelBuffer));
    size_t len = CVPixelBufferGetHeight(pixelBuffer)*
        CVPixelBufferGetBytesPerRow(pixelBuffer);
    u_char *dupData = malloc(len);
    assert(dupData);

    u_char *pixels = (u_char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    memcpy(dupData, pixels, len);
    NSData *pixData = [NSData dataWithBytes:dupData length:len];
    
    CIImage *dupciImage = [CIImage imageWithData:pixData];
    context = [CIContext contextWithOptions:nil];
    CGImageRef myDupImage = [context
                          createCGImage:dupciImage
                          fromRect:CGRectMake(0, 0,
                                              CVPixelBufferGetWidth(pixelBuffer),
                                              CVPixelBufferGetHeight(pixelBuffer))];
    UIImage *dupImage = [UIImage imageWithCGImage:myDupImage];
    free(dupData);
    CGImageRelease(myDupImage);
#endif

    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.cbImageView.image = liveImage;
        [self.cbImageView setNeedsDisplay];
    });

#ifdef notdef
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
#endif
#endif
    
}

- (void) processImage:(u_char *)buffer w:(size_t)w h:(size_t)h {
#ifdef notdef
//    NSLog(@"process %zu %zu", w, h);
    
    cbImage.buffer = buffer;
    cbImage.width = w;
    cbImage.height = h;
    [cbImage setNeedsDisplay];
#endif
}

@end
