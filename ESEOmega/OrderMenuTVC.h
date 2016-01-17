//
//  OrderMenuTVC.h
//  ESEOmega
//
//  Created by Tomn on 01/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "OrderMenuCell.h"
#import "OrderElemTVC.h"
#import "OrderIngredTVC.h"
#import "SDWebImage/UIImageView+WebCache.h"

#define NBR_MAX_MENUS 2
#define NBR_MAX_PANIER 10

@interface OrderMenuTVC : UITableViewController
{
    NSArray *data;
    UIWindow *statut;
    UILabel *label;
    NSTimer *timerMessage;
    UIDeviceOrientation currentOrientation;
}

- (void) rotateInsets;
- (void) choseMenu:(NSDictionary *)menu;
- (void) chooseIngredientsFor:(NSDictionary *)element;
- (void) afficherMessage:(NSString *)nom;
- (void) afficherMessageNotif:(NSNotification *)notif;
- (void) masquerMessage;
- (void) majFrameMessage;

@end
