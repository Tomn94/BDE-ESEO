//
//  OrderMenuTVC.h
//  ESEOmega
//
//  Created by Thomas NAUDET on 01/08/2015.
//  Copyright © 2015 Thomas NAUDET

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
#import "OrderMenuCell.h"
#import "OrderElemTVC.h"
#import "OrderIngredTVC.h"
#import "../../SDWebImage/UIImageView+WebCache.h"

#define NBR_MAX_MENUS 2
#define NBR_MAX_PANIER 10

@interface OrderMenuTVC : UITableViewController <CAAnimationDelegate>
{
    NSArray *data;
    UIView  *statut;
    UILabel *label;
    NSTimer *timerMessage;
}

@property (nonatomic, weak) UIView *pvcHolder;

- (void) rotateInsets;
- (void) choseMenu:(NSDictionary *)menu;
- (void) chooseIngredientsFor:(NSDictionary *)element;
- (void) afficherMessage:(NSString *)nom;
- (void) afficherMessageNotif:(NSNotification *)notif;
- (void) masquerMessage;
- (void) majFrameMessage;

@end
