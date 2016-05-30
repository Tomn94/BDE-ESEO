//
//  CommandesTVC.h
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
#import "CommandesCell.h"
#import "CommandesDetailVC.h"
#import "UIScrollView+EmptyDataSet.h"

typedef enum {
    Preparing = 0,
    Ready = 1,
    Done = 2,
    NotPaid = 3
} CmdStatus;

@interface CommandesTVC : UITableViewController <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIViewControllerPreviewingDelegate>
{
    NSArray *cmd;
    NSArray *cmdStatus;
    NSTimer *upd;
    NSInteger nbrUpd;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *__nullable ajoutBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *__nullable userBtn;
@property (weak, nonatomic) NSDictionary *__nullable infosCmdSel;

- (void) upd;
- (void) majTimerRecup;
- (void) recupCommandes:(BOOL)forcer;
- (void) loadCmds;
- (void) loadService;
- (IBAction) refresh:(nullable UIRefreshControl *)sender;
- (IBAction) commander:(nullable id)sender;
- (void) verifsCommande;
- (void) showCommande:(nullable NSDictionary *)dataToken;
- (void) masquerDetailModal;

@end


@interface CustomHeaderView : UIView

@property (weak, nonatomic) IBOutlet UILabel *__nullable serviceLabel;

@end
