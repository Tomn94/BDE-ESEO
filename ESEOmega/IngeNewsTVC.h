//
//  IngeNewsTVC.h
//  ESEOmega
//
//  Created by Tomn on 22/12/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;
@import CoreText;
@import SafariServices;
#import "Data.h"
#import "UIScrollView+EmptyDataSet.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface IngeNewsCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *titreLabel;
@property (weak, nonatomic) IBOutlet UILabel *sousLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconeView;

@end

@interface IngeNewsCVC : UICollectionViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, SFSafariViewControllerDelegate,UIGestureRecognizerDelegate,UIViewControllerPreviewingDelegate,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
{
    NSArray *fichiers;
    UIRefreshControl *refreshControl;
    BOOL messageLu;
}

- (IBAction) fermer:(id)sender;
- (void) refresh:(id)sender;
- (void) loadFichiers;

@end

@interface IngeNewsTVC : UITableViewController  <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, SFSafariViewControllerDelegate>
{
    NSArray *fichiers;
}

- (IBAction) fermer:(id)sender;
- (IBAction) refresh:(id)sender;
- (void) loadFichiers;

@end