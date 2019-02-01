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
@property (nonatomic, strong)   UIView *cbView;
@property (nonatomic, strong)   PixelView *cbImage;

@end

@implementation ColorBlindVC

@synthesize top;
@synthesize liveView;
@synthesize cbView, cbImage;

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
    
    cbView = [[UIView alloc] init];
    cbView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:cbView];

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
    
    f.origin.y = BELOW(f) + SEP;
    cbView.frame = f;
    [cbView setNeedsDisplay];
    
    f.origin = CGPointMake(0, 0);
    cbImage = [[PixelView alloc] initWithFrame:f];
    cbImage.backgroundColor = [UIColor greenColor];
    [cbView addSubview:cbImage];
    
    if ([self selectCamera:AVCaptureDevicePositionFront]) {
        [self setLiveFrameAndOrientation:liveView.frame];
        [self startVideoCapture:liveView.frame.size liveView:liveView];
    } else {
        NSLog(@"XXX no camera available");
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self stopVideoCapture];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) processImage:(u_char *)buffer w:(size_t)w h:(size_t)h {
//    NSLog(@"process %zu %zu", w, h);
    
    cbImage.buffer = buffer;
    cbImage.width = w;
    cbImage.height = h;
    [cbImage setNeedsDisplay];
}

@end
