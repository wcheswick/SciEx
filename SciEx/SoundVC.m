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
#import "AudioClip.h"
#import "WaveView.h"
#import "SpectrumView.h"
#import "XAxisView.h"

// keys used by dictionaries in soundClipSections:

#define kFileName   @"FileName"
#define kDescription    @"Description"

#define kLastClipChosen   @"LastClipChosen"

typedef enum {
    MikeSegment = 0,
    FileSegment = 1,
} SegmentChoice;

@interface SoundVC ()

@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UITableView *sampleTableView;
@property (nonatomic, strong)   UIView *controlsView;
@property (nonatomic, strong)   UIButton *mikeButton;
@property (nonatomic, strong)   UIToolbar *playControlBar;
@property (nonatomic, strong)   UISegmentedControl *selectInput;
@property (nonatomic, strong)   SpectrumView *spectrumView;
@property (assign)              CGSize spectrumViewSize;
@property (nonatomic, strong)   WaveView *waveView;
@property (nonatomic, strong)   XAxisView *xAxisView;

@property (nonatomic, strong)   OrderedDictionary *soundClipSections;
@property (assign)              BOOL AGC;
@property (nonatomic, strong)   AudioClip *audioClip;
@property (nonatomic, strong)   NSString *currentClipFile;

@property (assign)              long displayFirst, displayCount;

@property (assign)              long graphStart, graphCount;

// for pinch processing

@property (assign)              CGPoint startLeftTouch, startRightTouch;
@property (assign)              long startStart, startCount, startPan;
@property (assign)              CGFloat startPanX;

@end

@implementation SoundVC

@synthesize containerView;
@synthesize sampleTableView;
@synthesize controlsView, selectInput, playControlBar;
@synthesize mikeButton;
@synthesize spectrumView;
@synthesize spectrumViewSize;
@synthesize waveView;
@synthesize xAxisView;

@synthesize soundClipSections;
@synthesize currentClipFile;
@synthesize AGC;

@synthesize audioClip;

@synthesize displayFirst, displayCount;
@synthesize startLeftTouch, startRightTouch;
@synthesize startStart, startCount, startPan, startPanX;

- (id)init {
    self = [super init];
    if (self) {
        exhibitTitle = @"What does sound look like?";
        exhibitAvailable = YES;
        soundClipSections = [[OrderedDictionary alloc] init];
        AGC = NO;
        displayFirst = 0;
        displayCount = 0;
        audioClip = nil;
        currentClipFile = nil;
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
            [soundClipSections addObject:sectionEntries withKey:sectionName];
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
    
    spectrumView = [[SpectrumView alloc]
                    initWithFrame:CGRectMake(0, 0, LATER, FFT_H)];
    spectrumView.layer.borderWidth = 1;
    spectrumView.layer.borderColor = [UIColor redColor].CGColor;
    spectrumView.userInteractionEnabled = YES;
    
    UIPinchGestureRecognizer *pinchSpectrum = [[UIPinchGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(doPinchSpectrum:)];
    [spectrumView addGestureRecognizer:pinchSpectrum];
    
    UIPanGestureRecognizer *panSpectrum = [[UIPanGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(doPanSpectrum:)];
    [spectrumView addGestureRecognizer:panSpectrum];
    
    UITapGestureRecognizer *tapSpectrum = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(doTapSpectrum:)];
    [spectrumView addGestureRecognizer:tapSpectrum];

    [containerView addSubview:spectrumView];

    waveView = [[WaveView alloc]
                initWithFrame:CGRectMake(0, BELOW(spectrumView.frame) + SEP,
                                         LATER, WAVE_H)];
    waveView.layer.borderWidth = 1;
    waveView.layer.borderColor = [UIColor orangeColor].CGColor;

    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(doPinchAudio:)];
    [waveView addGestureRecognizer:pinch];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(doPanAudio:)];
    [waveView addGestureRecognizer:pan];

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
    
    playControlBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0,
                                                                 LATER, PLAY_CONTROL_H)];
    playControlBar.opaque = YES;
    playControlBar.backgroundColor = [UIColor whiteColor];
    [controlsView addSubview:playControlBar];
    
    [self adjustPlayControlBar];
    
    UISegmentedControl *selectInput = [[UISegmentedControl alloc]
                                       initWithItems:@[@"Mike", @"Samples"]];
    selectInput.frame = CGRectMake(0, BELOW(playControlBar.frame) + SEP,
                                   INPUT_SELECTOR_W, INPUT_SELECTOR_H);
    [selectInput addTarget:self
                    action:@selector(changeInput:)
          forControlEvents:UIControlEventValueChanged];
    [controlsView addSubview:selectInput];

    mikeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    mikeButton.enabled = [AudioClip mikeAvailable];
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
    [containerView addSubview:controlsView];

    sampleTableView = [[UITableView alloc]
                  initWithFrame:CGRectMake(0, BELOW(controlsView.frame), LATER, SAMPLE_TABLE_H)
                  style:UITableViewStyleGrouped];
    sampleTableView.delegate = self;
    sampleTableView.dataSource = self;
    sampleTableView.backgroundColor = [UIColor whiteColor];
    sampleTableView.layer.borderWidth = 1;
    sampleTableView.layer.borderColor = [UIColor greenColor].CGColor;
    [containerView addSubview:sampleTableView];

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
    
    SET_VIEW_WIDTH(spectrumView, containerView.frame.size.width);
    spectrumViewSize = spectrumView.frame.size;   // a non-main thread size
    SET_VIEW_WIDTH(waveView, containerView.frame.size.width);
    SET_VIEW_WIDTH(xAxisView, containerView.frame.size.width);
    SET_VIEW_WIDTH(playControlBar, containerView.frame.size.width);
    SET_VIEW_WIDTH(controlsView, containerView.frame.size.width);
    SET_VIEW_WIDTH(sampleTableView, containerView.frame.size.width);
    [sampleTableView reloadData];
    
    audioClip = [[AudioClip alloc] init];
    selectInput.enabled = NO;
    if (mikeButton.enabled) {   // try to setup mike
        NSString *err = [audioClip initializeMikeForTarget:self];
        if (!err) {
            selectInput.selectedSegmentIndex = MikeSegment;
            selectInput.enabled = YES;
            [waveView useClip:audioClip];
            xAxisView.audioClip = audioClip;
        } else
            NSLog(@"mike initialization error %@", err);
    }
    if (!selectInput.enabled) {
        selectInput.selectedSegmentIndex = FileSegment;
        selectInput.enabled = YES;
        currentClipFile = [[NSUserDefaults standardUserDefaults] stringForKey:kLastClipChosen];
        if (currentClipFile) {
            NSString *err = [audioClip initializeFromPath:currentClipFile];
            if (err)
                NSLog(@"path source initialization error %@", err);
            else {
                [waveView useClip:audioClip];
                xAxisView.audioClip = audioClip;
            }
        }
    }
    [selectInput setNeedsDisplay];
    
    displayCount = 5*audioClip.sampleRate;

    [waveView setNeedsLayout];
    [self changeInput:selectInput];
}

- (IBAction)changeInput:(UISegmentedControl *)sender {
    NSLog(@"selected input %ld", (long)sender.selectedSegmentIndex);
    if (sender.selectedSegmentIndex == MikeSegment) {
        audioClip = [[AudioClip alloc] init];
        NSString *err = [audioClip initializeMikeForTarget:self];
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
            [waveView useClip:audioClip];
            xAxisView.audioClip = audioClip;
            sampleTableView.userInteractionEnabled = NO;
            mikeButton.enabled = YES;
        }
    } else {
        NSLog(@"XXXXXXX switch to file sample");
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
        [audioClip startMike];
    } else
        [audioClip stopMike];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return soundClipSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *samplesList = [soundClipSections objectAtIndex:section];
    return samplesList.count;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
    NSString *key = [soundClipSections keyAtIndex:section];
    return key;
}

#define CellId  @"AudioAudioClipCellID"

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellId];
    }
    NSArray *samplesList = [soundClipSections objectAtIndex:indexPath.section];
    NSDictionary *sample = [samplesList objectAtIndex:indexPath.row];
    NSString *description = [sample objectForKey:kDescription];
    cell.textLabel.text = description;
    cell.indentationLevel = 5;
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *samplesList = [soundClipSections objectAtIndex:indexPath.section];
    NSDictionary *sample = [samplesList objectAtIndex:indexPath.row];
    NSLog(@"selected sample file %@", [sample objectForKey:kFileName]);
}

- (void) displayRangeFrom:(size_t)first length:(size_t)count {
    [waveView showRangeFrom:first count:count];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self->xAxisView range:self->displayFirst to:self->displayFirst + count];
    });
}

- (IBAction)doPanAudio:(UIPanGestureRecognizer *)sender {
    if ([sender numberOfTouches] < 1)
        return;
    CGPoint touch = [sender locationOfTouch:0 inView:sender.view];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            startPanX = touch.x;
            startPan = displayFirst;
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded: {
            CGFloat samplesPerPixel = displayCount/waveView.graphWidth;
            CGFloat dx = startPanX - touch.x;
            displayFirst = startPan + dx*samplesPerPixel;
            if (displayFirst < 0)
                displayFirst = 0;
            if (displayFirst + displayCount > audioClip.sampleCount)
                displayFirst = audioClip.sampleCount - displayCount;
            [self displayRangeFrom:displayFirst length:displayCount];
            break;
        }
        default:
            ;
    }
}

- (IBAction)doPinchAudio:(UIPinchGestureRecognizer *)sender {
    if ([sender numberOfTouches] < 2)
        return;
    CGPoint touchLeft = [sender locationOfTouch:0 inView:sender.view];
    CGPoint touchRight = [sender locationOfTouch:1 inView:sender.view];
    if (touchRight.x < touchLeft.x) {
        CGPoint p = touchLeft;
        touchLeft = touchRight;
        touchRight = p;
    }
    //    CGFloat center = (touchRight.x + touchLeft.x)/2.0;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            startRightTouch = touchRight;
            startLeftTouch = touchLeft;
            startStart = displayFirst;
            startCount = displayCount;
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded: {
            CGFloat sep = touchRight.x - touchLeft.x;
            float zoom = sep/(startRightTouch.x - startLeftTouch.x);
            //            NSLog(@"handleProcessedPinchGesture: @ %.0f zoom %.2f", center, zoom);
            displayCount = startCount/zoom;
            if (displayCount > audioClip.sampleCount)
                displayCount = audioClip.sampleCount;
            if (displayFirst + displayCount > audioClip.sampleCount)
                displayFirst = audioClip.sampleCount - displayCount;
            if (displayFirst < 0)
                displayFirst = 0;
            [self displayRangeFrom:displayFirst length:displayCount];
            break;
        }
        default:
            ;
    }
}

- (void) audioArrivedFromMike {
    [self displayRangeFrom:displayFirst length:displayCount];
}

- (void) spectrumChanged:(CGSize) newSize {
    //    NSData *spectrumData = [audioClip spectrumPixelDataForSize:spectrumViewSize];
    NSData *spectrumData = [audioClip spectrumPixelDataForSize:spectrumViewSize];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self->spectrumView displayPixels: spectrumData];
    });
}

- (IBAction)doPinchSpectrum:(UIPinchGestureRecognizer *)sender {
    if ([sender numberOfTouches] < 2)
        return;
}

- (IBAction)doTapSpectrum:(UITapGestureRecognizer *)sender {
    [self doMike:nil];
}

- (IBAction)doPanSpectrum:(UIPanGestureRecognizer *)sender {
    CGPoint touch = [sender locationOfTouch:0 inView:sender.view];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            startPanX = touch.x;
            startPan = displayFirst;
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded: {
            CGFloat samplesPerPixel = displayCount/waveView.graphWidth;
            CGFloat dx = startPanX - touch.x;
            displayFirst = startPan + dx*samplesPerPixel;
            if (displayFirst < 0)
                displayFirst = 0;
            if (displayFirst + displayCount > audioClip.sampleCount)
                displayFirst = audioClip.sampleCount - displayCount;
            [self displayRangeFrom:displayFirst length:displayCount];
            break;
        }
        default:
            ;
    }
}

- (void) mikeBufferFull {
    mikeButton.enabled = NO;
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [audioClip close];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
