//
//  SponsorsTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "SponsorsCell.h"
#import "CreditsTVC.h"
#import "UIScrollView+EmptyDataSet.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface SponsorsTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UIViewControllerPreviewingDelegate, SFSafariViewControllerDelegate>
{
    NSArray *sponsors;
}

- (void) recupSponsors:(BOOL)forcer;
- (void) loadSponsors;
- (IBAction) refresh:(nullable UIRefreshControl *)sender;
- (void) credits;

@end
