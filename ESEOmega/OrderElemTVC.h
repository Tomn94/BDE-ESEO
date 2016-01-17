//
//  OrderElemTVC.h
//  ESEOmega
//
//  Created by Tomn on 21/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "OrderIngredTVC.h"
#import "OrderPanierTVC.h"

@interface OrderElemTVC : UITableViewController
{
    NSArray *sandwiches;
    NSArray *elements;
    NSMutableArray *selectionSandwiches;
    NSMutableArray *selectionElements;
    UILabel *text;
}

@property (weak, nonatomic) NSDictionary *data;

- (instancetype) initWithStyle:(UITableViewStyle)style andData:(NSDictionary *)data;
- (void) newSandw:(NSNotification *)notif;
- (double) supplementSand:(NSDictionary *)sandwich;
- (double) supplement;
- (void) updSupplement;
- (void) sendNotif;
- (void) valider;

@end
