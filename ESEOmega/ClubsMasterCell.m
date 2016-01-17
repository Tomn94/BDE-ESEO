//
//  ClubsMasterCell.m
//  ESEOmega
//
//  Created by Thomas Naudet on 26/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
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
