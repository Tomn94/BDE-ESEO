//
//  ClubsMasterCell.h
//  ESEOmega
//
//  Created by Thomas Naudet on 26/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;

#define ROW_HEIGHT    125
#define PARALLAX_DIFF 60

@interface ClubsMasterCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *__nullable titreLabel;
@property (weak, nonatomic) IBOutlet UILabel *__nullable detailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *__nullable imgView;


- (void) cellOnTableView:(nonnull UITableView *)tableView
         didScrollOnView:(nonnull UIView *)view;

@end
