//
//  ColorBlindVC.h
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoExhibitVC.h"

@interface ColorBlindVC : VideoExhibitVC
    <VideoExhibitProto,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout>

@end
