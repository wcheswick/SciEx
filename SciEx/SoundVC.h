//
//  SoundVC.h
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExhibitVC.h"
#import "AudioClip.h"
#import "AudioDefines.h"
#import "SelectSourceVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface SoundVC : ExhibitVC <
    UITableViewDelegate,
    UITableViewDataSource,
UIPopoverPresentationControllerDelegate,
    MikeProtocol, SourceSelectProto>

@end

NS_ASSUME_NONNULL_END
