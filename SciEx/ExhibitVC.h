//
//  ExhibitVC.h
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExhibitVC : UIViewController {
    NSString *exhibitTitle;
    NSString *exhibitDescription;
    BOOL exhibitAvailable;
}

@property (nonatomic, strong)   NSString *exhibitTitle;
@property (nonatomic, strong)   NSString *exhibitDescription;
@property (assign)              BOOL exhibitAvailable;

@end
