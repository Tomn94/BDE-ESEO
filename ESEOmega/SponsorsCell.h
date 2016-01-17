//
//  SponsorsCell.h
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;

//#define CELL_HEIGHT 25

@interface SponsorsCell : UITableViewCell/* <UITableViewDataSource, UITableViewDelegate>*/ <NSLayoutManagerDelegate>
{
    NSArray *avantages;
}

@property (weak, nonatomic) IBOutlet UILabel *nomLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UITextView *bonsPlansView;
//@property (weak, nonatomic) IBOutlet UITableView *bonsPlansView;

- (void) setAvantages:(NSArray *)avt;

@end

/*@interface AvantagesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgViewCheck;
@property (weak, nonatomic) IBOutlet UILabel *avantageLabel;

@end
*/