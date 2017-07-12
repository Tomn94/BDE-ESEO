//
//  ClubsSplitVC.m
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

#import "ClubsSplitVC.h"

@implementation ClubsSplitVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    master = [(UINavigationController *)self.viewControllers[0] viewControllers][0];
    
    // Affichage ou non du bouton Utilisateur
    userButton = (iPAD) ? nil : master.navigationItem.rightBarButtonItem;
    [self splitViewController:self willChangeToDisplayMode:self.displayMode];
    
//    [(ClubsDetailTVC *)[(UINavigationController *)self.viewControllers[1] viewControllers][0] selectedClub:@{@"titre": @42}];    // 1er article à charger sur iPad/iPhone 6+ en paysage
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)    splitViewController:(nonnull UISplitViewController *)splitViewController
collapseSecondaryViewController:(nonnull UIViewController *)secondaryViewController
      ontoPrimaryViewController:(nonnull UIViewController *)primaryViewController
{
    /*if ([secondaryViewController isKindOfClass:[UINavigationController class]]
     && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[NewsDetailVC class]]
     && ([(NewsDetailVC *)[(UINavigationController *)secondaryViewController topViewController] infos] == nil))*/
    if ([secondaryViewController isKindOfClass:[UINavigationController class]]
        && ([(UINavigationController *)secondaryViewController viewControllers][0] == nil
            || [(ClubsDetailTVC *)[(UINavigationController *)secondaryViewController viewControllers][0] infos] == nil))
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
        [master.navigationItem setRightBarButtonItem:nil        animated:YES];
    else
        [master.navigationItem setRightBarButtonItem:userButton animated:YES];
}

- (void) viewWillTransitionToSize:(CGSize)size
        withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self splitViewController:self willChangeToDisplayMode:self.displayMode];
     } completion:nil];
}

@end
