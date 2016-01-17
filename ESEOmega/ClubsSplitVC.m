//
//  ClubsSplitVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
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
