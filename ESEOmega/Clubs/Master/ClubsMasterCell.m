//
//  ClubsMasterCell.m
//  ESEOmega
//
//  Created by Thomas Naudet on 26/07/2015.
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

#import "ClubsMasterCell.h"

@implementation ClubsMasterCell

- (void) cellOnTableView:(nonnull UITableView *)tableView
         didScrollOnView:(nonnull UIView *)view
{
    [_imgView setFrame:CGRectMake(0, -(PARALLAX_DIFF/4) - 10, self.frame.size.width, 15 + ROW_HEIGHT + (PARALLAX_DIFF / 2))];
    if (view == nil)
        view = [UIApplication sharedApplication].windows[0];
    if (view == nil)
        return;
    
    CGRect rectInSuperview = [tableView convertRect:self.frame toView:view];
    
    float distanceFromCenter = CGRectGetHeight(view.frame)/2 - CGRectGetMinY(rectInSuperview);
    float move = (distanceFromCenter / CGRectGetHeight(view.frame)) * PARALLAX_DIFF;
    
    CGRect imageRect = _imgView.frame;
    imageRect.origin.y = - (PARALLAX_DIFF / 2) + move;
    _imgView.frame = imageRect;
}

@end
