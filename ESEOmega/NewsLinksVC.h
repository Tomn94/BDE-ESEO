//
//  NewsLinksVC.h
//  ESEOmega
//
//  Created by Thomas NAUDET on 07/08/2015.
//  Copyright © 2015 Thomas NAUDET

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
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
