//
//  CommandesCell.h
//  ESEOmega
//
//  Created by Thomas Naudet on 26/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;

@interface CommandesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nomLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *prixLabel;
@property (weak, nonatomic) IBOutlet UILabel *numLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) UIColor *color;

@end
