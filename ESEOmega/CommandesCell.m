//
//  CommandesCell.m
//  ESEOmega
//
//  Created by Thomas Naudet on 26/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

#import "CommandesCell.h"

@implementation CommandesCell

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    self.imgView.backgroundColor = _color;
}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    self.imgView.backgroundColor = _color;
}

@end
