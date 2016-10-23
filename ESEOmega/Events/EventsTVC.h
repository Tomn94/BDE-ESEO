//
//  EventsTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
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
#import "EventAlertView.h"
#import "EventsHistoryTVC.h"
#import "UIScrollView+EmptyDataSet.h"
#import "CustomIOSAlertView.h"

#define JSON_DATE_FORMAT @"yyyy-MM-dd'T'HH:mm:ss.S'Z'"

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
