//
//  CommandesDetailVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 28/07/2015.
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
#import "CommandesTVC.h"
#import "TabBarController.h"
#import "../SDWebImage/UIImageView+WebCache.h"

@interface CommandesDetailVC : UIViewController <CAAnimationDelegate>
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
