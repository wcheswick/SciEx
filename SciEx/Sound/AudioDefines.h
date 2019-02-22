//
//  AudioDefines.h
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#ifndef AudioDefines_h
#define AudioDefines_h

#define kLastSource         @"LastSource"
#define kLastMAms           @"LastMAms"

#define DEFAULT_SAMPLE_RATE     44100
#define DEFAULT_SAMPLE_TYPE     short
#define RAW_SAMPLE_TYPE         short
#define MAX_MIKE_LEN        (DEFAULT_SAMPLE_RATE*60*5)  // five minutes

#define RAW_SAMPLE_MIN  INT16_MIN
#define RAW_SAMPLE_MAX  INT16_MAX

typedef DEFAULT_SAMPLE_TYPE Sample;
#define SAMPLE_TO_BYTE(s)   ((s)*sizeof(Sample))
#define BYTE_TO_SAMPLE(b)   ((b)/sizeof(Sample))


#define SpectrumPixel   uint8_t    // 0-255, use a colormap to color

#define SPECTRUM_MAX_PIXEL  ((1<<(sizeof(SpectrumPixel)*8)) - 1)

// main screen stuff

#define COUNTER_H   44  // same as toolbars
#define COUNTER_FONT_SIZE   42

#define BUTTON_FONT_SIZE    18
#define CONTROL_FONT_SIZE   24

// analyze screen stuff

#define BIG_TICK    10
#define SMALL_TICK  4

#define Y_LABEL_H     12
#define LABEL_H_SLOP    0   // fontsize = Label_H - slop


#define VSEP    20
#define HSEP    13

#define AMP_H   200

#define MA_GRAPH_H      100
#define PR_GRAPH_H      100

#define isIPhone (![[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] || [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)

#endif /* AudioDefines_h */
