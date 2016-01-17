//
//  OrderPanierTVC.h
//  ESEOmega
//
//  Created by Tomn on 01/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;
@import LocalAuthentication;
#import "Data.h"
#import "OrderItemCell.h"
#import "OrderConfirmCell.h"
#import "UIScrollView+EmptyDataSet.h"

@interface OrderPanierTVC : UITableViewController <DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UITextFieldDelegate>
{
    BOOL cmdEnCours;
    NSString *txtInstructions;
}

- (void) rotateInsets;
+ (NSDictionary *) dataForIDStr:(NSDictionary *)d;
- (double) getTotalPrice;
- (void) lancerCommande;
- (void) sendPanier;

@end
