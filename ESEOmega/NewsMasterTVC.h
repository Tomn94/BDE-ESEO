//
//  NewsMasterTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
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
- (void) projets;
- (void) eseomega;

- (IBAction) salles:(nullable id)sender;
- (IBAction) ingenews:(nullable id)sender;

@end
