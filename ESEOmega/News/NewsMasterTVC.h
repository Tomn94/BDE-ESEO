//
//  NewsMasterTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
//  Copyright © 2015 Thomas Naudet

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
#import "Data.h"
#import "NewsLinksVC.h"
#import "NewsDetailVC.h"
#import "NewsSelectionDelegate.h"
#import "UIScrollView+EmptyDataSet.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "UIScrollView+BottomRefreshControl.h"

@interface NewsMasterTVC : UITableViewController <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIToolbarDelegate, UIPopoverPresentationControllerDelegate, UIViewControllerPreviewingDelegate, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate>
{
    UINavigationController *detailNVC;
    NSArray *news;
    UIBarButtonItem *eseomegaBarItem;
    BOOL popoverVisible;
    NSInteger ptr;
    UIToolbar *toolbar;
}

@property (nonatomic, weak) UIViewController<NewsSelectionDelegate> *__nullable delegate;

- (void) recupNews:(BOOL)forcer;
- (void) loadNews;
- (void) openWithInfos:(nullable NSDictionary *)infosNews;
- (IBAction) refresh:(nullable UIRefreshControl *)sender;
- (void) loadMore;
- (void) hasLoadedMore;
- (void) debugRefresh;

- (void) setUpToolbar;
- (void) portail;
- (void) campus;
- (void) mails;
- (void) eseo;
- (void) dreamspark;
- (void) eseomega;

- (IBAction) salles:(nullable id)sender;
- (IBAction) ingenews:(nullable id)sender;

@end
