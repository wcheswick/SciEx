//
//  cb.h
//  SciEx
//
//  Created by William Cheswick on 2/6/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#ifndef cb_h
#define cb_h

#import "Pixel.h"

typedef enum {
    PROTANOPIA,
    DEUTERANOPIA,
    TRITANOPIA
} ColorblindDeficiency;

typedef struct colorDeficits {
    char *name;
    char *description;
} colorDeficits;

extern  Pixel to_colorblind(int r, int g, int b);
extern  Pixel livePixelToColorBlind(const Pixel *p);
extern  void init_colorblind(ColorblindDeficiency);
extern  void end_colorblind(void);

extern colorDeficits deficits[];

#endif /* cb_h */
