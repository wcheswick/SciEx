//
//  SoundVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "Defines.h"
#import "OrderedDictionary.h"
#import "SoundVC.h"
#import "WaveView.h"
#import "XAxisView.h"

// keys used by dictionaries in soundSampleSections:

#define kFileName   @"FileName"
#define kDescription    @"Description"

#define MikeSegment 0

@interface SoundVC ()

@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UITableView *sampleTableView;
@property (nonatomic, strong)   UIView *controlsView;
@property (nonatomic, strong)   UIButton *mikeButton;
@property (nonatomic, strong)   UIToolbar *playControlBar;
@property (nonatomic, strong)   UISegmentedControl *selectInput;
@property (nonatomic, strong)   UIView *FFTView;
@property (nonatomic, strong)   WaveView *waveView;
@property (nonatomic, strong)   XAxisView *xAxisView;

@property (nonatomic, strong)   OrderedDictionary *soundSampleSections;
@property (assign)              BOOL AGC;

@end

@implementation SoundVC

@synthesize containerView;
@synthesize sampleTableView;
@synthesize controlsView, selectInput, playControlBar;
@synthesize mikeButton;
@synthesize FFTView;
@synthesize waveView;
@synthesize xAxisView;

@synthesize soundSampleSections;
@synthesize AGC;

- (id)init {
    self = [super init];
    if (self) {
        exhibitTitle = @"What does sound look like?";
        exhibitAvailable = YES;
        soundSampleSections = [[OrderedDictionary alloc] init];
        AGC = NO;
        
        [self readSoundList];
    }
    return self;
}

- (void) readSoundList {
    NSString *soundIndexPath = [[NSBundle mainBundle]
                                     pathForResource:@"index"ofType:@""];
    if (!soundIndexPath) {
        NSLog(@"*** Sound index file missing sequences missing");
        return;
    }
    
    NSError *error;
    NSString *soundIndex = [NSString stringWithContentsOfFile:soundIndexPath
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    if (!soundIndex || [soundIndex isEqualToString:@""] || error) {
        NSLog(@"sound index list error: %@", [error localizedDescription]);
        return;
    }
    
    // Entries look like this:
    
    // #Section-name
    // selection-name<whitespace>Description
    
    NSArray *lines = [soundIndex componentsSeparatedByString:@"\n"];
    NSLog(@" number of sounds lines: %lu", (unsigned long)lines.count);

    NSMutableArray *sectionEntries = nil;
    
    for (NSString *line in lines) {
        if (line.length == 0 || [line isEqualToString:@""] )
            continue;
        if ([line hasPrefix:@"#"]) {    // new section
            NSString *sectionName = [line substringFromIndex:1];
//            NSLog(@"new section: %@", sectionName);
            sectionEntries = [[NSMutableArray alloc] init];
            [soundSampleSections addObject:sectionEntries withKey:sectionName];
        } else {    // new sound in current section
            NSRange tabIndex = [line rangeOfString:@"\t"];
            if (tabIndex.location == NSNotFound) {
                NSLog(@"malformed entry: '%@'", line);
                continue;
            }
            NSString *fileName = [line substringToIndex:tabIndex.location];
            NSString *samplePath = [[NSBundle mainBundle]
                                        pathForResource:fileName ofType:@"wav"];
            if (![[NSFileManager defaultManager] fileExistsAtPath:samplePath]) {
                NSLog(@"sound sample file missing: '%@', skipped", fileName);
                continue;
            }

//            NSLog(@"    file name: %@", fileName);
            NSString *description = [[line substringFromIndex:tabIndex.location+1]
                                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//            NSLog(@"            description: %@", description);
            NSDictionary *entryInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       fileName, kFileName,
                                       description, kDescription,
                                       nil];
            [sectionEntries addObject:entryInfo];
        }
    }
}

#define PLAY_CONTROL_H  50
#define MIKE_BUTTON_W   100
#define CONTROLS_H  50
#define WAVE_H    200
#define FFT_H   WAVE_H
#define INPUT_SELECTOR_W  150
#define INPUT_SELECTOR_H    50
#define SAMPLE_TABLE_H  150

#define X_AXIS_H    20


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.toolbarHidden = YES;
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doDone:)];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor whiteColor];
    
    FFTView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, LATER, FFT_H)];
    FFTView.layer.borderWidth = 1;
    FFTView.layer.borderColor = [UIColor redColor].CGColor;
    [containerView addSubview:FFTView];

    waveView = [[WaveView alloc] initWithFrame:CGRectMake(0, BELOW(FFTView.frame) + SEP,
                                                          LATER, WAVE_H)];
    waveView.layer.borderWidth = 1;
    waveView.layer.borderColor = [UIColor orangeColor].CGColor;
    [containerView addSubview:waveView];

    xAxisView = [[XAxisView alloc]
                 initWithFrame:CGRectMake(0, BELOW(waveView.frame),
                                          LATER, X_AXIS_H)];
    xAxisView.layer.borderWidth = 1;
    xAxisView.layer.borderColor = [UIColor yellowColor].CGColor;
    [containerView addSubview:xAxisView];
    
    controlsView = [[UIView alloc]
                    initWithFrame:CGRectMake(0, BELOW(xAxisView.frame),
                                             LATER, CONTROLS_H)];
    controlsView.layer.borderWidth = 1;
    controlsView.layer.borderColor = [UIColor greenColor].CGColor;
    controlsView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0,
                                                                 LATER, PLAY_CONTROL_H)];
    playControlBar.opaque = YES;
    playControlBar.backgroundColor = [UIColor whiteColor];
    //    playControlBar.opaque = YES;
    //    playControlBar.translucent = YES;
    playControlBar.backgroundColor = [UIColor purpleColor];
    [controlsView addSubview:playControlBar];
    
    [self adjustPlayControlBar];
    
    UISegmentedControl *selectInput = [[UISegmentedControl alloc]
                                       initWithItems:@[@"Mike", @"Samples"]];
    selectInput.frame = CGRectMake(0, BELOW(playControlBar.frame) + SEP, INPUT_SELECTOR_W, INPUT_SELECTOR_H);
    [selectInput addTarget:self
                    action:@selector(changeInput:)
          forControlEvents:UIControlEventValueChanged];
    selectInput.selectedSegmentIndex = MikeSegment;
    [controlsView addSubview:selectInput];

    mikeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    mikeButton.enabled = [self mikeAvailable];
    mikeButton.frame = CGRectMake(RIGHT(selectInput.frame) + 3*SEP, selectInput.frame.origin.y,
                                  MIKE_BUTTON_W, selectInput.frame.size.height);
    [mikeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [mikeButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [mikeButton setTitle:@"Mike On" forState:UIControlStateNormal];
    [mikeButton setTitle:@"Mike Off" forState:UIControlStateSelected];
    mikeButton.titleLabel.font = [UIFont boldSystemFontOfSize: BUTTON_FONT_SIZE];
    [mikeButton addTarget:self action:@selector(doMike:)
         forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview:mikeButton];
    
    SET_VIEW_HEIGHT(controlsView, BELOW(selectInput.frame));
    controlsView.backgroundColor = [UIColor greenColor];
    [containerView addSubview:controlsView];

    sampleTableView = [[UITableView alloc]
                  initWithFrame:CGRectMake(0, BELOW(controlsView.frame), LATER, SAMPLE_TABLE_H)
                  style:UITableViewStyleGrouped];
    sampleTableView.delegate = self;
    sampleTableView.dataSource = self;
    sampleTableView.backgroundColor = [UIColor whiteColor];
    sampleTableView.layer.borderWidth = 1;
    sampleTableView.layer.borderColor = [UIColor greenColor].CGColor;
//    [containerView addSubview:sampleTableView];

    [self.view addSubview:containerView];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void) adjustPlayControlBar {
    UIBarButtonItem *flexiableItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIButton *AGCButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    AGCButton.enabled = NO;
    mikeButton.frame = CGRectMake(RIGHT(selectInput.frame) + 3*SEP, selectInput.frame.origin.y,
                                  MIKE_BUTTON_W, selectInput.frame.size.height);
    [AGCButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [AGCButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [AGCButton setTitle:@"AGC on " forState:UIControlStateNormal];
    [AGCButton setTitle:@"AGC off" forState:UIControlStateSelected];
    AGCButton.titleLabel.font = [UIFont boldSystemFontOfSize: BUTTON_FONT_SIZE];
    [AGCButton addTarget:self action:@selector(doAGC:)
         forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *AGCBarButton = [[UIBarButtonItem alloc]
                                  initWithCustomView:AGCButton];

#ifdef notdef
    UIBarButtonItem *rewindButton = [[UIBarButtonItem alloc]
                                    initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                    target:self action:@selector(doRewind:)];
    rewindButton.enabled = NO;
    UIBarButtonItem *redoButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemRedo
                                   target:self action:@selector(doRedo:)];
    redoButton.enabled = NO;
    
    UIBarButtonItem *startStopButton;
    if (mikeIsOn)
        startStopButton = [[UIBarButtonItem alloc]
                           initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                           target:self
                           action:@selector(doStop:)];
    else
        startStopButton = [[UIBarButtonItem alloc]
                           initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                           target:self
                           action:@selector(doStart:)];
#endif

    playControlBar.items = [NSArray arrayWithObjects:
                               flexiableItem,
                            AGCBarButton, flexiableItem,
 //                              rewindButton, flexiableItem,
 //                              startStopButton, flexiableItem,
                               nil];
    [playControlBar setNeedsDisplay];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    containerView.frame = self.view.frame;
    SET_VIEW_Y(containerView, BELOW(self.navigationController.navigationBar.frame));
    SET_VIEW_HEIGHT(containerView, containerView.frame.size.height - containerView.frame.origin.y);
    containerView.frame = CGRectInset(containerView.frame, INSET, INSET);
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.opaque = YES;
    
    SET_VIEW_WIDTH(FFTView, containerView.frame.size.width);
    SET_VIEW_WIDTH(waveView, containerView.frame.size.width);
    SET_VIEW_WIDTH(xAxisView, containerView.frame.size.width);
    SET_VIEW_WIDTH(playControlBar, containerView.frame.size.width);
    SET_VIEW_WIDTH(controlsView, containerView.frame.size.width);
    SET_VIEW_WIDTH(sampleTableView, containerView.frame.size.width);
    [sampleTableView reloadData];
    
    [waveView setNeedsLayout];
    [self changeInput:selectInput];
}

- (IBAction)changeInput:(UISegmentedControl *)sender {
    NSLog(@"selected input %ld", (long)sender.selectedSegmentIndex);
    if (sender.selectedSegmentIndex == MikeSegment) {
        NSString *err = [self setupMike];
        if (err) {
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
        } else {
            sampleTableView.userInteractionEnabled = NO;
            mikeButton.enabled = YES;
        }
    } else {
        [self mikeOn: NO];
        mikeButton.enabled = NO;
        sampleTableView.userInteractionEnabled = YES;
    }
}


- (IBAction)doAGC:(UIButton *)b {
    AGC = b.selected = !b.selected;
    NSLog(@"AGC is now %@", AGC ? @"ON" : @"OFF");
}

- (IBAction)doMike:(UIButton *)sender {
    mikeButton.selected = !mikeButton.selected;
    if (mikeButton.selected) {
        [self mikeOn:YES];
    } else
        [self mikeOn:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return soundSampleSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *samplesList = [soundSampleSections objectAtIndex:section];
    return samplesList.count;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
    NSString *key = [soundSampleSections keyAtIndex:section];
    return key;
}

#define CellId  @"TVCellID"

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellId];
    }
    NSArray *samplesList = [soundSampleSections objectAtIndex:indexPath.section];
    NSDictionary *sample = [samplesList objectAtIndex:indexPath.row];
    NSString *description = [sample objectForKey:kDescription];
    cell.textLabel.text = description;
    cell.indentationLevel = 5;
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *samplesList = [soundSampleSections objectAtIndex:indexPath.section];
    NSDictionary *sample = [samplesList objectAtIndex:indexPath.row];
    NSLog(@"selected sample file %@", [sample objectForKey:kFileName]);
}

static u_long inputCount = 0;

// The microphone has delivered one or more buffers of sound.

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    size_t sampleSize = CMSampleBufferGetSampleSize(sampleBuffer,0);
    assert(sampleSize == sizeof(Sample));
    size_t sampleCount = CMSampleBufferGetNumSamples(sampleBuffer);
    size_t sampleLength = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    assert(sampleSize * sampleCount == sampleLength);
    
    if (samples_count + sampleCount > samples_alloc) {
        if (samples_count + sampleCount == MAX_SAMPLES) {
            NSLog(@"*** buffer full, now what?");
            return;
        }
        samples_alloc += SAMPLE_MEM_INCR;
        if (samples_alloc > MAX_SAMPLES)
            samples_alloc = MAX_SAMPLES;
        samples = (Sample *)realloc(samples, samples_alloc*sizeof(Sample));
        assert(samples);
    }

    CMBlockBufferRef blockbuff = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus stat = CMBlockBufferCopyDataBytes(blockbuff,
                                      0,
                                      sampleLength,
                                      &samples[samples_count]);
    if (stat != kCMBlockBufferNoErr) {
        NSLog(@"sound block fetch error %d", (int)stat);
        return;
    }
    inputCount += sampleCount;
    samples_count += sampleCount;
    [waveView updateView];
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
