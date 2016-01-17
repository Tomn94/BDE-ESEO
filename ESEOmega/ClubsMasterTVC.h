//
//  ClubsMasterTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "UIScrollView+EmptyDataSet.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "Data.h"
#import "ClubsSelectionDelegate.h"
#import "ClubsMasterCell.h"
#import "ClubsDetailTVC.h"

@interface ClubsMasterTVC : UITableViewController <DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UIViewControllerPreviewingDelegate, MFMailComposeViewControllerDelegate>
{
    UINavigationController *detailNVC;
    NSArray *clubs;
}

@property (nonatomic, weak) UIViewController<ClubsSelectionDelegate> *__nullable delegate;

- (void) recupClubs:(BOOL)forcer;
- (void) loadClubs;
- (void) scrollViewDidScroll:(nullable UIScrollView *)scrollView;
- (IBAction) refresh:(nullable UIRefreshControl *)sender;

@end
