//
//  OrderPVC.h
//  ESEOmega
//
//  Created by Thomas NAUDET on 01/08/2015.
//  Copyright © 2015 Thomas NAUDET

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
#import "Data.h"

@interface OrderPVC : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIToolbarDelegate>

{
    NSArray *viewControllers;
    UISegmentedControl *seg;
    UIToolbar *toolbar;
    BOOL messageQuitterVu;
}

- (void) timeout;
- (IBAction) fermer:(id)sender;
- (void) fermerForcer;
- (void) fermerForcerLydia:(NSNotification *)n;
- (void) tabSelected;
- (void) updSegTitle;
- (void) rotateToolbar;
- (UIViewController *) viewControllerAtIndex:(NSInteger)i;

@end
