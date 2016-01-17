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

@interface NewsLinksVC : UITableViewController <MFMailComposeViewControllerDelegate, UIViewControllerPreviewingDelegate, SFSafariViewControllerDelegate>
{
    NSArray *titles, *links;
}

@end
