//
//  SelectSourceVC.h
//  SciEx
//
//  Created by ches on 3/17/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SoundDefines.h"

NS_ASSUME_NONNULL_BEGIN


@protocol SourceSelectProto <NSObject>

- (void) selectSource: (SourceSelected) src;

@end

@interface SelectSourceVC : UITableViewController <
    UITableViewDelegate,
    UITableViewDataSource> {
    SourceSelected selectedSource;
    __unsafe_unretained id<SourceSelectProto> caller;
}

@property (assign)  SourceSelected selectedSource;
@property (assign)  __unsafe_unretained id<SourceSelectProto> caller;


@end

NS_ASSUME_NONNULL_END
