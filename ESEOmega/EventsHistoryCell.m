//
//  EventsHistoryCell.m
//  ESEOmega
//
//  Created by Tomn on 11/01/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

#import "EventsHistoryCell.h"

@implementation EventsHistoryCell

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
