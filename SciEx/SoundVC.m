//
//  SoundVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "SoundVC.h"
#import "WaveView.h"
#import "Defines.h"

@interface SoundVC ()

@property (nonatomic, strong)   UIView *sourceView;
@property (nonatomic, strong)   WaveView *waveView;
@property (nonatomic, strong)   UIView *FFTView;

@property (nonatomic, strong)   UIButton *mikeButton;

@end

@implementation SoundVC

@synthesize sourceView;
@synthesize waveView;
@synthesize FFTView;
@synthesize mikeButton;

- (id)init {
    self = [super init];
    if (self) {
        exhibitTitle = @"What does sound look like?";
        exhibitAvailable = YES;
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

    sourceView = [[UIView alloc]
                  initWithFrame:CGRectMake(0, LATER, LATER, LATER)];
    [self.view addSubview:sourceView];
    
    mikeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    mikeButton.enabled = [self mikeAvailable];
    mikeButton.frame = CGRectMake(0, 0, 100, BUTTON_H);
    [mikeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [mikeButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [mikeButton setTitle:@"Mike On" forState:UIControlStateNormal];
    [mikeButton setTitle:@"Mike Off" forState:UIControlStateSelected];
    mikeButton.titleLabel.font = [UIFont boldSystemFontOfSize: BUTTON_FONT_SIZE];
    [mikeButton addTarget:self action:@selector(doMike:)
     forControlEvents:UIControlEventTouchUpInside];
    [sourceView addSubview:mikeButton];
    SET_VIEW_HEIGHT(sourceView, BELOW(mikeButton.frame));
    SET_VIEW_WIDTH(sourceView, RIGHT(mikeButton.frame));

    waveView = [[WaveView alloc] init];
    waveView.backgroundColor = [UIColor yellowColor];
    waveView.layer.borderColor = [UIColor blackColor].CGColor;
    waveView.layer.borderWidth = 0.5;
    waveView.layer.cornerRadius = 1.0;
    [self.view addSubview:waveView];

    FFTView = [[UIView alloc] init];
    [self.view addSubview:FFTView];

    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    SET_VIEW_Y(self.view, BELOW(self.navigationController.navigationBar.frame));
    SET_VIEW_HEIGHT(self.view, self.view.frame.size.height - self.view.frame.origin.y);
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.opaque = YES;
    
    SET_VIEW_Y(sourceView, self.view.frame.size.height - sourceView.frame.size.height);
    [sourceView setNeedsDisplay];
    
#define WAVE_H    200
    waveView.frame = CGRectMake(INSET, sourceView.frame.origin.y - SEP - WAVE_H,
                                self.view.frame.size.width - 2*INSET, WAVE_H);
    [waveView setNeedsLayout];
}

- (IBAction)doMike:(UIButton *)sender {
    mikeButton.selected = !mikeButton.selected;
    if (mikeButton.selected) {
        NSString *err = [self startAudioCapture];
        if (err) {
            mikeButton.selected = NO;
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Could not start microphone"
                                                                           message:err
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Dismiss"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      ;
                                                                  }
                                            ];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else
        [self stopAudioCapture];
}

static u_long inputCount = 0;

// The microphone has delivered one or more buffers of sound.

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {

    size_t sampleSize = CMSampleBufferGetSampleSize(sampleBuffer,0);
    assert(sampleSize == sizeof(Sample));
    size_t sampleCount = CMSampleBufferGetNumSamples(sampleBuffer);
    size_t sampleLength = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    assert(sampleSize * sampleCount == sampleLength);
    
    if (sampleLength > samples_alloc) {
        samples_alloc = sampleLength;
        samples = (Sample *)realloc(samples, samples_alloc);
        assert(samples);
    }

    CMBlockBufferRef blockbuff = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus stat = CMBlockBufferCopyDataBytes(blockbuff,
                                      0,
                                      sampleLength,
                                      samples);
    if (stat != kCMBlockBufferNoErr) {
        NSLog(@"sound block fetch error %d", (int)stat);
        return;
    }
    inputCount += sampleCount;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.waveView showSamples:0 count:sampleCount];
    });
}

- (void) newAudioData: (NSData *)buffer {
#ifdef notdef
    size_t nSamples = [buffer length]/sizeof(DEFAULT_SAMPLE_TYPE);
    if (amp.len + nSamples > amp.alloc) {
        // amp buffer is full.  If we are paused for analysis,
        // drop the data, so we don't move the buffer, else
        // forget a chunk, and continue
        if (paused) {
            overflow++;
        } else {
            size_t sToForget = amp.alloc*AMP_REDUCE_PCT/100.0;
            if (sToForget > amp.len)    // should never happen, but ok
                sToForget = amp.len;
            NSLog(@"shift, @%zu: forget %zu from %zu",
                  ampStartSampleNumber, sToForget, amp.len);
            memmove(&AMP[0], &AMP[sToForget], sizeof(AMP[0])*(amp.len - sToForget));
            amp.len -= sToForget;
            ampStartSampleNumber += sToForget;
        }
    }
    
    short *raw = (short *)[buffer bytes];
    size_t i;
    for (i=0; i<nSamples && amp.len + i < amp.alloc; i++) {
        ushort a = abs(raw[i]);
        if (a > amp.maximum)
            amp.maximum = a;
        if (a < amp.minimum)
            amp.minimum = a;
        AMP[amp.len++] = a;
    }
    
    long ampStart = amp.len - msToSamples(srcGraphWidthMs);
    long sourceLen = amp.len - ampStart;
    if (ampStart < 0)
        ampStart = 0;
    [sourceView xRangeFrom:sToMs(ampStart + ampStartSampleNumber)
                        to:sToMs(ampStart + sourceLen + ampStartSampleNumber)];
    [sourceView plotClipsFrom: ampStart width:sourceLen];
    [self setNeedsDisplay];
    busy = NO;
    
    [self processSample];
#endif
}

- (void) processSample {
#ifdef notdef
    long processLen = msToSamples(procGraphWidthMs);
    long processStart = amp.len - processLen;
    if (processStart < 0) {
        processLen += processStart;
        processStart = 0;
    }
    [self processSampleFrom: processStart length:processLen];
    [processedView xRangeFrom:sToMs(processStart + ampStartSampleNumber)
                           to:sToMs(processStart + ampStartSampleNumber + processLen)];
    [processedView plotClipsFrom:0 width:processLen];
#endif
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
