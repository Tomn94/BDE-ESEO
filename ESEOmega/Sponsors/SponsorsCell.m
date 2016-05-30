//
//  SponsorsCell.m
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

#import "SponsorsCell.h"

@implementation SponsorsCell

- (void) setAvantages:(NSArray *)avt
{
    
    avantages = avt;
    if ([avantages count] < 1)
        [_bonsPlansView setText:@""];
    else
        [_bonsPlansView setText:[[NSString stringWithFormat:@"✅ %@", [avantages componentsJoinedByString:@"\n✅ "]] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]];
    [_bonsPlansView setTextColor:[UIColor darkGrayColor]];
    [_bonsPlansView setFont:[UIFont systemFontOfSize:13]];
    _bonsPlansView.layoutManager.delegate = self;
    
    /*
     _bonsPlansView.delegate = self;
     _bonsPlansView.dataSource = self;*/
    /*
    [_bonsPlansView reloadData];
    [_bonsPlansView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    CGFloat height = 0;
    for (int i = 0 ; i < [avantages count] ; ++i)
    {
        height += [self tableView:_bonsPlansView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    if ([avantages count] > 1)
        NSLog(@"%@ %f", avantages[0], height);
    else
        NSLog(@"vide %f", height);
    [_bonsPlansView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_bonsPlansView(==%d)]", 0]
                                                                   options:0
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_bonsPlansView)]];*/
}

#pragma mark Layout manager delegate

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect
{
    return 7; // For really wide spacing; pick your own value
}

/*
#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [avantages count];
}

- (CGFloat)   tableView:(nonnull UITableView *)tableView
heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *cellText = avantages[indexPath.row];
    UIFont *cellFont = [UIFont systemFontOfSize:12];
    
    NSAttributedString *attributedText =
    [[NSAttributedString alloc]
     initWithString:cellText
     attributes:@
     {
     NSFontAttributeName: cellFont
     }];
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(tableView.bounds.size.width - 100, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    return rect.size.height + 7;
    
    return CELL_HEIGHT;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView
                  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    AvantagesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"avantageCell" forIndexPath:indexPath];*/
    /*
    [cell.textLabel setText:avantages[indexPath.row]];
    [cell.textLabel setFont:[UIFont systemFontOfSize:12]];
    [cell.textLabel setTextColor:[UIColor darkGrayColor]];
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    [cell.imageView setTintColor:[UIColor colorWithRed:0.549 green:0.824 blue:0 alpha:1]];
    [cell.imageView setImage:[[UIImage imageNamed:@"check"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];*/
    /*cell.avantageLabel.text = avantages[indexPath.row];
    cell.imgViewCheck.image = [[UIImage imageNamed:@"check"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    return cell;
}
*/
@end

/*@implementation AvantagesCell

- (void) layoutSubviews
 {
 [super layoutSubviews];
 //    self.imageView.frame = CGRectMake(0, 0, 22, 22);
 //    self.textLabel.frame = CGRectMake(25, 0, self.frame.size.width, 22);
 }

@end*/
