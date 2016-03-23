//
//  CommandesTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
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
