//
//  ChatVC.m
//  SciEx
//
//  Created by William Cheswick on 2/7/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "ChatVC.h"
#import "Defines.h"

@interface ChatVC ()

@end

@implementation ChatVC


- (id)init {
    self = [super init];
    if (self) {
        exhibitTitle = @"The Chatanooga Children's discovery portrait style station";
        exhibitAvailable = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBarHidden = NO;
    //    self.navigationController.navigationBar.opaque = YES;
    self.navigationController.toolbarHidden = YES;
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doDone:)];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    SET_VIEW_Y(self.view, BELOW(self.navigationController.navigationBar.frame));
    SET_VIEW_HEIGHT(self.view, self.view.frame.size.height - self.view.frame.origin.y);
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.opaque = YES;
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void) processImage:(u_char *)buffer w:(size_t)w h:(size_t)h {
    //    NSLog(@"process %zu %zu", w, h);
}

@end
