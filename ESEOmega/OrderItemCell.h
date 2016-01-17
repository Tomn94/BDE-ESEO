//
//  OrderItemCell.h
//  ESEOmega
//
//  Created by Tomn on 20/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;

@interface OrderItemCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titre;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UILabel *prix;

@end
