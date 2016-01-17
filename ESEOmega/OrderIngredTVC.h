//
//  OrderDetailTVC.h
//  ESEOmega
//
//  Created by Tomn on 21/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;
#import "Data.h"

@interface OrderIngredTVC : UITableViewController
{
    NSArray *ingredients;
    NSMutableArray *selection;
    UILabel *text;
}

@property (weak, nonatomic) NSDictionary *data;
@property (nonatomic) NSInteger menu;

- (instancetype) initWithStyle:(UITableViewStyle)style andMenu:(NSInteger)menu;
- (double) supplement;
- (void) updSupplement;
- (void) sendNotif;
- (void) preselect:(NSArray *)ingr;
- (void) valider;

@end
