//
//  EventOrderNavTVC.h
//  ESEOmega
//
//  Created by Tomn on 11/01/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;

#import "Data.h"

@interface EventsOrderNavTVC : UITableViewController
{
    NSArray *navettes;
    NSDictionary *selectionNavette;
}

@property (strong, nonatomic) NSDictionary *data;


- (instancetype) initWithStyle:(UITableViewStyle)style andData:(NSDictionary *)data;
- (void) valider;

@end
