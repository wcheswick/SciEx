//
//  AppDelegate.h
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    UINavigationController *navController;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic)   UINavigationController *navController;


@end

