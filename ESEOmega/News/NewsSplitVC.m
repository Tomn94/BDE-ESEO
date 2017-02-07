//
//  NewsSplitVC.m
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

#import "NewsSplitVC.h"

@implementation NewsSplitVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    _master = [(UINavigationController *)self.viewControllers[0] viewControllers][0];
    
    // Credits navigation bar button
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(credits) forControlEvents:UIControlEventTouchUpInside];
    creditsItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    // Showing User & Share buttons to the right place depending on the context
    barButtons = (iPAD) ? [NSArray array] : _master.navigationItem.rightBarButtonItems;
    [self splitViewController:self willChangeToDisplayMode:self.displayMode];
}

#pragma mark - Split View Controller delegate

- (BOOL)    splitViewController:(nonnull UISplitViewController *)splitViewController
collapseSecondaryViewController:(nonnull UIViewController *)secondaryViewController
      ontoPrimaryViewController:(nonnull UIViewController *)primaryViewController
{
    if ([secondaryViewController isKindOfClass:[UINavigationController class]]
        && ([(UINavigationController *)secondaryViewController viewControllers][0] == nil
        || [(NewsDetailVC *)[(UINavigationController *)secondaryViewController viewControllers][0] infos] == nil))
        return YES;
    else
        return NO;
}

#pragma mark Bouton Utilisateur

- (void) splitViewController:(nonnull UISplitViewController *)svc
     willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
{
    if (displayMode == UISplitViewControllerDisplayModeAllVisible &&
        self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact)
        [_master.navigationItem setRightBarButtonItems:@[creditsItem] animated:YES];    // iPad/iPhone 6+ landscape
    else
    {
        NSMutableArray *buttons = barButtons.mutableCopy;
        [buttons addObject:creditsItem];
        [_master.navigationItem setRightBarButtonItems:buttons animated:YES];       // other
    }
}

- (void) viewWillTransitionToSize:(CGSize)size
        withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self splitViewController:self willChangeToDisplayMode:self.displayMode];
    } completion:nil];
}

#pragma mark Crédits

- (void) credits
{
    CreditsTVC *credits = [[CreditsTVC alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:credits];
    [nc setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:nc animated:YES completion:nil];
}

@end
