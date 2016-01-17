//
//  CreditsTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 29/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "UIScrollView+EmptyDataSet.h"

@interface CreditsTVC : UITableViewController <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

- (void) fermer;

@end
