//
//  EventsTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "EventAlertView.h"
#import "EventsHistoryTVC.h"
#import "UIScrollView+EmptyDataSet.h"
#import "CustomIOSAlertView.h"

@interface EventsTVC : UITableViewController <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, CustomIOSAlertViewDelegate, UIViewControllerPreviewingDelegate>
{
    NSArray *events;
    NSArray *eventsMonths;
    NSArray *boutons3DPop;
}

- (nullable NSString *) texteDetail:(nonnull NSIndexPath *)indexPath;
- (void) recupEvents:(BOOL)forcer;
- (void) loadEvents;
- (IBAction) refresh:(nullable UIRefreshControl *)sender;
- (void) scrollerMoisActuel;
- (nullable CustomIOSAlertView *) popUp:(nonnull NSIndexPath *)index;
- (nullable NSArray *) boutonsPopUp:(nonnull NSIndexPath *)index;
- (IBAction) commanderEvent:(nullable id)sender;

@end
