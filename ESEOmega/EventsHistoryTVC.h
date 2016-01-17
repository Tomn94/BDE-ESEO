//
//  EventsHistoryTVC.h
//  ESEOmega
//
//  Created by Tomn on 11/01/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;

#import "Data.h"
#import "EventsHistoryCell.h"
#import "UIScrollView+EmptyDataSet.h"

@interface EventsHistoryTVC : UITableViewController <DZNEmptyDataSetDelegate, DZNEmptyDataSetSource>
{
    NSArray *cmd;
    NSTimer *upd;
    NSInteger nbrUpd;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *__nullable ajoutBtn;

- (IBAction) fermer:(nullable id)sender;
- (IBAction) reserver:(nullable id)sender;
- (void) verifsCommande;
- (void) majTimerRecup;
- (void) loadEventsCmds;
- (IBAction) refresh:(nullable UIRefreshControl *)sender;
- (void) recupCommandes:(BOOL)forcer;
- (void) commandeValidee:(nonnull NSNotification *)n;

@end
