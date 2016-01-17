//
//  OrderMenuCell.h
//  ESEOmega
//
//  Created by Tomn on 20/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;

@interface OrderMenuCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nom;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UILabel *prix;
@property (weak, nonatomic) IBOutlet UIImageView *back;

@end
