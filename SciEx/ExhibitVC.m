//
//  ExhibitVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "ExhibitVC.h"

@interface ExhibitVC ()

@end

@implementation ExhibitVC

@synthesize exhibitTitle, exhibitDescription;
@synthesize exhibitAvailable;


- (id)init {
    self = [super init];
    if (self) {
        exhibitAvailable = NO;     // default is not ready yet
        exhibitDescription = nil;
        exhibitTitle = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!exhibitTitle)
        exhibitTitle = @"XXX your title here";
    if (!exhibitDescription)
        exhibitDescription = @"XXX your description here";
}

@end
