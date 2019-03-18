//
//  SoundVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

//     AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithData:clipData error:&error]

#import "Defines.h"
#import "SoundDefines.h"
#import "OrderedDictionary.h"
#import "SoundVC.h"
#import "AudioClip.h"
#import "WaveView.h"
#import "SpectrumView.h"
#import "SpectrumGridView.h"
#import "SpectrumOptions.h"
#import "XAxisView.h"

// keys used by dictionaries in soundClipSections:

#define kFileName   @"FileName"
#define kDescription    @"Description"

#define kLastClipChosen   @"LastClipChosen"

NSArray *sourceNames;

@interface SoundVC ()

@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UIView *playControlView;
@property (nonatomic, strong)   UITableView *sampleTableView;
@property (nonatomic, strong)   UIView *controlsView;
@property (nonatomic, strong)   UIButton *mikeButton;
@property (nonatomic, strong)   UISegmentedControl *selectInput;
@property (nonatomic, strong)   SpectrumView *spectrumView;
@property (nonatomic, strong)   SpectrumGridView *spectrumGridView;
@property (assign)              CGSize spectrumViewSize;

@property (nonatomic, strong)   UIButton *monitorButton;
@property (nonatomic, strong)   UIBarButtonItem *runButton;
@property (nonatomic, strong)   UISegmentedControl *srcTypeSelect;
@property (nonatomic, strong)   UIBarButtonItem *srcButton;

@property (nonatomic, strong)   WaveView *waveView;
@property (assign)              size_t waveSamplesPerPixel;
@property (assign)              size_t pinchWaveStartSamplesPerPixel;
@property (nonatomic, strong)   XAxisView *xAxisView;

@property (nonatomic, strong)   OrderedDictionary *soundClipSections;
@property (assign)              BOOL AGC;

@property (nonatomic, strong)   UITableView *selectSourceTable;
@property (assign)              SourceSelected currentSource;

@property (assign)              BOOL running, monitor;
@property (nonatomic, strong)   AudioClip *audioClip;
@property (nonatomic, strong)   NSString *currentClipFile;

@property (assign)              long displayFirst, displayCount;

@property (assign)              long graphStart, graphCount;

// for pinch processing

@property (assign)              CGPoint startTouch0, startTouch1;
@property (assign)              long startStart, startCount, startPan;
@property (assign)              CGFloat startPanX;

@property (nonatomic, strong)   SpectrumOptions *spectrumOptions, *gestureStartSpectrumOptions;

@end

@implementation SoundVC

@synthesize containerView;
@synthesize playControlView;
@synthesize sampleTableView;
@synthesize controlsView, selectInput;
@synthesize mikeButton;
@synthesize spectrumView, spectrumGridView;
@synthesize spectrumViewSize;
@synthesize waveView;
@synthesize waveSamplesPerPixel, pinchWaveStartSamplesPerPixel;
@synthesize xAxisView;

@synthesize runButton, monitorButton, srcButton;
@synthesize srcTypeSelect;
@synthesize selectSourceTable;
@synthesize currentSource;

@synthesize soundClipSections;
@synthesize currentClipFile;

@synthesize AGC, running, monitor;

@synthesize audioClip;

@synthesize displayFirst, displayCount;
@synthesize startTouch0, startTouch1;
@synthesize startStart, startCount, startPan, startPanX;
@synthesize spectrumOptions, gestureStartSpectrumOptions;

- (id)init {
    self = [super init];
    if (self) {
        exhibitTitle = @"What does sound look like?";
        exhibitAvailable = YES;
        soundClipSections = [[OrderedDictionary alloc] init];
        sourceNames = [NSArray arrayWithObjects:SRC_NAMES_OBJS, nil];
        AGC = NO;
        running = NO;
        monitor = NO;
        displayFirst = 0;
        displayCount = 0;
        waveSamplesPerPixel = 1; // 3;
        audioClip = nil;
        currentClipFile = nil;
        currentSource = MikeSelected;
        spectrumOptions = [[SpectrumOptions alloc] init];
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

#define PLAY_CTL_W  50

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.toolbarHidden = NO;
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doDone:)];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor whiteColor];
    
    playControlView = [[UIView alloc]
                       initWithFrame:CGRectMake(LATER, 0, PLAY_CTL_W, LATER)];
    
    [containerView addSubview:playControlView];
    
    spectrumView = [[SpectrumView alloc]
                    initWithFrame:CGRectMake(0, 0, LATER, FFT_H)];
    spectrumView.backgroundColor = [UIColor blackColor];
    spectrumView.userInteractionEnabled = YES;
    
    spectrumGridView = [[SpectrumGridView alloc]
                        initWithFrame:spectrumView.frame];
    spectrumGridView.opaque = NO;
    [spectrumView addSubview:spectrumGridView];
    
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
    
    UIImage *hearImage = [UIImage
                          imageWithContentsOfFile:[[NSBundle mainBundle]
                                                   pathForResource:@"ear" ofType:@"png"]];
    UIImage *noHearImage = [UIImage
                            imageWithContentsOfFile:[[NSBundle mainBundle]
                                                     pathForResource:@"noEar" ofType:@"png"]];
    CGFloat h = self.navigationController.toolbar.frame.size.height;
    
    monitorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat aspect = hearImage.size.width / hearImage.size.height;
    monitorButton.frame = CGRectMake(0, 0, h*aspect, h);
    monitorButton.autoresizingMask = UIViewAutoresizingNone;
//    monitorButton.contentMode = UIViewContentModeCenter;
    [monitorButton setImage:hearImage forState:UIControlStateNormal];
    [monitorButton setImage:noHearImage forState:UIControlStateSelected];
    
    [monitorButton addTarget:self action:@selector(doToggleHear:)
            forControlEvents:UIControlEventTouchUpInside];
    [monitorButton addTarget:self action:@selector(doToggleHear:)
            forControlEvents:UIControlEventTouchUpInside];
    monitorButton.backgroundColor = [UIColor greenColor];

    static struct iconList {
        char *file;
        SourceSelected source;
    } iconList[] = {
        {"mike", MikeSelected},
        {"sine", GeneratorSelected},
        {"files", UserFileSelected},
        {"eagle", SampleFileSelected},
        {0, 0}
    };
    
    srcTypeSelect = [[UISegmentedControl alloc] init];
    for (size_t i=0; iconList[i].file; i++) {
        NSString *file = [NSString stringWithUTF8String:iconList[i].file];
        UIImage *image = [UIImage
                              imageWithContentsOfFile:[[NSBundle mainBundle]
                                                       pathForResource:file ofType:@"png"]];
        [srcTypeSelect insertSegmentWithImage:
         [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                      atIndex:i animated:NO];
        [srcTypeSelect setWidth:60 forSegmentAtIndex:i];
    }
    [srcTypeSelect addTarget:self
                     action:@selector(newSourceType:)
           forControlEvents:UIControlEventValueChanged];
    srcTypeSelect.selectedSegmentIndex = MikeSelected;
    srcTypeSelect.tintColor = [UIColor whiteColor];
    
    srcButton = [[UIBarButtonItem alloc]
                 initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                 target:self
                 action:@selector(goSelectSource:)];

    
    [self selectSource: MikeSelected];
    
    selectSourceTable = [[UITableView alloc] init];
    
    
    controlsView = [[UIView alloc]
                    initWithFrame:CGRectMake(0, BELOW(xAxisView.frame),
                                             LATER, CONTROLS_H)];
    controlsView.layer.borderWidth = 1;
    controlsView.layer.borderColor = [UIColor greenColor].CGColor;
    
    [self adjustPlayControlBar];
    
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
    
    audioClip = [[AudioClip alloc] init];
    selectInput.enabled = NO;
    switch (currentSource) {
        case MikeSelected:
            [waveView useClip:audioClip];
            xAxisView.audioClip = audioClip;
            break;
        case SampleFileSelected:
            NSLog(@"SampleFileSelected");
            break;
        case UserFileSelected:
            NSLog(@"UserFileSelected");
            break;
        case GeneratorSelected:
            NSLog(@"GeneratorSelected");
            break;
    }
}

- (IBAction)goSelectSource:(UIBarButtonItem *)sender {
    SelectSourceVC *ssVC = [[SelectSourceVC alloc] init];
    ssVC.view.frame = CGRectMake(0, 0, 100, 44*4 + 40);
    ssVC.caller = self;
    ssVC.selectedSource = currentSource;
    UINavigationController *nav = [[UINavigationController alloc]
                                   initWithRootViewController:ssVC];
    nav.modalPresentationStyle = UIModalPresentationPopover;
    nav.preferredContentSize = CGSizeMake(100, 44*4 + 40);
    CGRect f = nav.view.frame;
    f.size = nav.preferredContentSize;
    nav.view.frame = f;
    
    UIPopoverPresentationController *popvc = nav.popoverPresentationController;
    popvc.sourceRect = CGRectMake(100, 100, 100, 100);
    popvc.delegate = self;
    popvc.sourceView = ssVC.view;
    popvc.barButtonItem = sender;
    [self presentViewController:nav animated:YES completion:nil];

}

- (void) selectSource: (SourceSelected) src {
    currentSource = src;
    srcButton.title = [sourceNames objectAtIndex:currentSource];
}

- (void) selectClip:(NSString *)clipFile {
    NSString *err = [audioClip initializeFromPath:currentClipFile];
    if (err) {
        NSLog(@"path source initialization error %@", err);
    }
    [waveView useClip:audioClip];
    xAxisView.audioClip = audioClip;
    [[NSUserDefaults standardUserDefaults] setObject:clipFile forKey:kLastClipChosen];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) adjustPlayControlBar {
    UIBarButtonItem *flexiableItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    [self runAudio:running];

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

    UIBarButtonItem *monitorBarButton = [[UIBarButtonItem alloc]
                                         initWithCustomView:monitorButton];
    monitorBarButton.image = monitorButton.imageView.image;
    
    UIBarButtonItem *negativeSeparator = [[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSeparator.width = -12;
    
    UIBarButtonItem *srcSelectBarButton = [[UIBarButtonItem alloc] initWithCustomView:srcTypeSelect];

    NSArray *toolbarItems = [NSArray arrayWithObjects:
                             flexiableItem,
                             runButton, flexiableItem,
                             AGCBarButton, flexiableItem,
                             monitorBarButton, flexiableItem,
                             srcSelectBarButton,
                             nil];
    [self setToolbarItems: toolbarItems];
}


- (IBAction)doToggleRun:(UIButton *)b {
    [self runAudio:!running];
}

- (void) runAudio:(BOOL) run {
    running = run;
    if (running) {
        switch (currentSource) {
            case MikeSelected:
                [audioClip startMike];
                break;
            default:
                ;
        }
        runButton = [[UIBarButtonItem alloc]
                     initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                     target:self
                     action:@selector(doToggleRun:)];
    } else {
        switch (currentSource) {
            case MikeSelected:
                [audioClip stopMike];
                break;
            default:
                ;
        }
        runButton = [[UIBarButtonItem alloc]
                     initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                     target:self
                     action:@selector(doToggleRun:)];
    }
}

- (void) viewWillTransitionToSize:(CGSize)size
        withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    NSLog(@"***** transitition ***");
    [self layoutViewsToSize:size];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self layoutViewsToSize:self.view.frame.size];
}

- (void) layoutViewsToSize:(CGSize) newSize {
    CGRect f = self.view.frame;
    f.size = newSize;
//    self.view.frame = f;
    
    containerView.frame = f;
    SET_VIEW_Y(containerView, BELOW(self.navigationController.navigationBar.frame));
    SET_VIEW_HEIGHT(containerView, containerView.frame.size.height - containerView.frame.origin.y);
    containerView.frame = CGRectInset(containerView.frame, INSET, INSET);
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.opaque = YES;
    
    SET_VIEW_WIDTH(spectrumView, containerView.frame.size.width);
    spectrumViewSize = spectrumView.frame.size;   // size not needing the mail thread
    spectrumGridView.frame = spectrumView.frame;
    SET_VIEW_WIDTH(waveView, containerView.frame.size.width);
    SET_VIEW_WIDTH(xAxisView, containerView.frame.size.width);
    SET_VIEW_WIDTH(controlsView, containerView.frame.size.width);
    SET_VIEW_WIDTH(sampleTableView, containerView.frame.size.width);
    [sampleTableView reloadData];
    [selectInput setNeedsDisplay];
    
    displayCount = 5*audioClip.sampleRate;

    [waveView setNeedsLayout];
//    [self newSource:selectInput];
}

- (IBAction)newSourceType:(UISegmentedControl *)sender {
    NSLog(@"selected input %ld", (long)sender.selectedSegmentIndex);
    if (sender.selectedSegmentIndex == MikeSelected) {
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
        mikeButton.enabled = NO;
        sampleTableView.userInteractionEnabled = YES;
    }
}

- (IBAction)doToggleHear:(UIButton *)b {
    monitorButton.selected = !monitorButton.selected;
    [monitorButton setNeedsDisplay];
}

- (IBAction)doAGC:(UIButton *)b {
    AGC = b.selected = !b.selected;
    NSLog(@"AGC is now %@", AGC ? @"ON" : @"OFF");
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
    NSString *clipFile = [sample objectForKey:kFileName];
    NSLog(@"selected sample file %@", [sample objectForKey:kFileName]);
    [self selectClip:clipFile];
    
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
}


- (void) audioArrivedFromMike {
    displayFirst = audioClip.sampleCount - waveView.graphWidth*waveSamplesPerPixel;
    if (displayFirst < 0)
        displayFirst = 0;
    [self displayWaveFrom:displayFirst];
}

- (void) displayWaveFrom:(size_t)first {
    [waveView showRangeFrom:first spp:waveSamplesPerPixel];
//    dispatch_async(dispatch_get_main_queue(), ^(void) {
//        [self->xAxisView range:self->displayFirst at:self->waveSamplesPerPixel];
//    });
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
            [self displayWaveFrom:displayFirst];
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
            if (touchRight.x == touchLeft.x)
                touchRight.x = touchLeft.x + 1; // no div by zero
            startTouch0 = touchLeft;
            startTouch1 = touchRight;
            pinchWaveStartSamplesPerPixel = waveSamplesPerPixel;
            startStart = displayFirst;
            startCount = displayCount;
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded: {
            CGFloat sep = touchRight.x - touchLeft.x;
            if (sep == 0)
                sep = 1;
            waveSamplesPerPixel = pinchWaveStartSamplesPerPixel/(startTouch1.x - startTouch0.x);
            [self displayWaveFrom:displayFirst];
            break;
        }
        default:
            ;
    }
}

- (void) spectrumChanged {
    int leftBlock = audioClip.blockCount - spectrumViewSize.width/spectrumOptions.pixelsPerBlock;
    if (leftBlock < 0)
        leftBlock = 0;
    int startX;
    NSData *spectrumData = [audioClip spectrumPixelDataForSize:spectrumViewSize
                                                       options:spectrumOptions
                                                     leftBlock:leftBlock
                                                        startX:&startX];
    float timePerBlock = (float)FFT_LEN/(float)audioClip.sampleRate;
    float startTime = leftBlock * timePerBlock;
    float endTime = (spectrumViewSize.width - startX)*timePerBlock;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self->spectrumGridView gridSettings:self->spectrumOptions
                                   startTime:startTime endTime:endTime
                                      startX:startX];
        [self->spectrumView displayPixels: spectrumData];
    });
}

- (IBAction)doPinchSpectrum:(UIPinchGestureRecognizer *)sender {
    if ([sender numberOfTouches] < 2)
        return;
    CGPoint touch0 = [sender locationOfTouch:0 inView:sender.view];
    CGPoint touch1 = [sender locationOfTouch:1 inView:sender.view];
    //    CGFloat center = (touchRight.x + touchLeft.x)/2.0;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            startTouch0 = touch0;
            startTouch1 = touch1;
            gestureStartSpectrumOptions = spectrumOptions;
            startStart = displayFirst;
            startCount = displayCount;
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded: {
            return;     // broken, disabled
            float startDY = fabs(startTouch0.y - startTouch1.y);
            float startDX = fabs(startTouch0.x - startTouch1.x);
            float dx = fabs(touch0.x - touch1.x);
            float dy = fabs(touch0.y - touch1.y);
            float zoomX = dx/startDX;
            assert(zoomX >= 0);
            float zoomY = dy/startDY;
            NSLog(@"  %.1f %.1f   %.1f %.1f", dx, zoomX, dy, zoomY);
            size_t newPixelsPerBlock = floor((float)gestureStartSpectrumOptions.pixelsPerBlock * zoomX);
            if (newPixelsPerBlock >= 1 && newPixelsPerBlock != spectrumOptions.pixelsPerBlock) {
                NSLog(@"ppb: %ld -> %zu", (long)spectrumOptions.pixelsPerBlock, newPixelsPerBlock);
                spectrumOptions.pixelsPerBlock = newPixelsPerBlock;
                break;
            }
        default:
            ;
        }
    }
}

- (IBAction)doTapSpectrum:(UITapGestureRecognizer *)sender {
    [self runAudio:!running];
}

- (IBAction)doPanSpectrum:(UIPanGestureRecognizer *)sender {
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
            [self displayWaveFrom:displayFirst];
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
