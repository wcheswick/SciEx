//
//  VideoExhibitVC.h
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol VideoExhibitProto <NSObject>

//- (void) processImage:(u_char *)buffer w:(size_t)w h:(size_t)h;

@end

#import "ExhibitVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoExhibitVC : ExhibitVC
<AVCaptureVideoDataOutputSampleBufferDelegate> {
    __unsafe_unretained id<VideoExhibitProto> caller;
}

@property (assign)      id<VideoExhibitProto>caller;

- (BOOL) selectCamera:(AVCaptureDevicePosition) position;
- (void) setLiveFrameAndOrientation: (CGRect) frame;
- (void) startVideoCapture:(CGSize) capSize liveView:(nullable UIView *)liveView;
- (void) stopVideoCapture;


@end

NS_ASSUME_NONNULL_END
