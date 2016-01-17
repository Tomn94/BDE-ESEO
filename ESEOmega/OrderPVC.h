//
//  OrderPVC.h
//  ESEOmega
//
//  Created by Thomas NAUDET on 01/08/2015.
//  Copyright © 2015 Thomas NAUDET. All rights reserved.
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
