//
//  Pixel.h
//  SciEx
//
//  Created by William Cheswick on 2/6/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#ifndef Pixel_h
#define Pixel_h

#ifdef notdef

struct Pixel16 {        // #if BYTE_ORDER == LITTLE_ENDIAN
    u_short a:1;    /*alpha...not used */
    u_short b:5;
    u_short g:5;
    u_short r:5;
};

typedef struct Pixel24  Pixel24;
struct Pixel24 {
    u_char b,g,r;
};
#endif

typedef struct Pixel32  Pixel32;
struct Pixel32 {
    u_char b,g,r,a;
};

/* In these routines, we are using only the 32-bit pixels. */

typedef Pixel32 Pixel;
typedef u_char  channel;

#define Z   ((u_char)UINT8_MAX)
#define BYTES_PER_PIXEL sizeof(UInt32) // rgba

#define PIXEL(r,g,b)    SETRGB((r),(g),(b))

#define BLUE    PIXEL(0,0,Z)
#define GREEN   PIXEL(0,Z,0)
#define RED     PIXEL(Z,0,0)
#define WHITE   PIXEL(Z,Z,Z)
#define YELLOW  PIXEL(Z,Z,0)

#define SETRGB(r,g,b)   (Pixel){(b),(g),(r),Z}

#define Black           SETRGB(0,0,0)
#define Grey            SETRGB(Z/2,Z/2,Z/2)
#define LightGrey       SETRGB(2*Z/3,2*Z/3,2*Z/3)
#define White           SETRGB(Z,Z,Z)

#define LightBlue       SETRGB(0,Z/2,Z)
#define DarkBlue        SETRGB(0,0,Z/2)
#define Blue            SETRGB(0,0,Z)

#define Red             SETRGB(Z,0,0)
#define LightRed        SETRGB(Z, Z/2, Z/2)
#define Green           SETRGB(0,Z,0)
#define LightGreen      SETRGB(Z/2,Z,Z/2)
#define DarkGreen       SETRGB(0,Z/2,0)
#define Magenta         SETRGB(Z,0,Z)
#define LightMagenta    SETRGB(Z,Z/2,Z)
#define Cyan            SETRGB(0,Z,Z)

#define Yellow          SETRGB(Z,Z,0)
#define Orange          SETRGB(Z/2,Z,Z)

#define LUM(p)  ((((p).r)*299 + ((p).g)*587 + ((p).b)*114)/1000)

#define CLIP(c) ((c)<0 ? 0 : ((c)>Z ? Z : (c)))

#endif /* Pixel_h */
