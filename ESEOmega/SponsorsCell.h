//
//  SponsorsCell.h
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
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