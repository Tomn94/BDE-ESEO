//
//  EventsHistoryCell.h
//  ESEOmega
//
//  Created by Tomn on 11/01/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;

@interface EventsHistoryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nomLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *prixLabel;
@property (weak, nonatomic) IBOutlet UILabel *numLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) UIColor *color;

@end
