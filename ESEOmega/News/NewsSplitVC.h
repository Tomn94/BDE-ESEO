//
//  NewsSplitVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
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
#import "TabBarController.h"
#import "NewsMasterTVC.h"
#import "NewsDetailVC.h"

@interface NewsSplitVC : UISplitViewController <UISplitViewControllerDelegate>
{
    NSArray *barButtons;
    UIBarButtonItem *creditsItem;
}

@property (nonatomic, strong) NewsMasterTVC *master;

- (void) credits;

@end
