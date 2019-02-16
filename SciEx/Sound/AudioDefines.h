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


#define DEFAULT_SAMPLE_RATE     44100
#define DEFAULT_SAMPLE_TYPE     short
#define RAW_SAMPLE_TYPE         short

typedef short Sample;

#define SAMPLES_TO_MS(s)    (1000.0*(((float)s)/(float)DEFAULT_SAMPLE_RATE))

#define MAX_SAMPLES     (2000*DEFAULT_SAMPLE_RATE)  // more than half an hour, about 80MB

#define SAMPLE_MEM_INCR (10*DEFAULT_SAMPLE_RATE) // more mem every ten seconds

extern  Sample *samples;
extern  size_t samples_alloc;
extern  size_t samples_count;

#endif /* AudioDefines_h */
