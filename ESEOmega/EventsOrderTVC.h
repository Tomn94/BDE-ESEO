//
//  EventsOrderTVC.h
//  ESEOmega
//
//  Created by Tomn on 11/01/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;
@import LocalAuthentication;

#import "Data.h"
#import "OrderMenuCell.h"
#import "EventsOrderNavTVC.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface EventsOrderTVC : UITableViewController
{
    BOOL messageQuitterVu;
    NSArray *dataEvents;
    NSArray *dataEventsTickets;
    NSArray *dataShuttles;
}

- (IBAction) fermer:(id)sender;
- (void) chooseShuttleFor:(NSDictionary *)ticket;
- (void) validerAchat:(NSDictionary *)achat;
- (void) validerAchatN:(NSNotification *)notif;
- (void) sendAchat:(NSDictionary *)achat;

@end
