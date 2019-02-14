//
//  MainVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "MainVC.h"
#import "ExhibitVC.h"
#import "SoundVC.h"
#import "ColorBlindVC.h"
#import "LotteryVC.h"
#import "DDVC.h"
#import "ChatVC.h"
#import "Defines.h"

@interface MainVC ()

@property (nonatomic, strong)   UICollectionView *collectionView;
@property (nonatomic, strong)   UICollectionViewFlowLayout *layout;

@property (nonatomic, strong)   ExhibitVC *exhibitVC;

@property (nonatomic, strong)   NSArray *exhibitList;

@end

@implementation MainVC

static NSString * const reuseIdentifier = @"Cell";

@synthesize collectionView, layout;
@synthesize exhibitVC;

@synthesize exhibitList;


- (id)init {
    self = [super init];
    if (self) {
        exhibitList = [[NSArray alloc] initWithObjects:
                       [[SoundVC alloc] init],
                       [[ColorBlindVC alloc] init],
                       [[LotteryVC alloc] init],
                       [[DDVC alloc] init],
                       [[ChatVC alloc] init],
                       nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Science exhibits";
    
//    self.navigationController.navigationBar.hidden = YES;
//    self.navigationController.toolbarHidden = YES;

    layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(INSET, INSET, INSET, INSET);
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    
    collectionView = [[UICollectionView alloc]
                      initWithFrame:self.view.frame
                      collectionViewLayout:layout];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [collectionView registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:reuseIdentifier];
    collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:collectionView];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return exhibitList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    ExhibitVC *exhibitView = (ExhibitVC *)[exhibitList objectAtIndex:indexPath.row];
    UILabel *label = [[UILabel alloc]
                      initWithFrame:CGRectMake(0, 0,
                                               cell.frame.size.width,
                                               cell.frame.size.height)];
    label.text = exhibitView.exhibitTitle;
    label.textColor = [UIColor blueColor];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:20];
    label.layer.borderWidth = 0.5;
    label.layer.borderColor = [UIColor blackColor].CGColor;
    label.layer.cornerRadius = 10.0;
    label.enabled = exhibitView.exhibitAvailable;
    [cell addSubview:label];
    
    if (!exhibitView.exhibitAvailable) {
        cell.userInteractionEnabled = NO;
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(200, 100);
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ExhibitVC *exhibitView = (ExhibitVC *)[exhibitList objectAtIndex:indexPath.row];
    NSLog(@"selected item %ld, '%@'", (long)indexPath.row, exhibitView.exhibitTitle);
    [self.navigationController
     pushViewController:exhibitView
     animated: YES];
}

@end
