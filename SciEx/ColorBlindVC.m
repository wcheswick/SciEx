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

@property (nonatomic, strong)   UICollectionView *srcCollectionView;
@property (nonatomic, strong)   UICollectionView *defCollectionView;
@property (nonatomic, strong)   UICollectionViewFlowLayout *layout;

@property (assign)              BOOL transformReady;
@property (assign)              BOOL fullScreenCB;

@end

static Pixel *abgr = 0;
static size_t w = 0;
static size_t h = 0;

static BOOL busy = NO;
static int busyCount = 0;

@implementation ColorBlindVC

static NSString * const reuseIdentifier = @"cbCells";
//static NSString * const srcReuseIdentifier = @"cbCells";
//static NSString * const defReuseIdentifier = @"DefCell";

static char *src_images[] = {
    "cube.jpeg",
    "ishihara6.jpeg",
    "ishihara8.jpeg",
    "ishihara25.jpeg",
    "ishihara29.jpeg",
    "ishihara45.jpeg",
    "ishihara56.jpeg",
    "ishihara74.gif",
    "rainbow.gif",
    0,
};
#define NSRC    ((sizeof(src_images)/(sizeof(char *)))-1)    // plus live

#define SRC_TAG 1000
#define DEF_TAG 1001
#define LIVE_TAG    2000

#define IMAGE_BUTTON_W    70
#define IMAGE_BUTTON_H    IMAGE_BUTTON_W

#define DEF_BUTTON_W    120
#define DEF_BUTTON_H    60

@synthesize top;
@synthesize liveView, liveImageView;
@synthesize cbView, cbImageView;
@synthesize transformReady;
@synthesize fullScreenCB;
@synthesize srcCollectionView, defCollectionView;
@synthesize layout;

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
    
    
    layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(INSET, INSET, INSET, INSET);
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;

#ifdef NOTUSED
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
#endif
    
    liveView = [[UIView alloc] init];
    liveView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:liveView];
    liveImageView = [[UIImageView alloc] init];
    liveImageView.contentMode = UIViewContentModeScaleAspectFit;
    [liveView addSubview:liveImageView];
    
    srcCollectionView = [[UICollectionView alloc]
                      initWithFrame:CGRectZero
                      collectionViewLayout:layout];
    srcCollectionView.dataSource = self;
    srcCollectionView.delegate = self;
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [srcCollectionView registerClass:[UICollectionViewCell class]
       forCellWithReuseIdentifier:reuseIdentifier];
    srcCollectionView.backgroundColor = [UIColor whiteColor];
    srcCollectionView.tag = SRC_TAG;
    [liveView addSubview:srcCollectionView];

    cbView = [[UIView alloc] init];
    [self.view addSubview:cbView];
    cbImageView = [[UIImageView alloc] init];
    cbImageView.contentMode = UIViewContentModeScaleAspectFit;
    [cbView addSubview:cbImageView];
    
    defCollectionView = [[UICollectionView alloc]
                         initWithFrame:CGRectZero
                         collectionViewLayout:layout];
    defCollectionView.dataSource = self;
    defCollectionView.delegate = self;
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [defCollectionView registerClass:[UICollectionViewCell class]
          forCellWithReuseIdentifier:reuseIdentifier];
    defCollectionView.backgroundColor = [UIColor whiteColor];
    defCollectionView.tag = DEF_TAG;
    [cbView addSubview:defCollectionView];
    
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
        cbImageView.frame = CGRectMake(0, 0, f.size.width, f.size.height*0.6);
        
        f.origin = CGPointMake(INSET, BELOW(cbImageView.frame) + SEP);
        f.size = CGSizeMake(f.size.width - 2*INSET, cbView.frame.size.height - f.origin.y);
        defCollectionView.frame = f;
    } else {
        f.origin = CGPointMake(INSET, self.view.frame.origin.y);
        f.size = CGSizeMake((self.view.frame.size.width - 2*INSET - INSET)/2.0,
                            (self.view.frame.size.height - f.origin.y));
        liveView.frame = f;
        liveImageView.frame = CGRectMake(0, 0, f.size.width, f.size.height*0.65);
        [liveImageView setNeedsDisplay];
        
        f.origin = CGPointMake(INSET, BELOW(liveImageView.frame) + SEP);
        f.size = CGSizeMake(f.size.width - 2*INSET, liveView.frame.size.height - f.origin.y);
        srcCollectionView.frame = f;

        cbView.frame = liveView.frame;
        SET_VIEW_X(cbView, RIGHT(liveView.frame) + INSET);
        cbImageView.frame = liveImageView.frame;
        
        f.origin = CGPointMake(INSET, BELOW(cbImageView.frame) + SEP);
        f.size = CGSizeMake(f.size.width - 2*INSET, cbView.frame.size.height - f.origin.y);
        defCollectionView.frame = f;
    }
    [liveView setNeedsDisplay];
    [cbView setNeedsDisplay];
    [cbImageView setNeedsDisplay];
    [defCollectionView setNeedsLayout];
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
    
    UIActivityIndicatorView *busy = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    busy.frame = CGRectMake(0, 0, cbImageView.frame.size.width, cbImageView.frame.size.height);
    busy.hidesWhenStopped = YES;
    busy.backgroundColor = [UIColor darkGrayColor];
    busy.backgroundColor = [UIColor whiteColor];
    [cbImageView addSubview:busy];
    
    [busy startAnimating];
    init_colorblind(TRITANOPIA);
    [busy stopAnimating];
    
    self.cbView.backgroundColor = [UIColor whiteColor];
    self.transformReady = YES;
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    transformReady = NO;
    if (abgr) {
        free(abgr);
        NSLog(@"Freed");
        abgr = 0;
    }
    NSLog(@"clearing colorblind table");
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
    
    if (!fullScreenCB) {
        UIImage *liveImage = [UIImage imageWithCGImage:liveImageRef];
        
        //    NSLog(@"o: %ld", (long)liveImage.imageOrientation);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.liveImageView.image = [UIImage imageWithCGImage:[liveImage CGImage]
                                                           scale:[liveImage scale]
                                                     orientation: UIImageOrientationRight];
            [self.liveImageView setNeedsDisplay];
        });
    }

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
        UIImage *cbImage = [UIImage imageWithCGImage:cbImageRef];
        
        CGImageRelease(cbImageRef);
        CGContextRelease(gtx);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.cbImageView.image = [UIImage imageWithCGImage:[cbImage CGImage]
                                                         scale:[cbImage scale]
                                                   orientation: UIImageOrientationRight];;
            [self.cbImageView setNeedsDisplay];
            busy = NO;
        });
    }
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    CGImageRelease(liveImageRef);
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView.tag == DEF_TAG) {
        int i;
        for (i=0; deficits[i].name; i++) {  // run through the available color deficits
            ;
        }
        NSLog(@"inputs: %d", i);
        return i;
    } else {
        NSLog(@" NSRC = %lu", NSRC);
        return NSRC + 1;   // live + others
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                                          forIndexPath:indexPath];;
    if (collectionView.tag == DEF_TAG) {
        UILabel *label = [[UILabel alloc]
                          initWithFrame:CGRectMake(0, 0,
                                                   cell.frame.size.width,
                                                   cell.frame.size.height)];
        label.text = [NSString stringWithUTF8String: deficits[indexPath.row].name];
        [cell addSubview:label];
        //[NSString stringWithUTF8String: deficits[indexPath.row].description];
    } else {
        if (indexPath.row == 0) {   // Live button
            UILabel *label = [[UILabel alloc]
                              initWithFrame:CGRectMake(0, 0,
                                                       cell.frame.size.width,
                                                       cell.frame.size.height)];
             label.text = @"Live";
            [cell addSubview:label];
        } else {    // one of our images
            NSString *imageName = [NSString stringWithUTF8String:src_images[indexPath.row]];
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
            assert(imagePath);
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            assert(image);
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.layer.borderColor = [UIColor blueColor].CGColor;
            imageView.layer.borderWidth = 0.5;
            imageView.layer.cornerRadius = 5.0;
            imageView.frame = cell.contentView.frame;
            [cell.contentView addSubview:imageView];
        }
    }
    
#ifdef notdef
    label.textColor = [UIColor blueColor];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:20];
    label.layer.borderWidth = 0.5;
    label.layer.borderColor = [UIColor blackColor].CGColor;
    label.layer.cornerRadius = 10.0;
    [cell addSubview:label];
#endif
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == DEF_TAG) {
        return CGSizeMake(IMAGE_BUTTON_W, IMAGE_BUTTON_H);
    } else {
        return CGSizeMake(DEF_BUTTON_W, DEF_BUTTON_H);
    }
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == DEF_TAG) {
        ColorblindDeficiency def = (ColorblindDeficiency)indexPath.row;
        NSString *defName = [NSString stringWithUTF8String:deficits[def].name];
        NSLog(@"select deficit %@", defName);
     } else {
         if (indexPath.row == 0)
             NSLog(@"select live source");
         else {
             NSString *source = [NSString stringWithUTF8String:src_images[indexPath.row]];
             NSLog(@"select source %@", source);
         }
    }
}

@end
