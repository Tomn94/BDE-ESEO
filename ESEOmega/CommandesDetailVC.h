//
//  CommandesDetailVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 28/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "CommandesTVC.h"
#import "TabBarController.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface CommandesDetailVC : UIViewController
{
    CGFloat brightness;
    NSTimer *upd;
    BOOL loaded;
}

@property (strong, nonatomic) NSDictionary *infos;
@property (weak, nonatomic) IBOutlet UIImageView *bandeau;
@property (weak, nonatomic) IBOutlet UILabel *titreLabel;
@property (weak, nonatomic) IBOutlet UILabel *prix;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UILabel *numCmdLabel;
@property (weak, nonatomic) IBOutlet UIView *numCmdLabelBack;
@property (weak, nonatomic) IBOutlet UILabel *numCmdHeader;
@property (weak, nonatomic) IBOutlet UIView *numCmdBack;

- (void) majTimerRecup;
- (void) loadCmd;
- (void) showCmd;
- (void) payCmd;

@end
