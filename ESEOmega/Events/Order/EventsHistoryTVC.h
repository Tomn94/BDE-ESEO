//
//  EventsHistoryTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 11/01/2016.
//  Copyright © 2016 Thomas Naudet

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
