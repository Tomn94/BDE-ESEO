//
//  NewsSplitVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

#import "NewsSplitVC.h"

@implementation NewsSplitVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    _master = [(UINavigationController *)self.viewControllers[0] viewControllers][0];
    
    // Affichage ou non du bouton Utilisateur
//    userButton = (iPAD) ? nil : master.navigationItem.rightBarButtonItem;
    barButtons = (iPAD) ? nil : _master.navigationItem.rightBarButtonItems;
    [self splitViewController:self willChangeToDisplayMode:self.displayMode];
}

#pragma mark - Split View Controller delegate

- (BOOL)    splitViewController:(nonnull UISplitViewController *)splitViewController
collapseSecondaryViewController:(nonnull UIViewController *)secondaryViewController
      ontoPrimaryViewController:(nonnull UIViewController *)primaryViewController
{
    /*if ([secondaryViewController isKindOfClass:[UINavigationController class]]
        && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[NewsDetailVC class]]
        && ([(NewsDetailVC *)[(UINavigationController *)secondaryViewController topViewController] infos] == nil))*/
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
        [_master.navigationItem setRightBarButtonItem:nil        animated:YES];
    else
//        [master.navigationItem setRightBarButtonItem:userButton animated:YES];
        [_master.navigationItem setRightBarButtonItems:barButtons animated:YES];
}

- (void) viewWillTransitionToSize:(CGSize)size
        withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self splitViewController:self willChangeToDisplayMode:self.displayMode];
    } completion:nil];
}

@end
