//
//  SallesTVC.h
//  ESEOmega
//
//  Created by Tomn on 28/11/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;
@import CoreText;
#import "Data.h"
#import "JTSImageInfo.h"
#import "JTSImageViewController.h"
#import "UIScrollView+EmptyDataSet.h"

@interface SallesTVC : UITableViewController <UISearchResultsUpdating,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate,UISearchBarDelegate>
{
    NSArray *salles;
    NSMutableArray *filtre;
    UISearchController *search;
}

- (IBAction) fermer:(id)sender;
- (IBAction) refresh:(id)sender;
- (void) loadSalles;
- (IBAction) afficherPlans:(id)sender;

@end
