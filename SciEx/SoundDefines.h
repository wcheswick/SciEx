//
//  SoundDefines.h
//  SciEx
//
//  Created by ches on 3/17/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#ifndef SoundDefines_h
#define SoundDefines_h


typedef enum {
    MikeSelected,
    GeneratorSelected,
    UserFileSelected,
    SampleFileSelected,
} SourceSelected;

#define SRC_NAMES_OBJS   @"Mike", @"Gen", @"Files", @"Samples", nil

extern NSArray *sourceNames;

#endif /* SoundDefines_h */
