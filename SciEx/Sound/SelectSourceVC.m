//
//  SelectSourceVC.m
//  SciEx
//
//  Created by ches on 3/17/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "SelectSourceVC.h"

@interface SelectSourceVC ()

@end

@implementation SelectSourceVC

@synthesize selectedSource;
@synthesize caller;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Select source";
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doDone:)];
    self.navigationItem.leftBarButtonItem = leftBarButton;

    self.clearsSelectionOnViewWillAppear = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sourceNames.count;
}

#define CellId  @"SelectSourceCell"

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellId];
    }
    if(indexPath.row == selectedSource) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.selected = YES;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selected = NO;
    }
    cell.textLabel.text = [sourceNames objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedSource = (SourceSelected)indexPath.row;
    [caller selectSource:selectedSource];
    [tableView reloadData];
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
