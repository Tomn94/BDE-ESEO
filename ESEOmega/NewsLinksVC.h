//
//  NewsLinksVC.h
//  ESEOmega
//
//  Created by Tomn on 07/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;
@import MessageUI;
#import "Data.h"
#import "UIScrollView+EmptyDataSet.h"

#define SITE_BDE_TITLE @"Site BDE"
#define MAIL_BDE_TITLE @"Nous contacter"

@interface NewsLinksVC : UITableViewController <MFMailComposeViewControllerDelegate, UIViewControllerPreviewingDelegate, SFSafariViewControllerDelegate,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
{
    NSMutableArray *titles, *links, *imgs;
}

- (void) loadLinks;

@end
