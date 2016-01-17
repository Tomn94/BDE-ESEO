//
//  TabBarController.m
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

#import "TabBarController.h"

@implementation TabBarController

- (void) viewDidLoad
{
    [[Data sharedData] setLaunchTime:[NSDate timeIntervalSinceReferenceDate]];
    self.delegate = self;
    retapCmd = NO;
    
//    [self ajouterTap];
    
    [[Data sharedData] updateJSON:@"news"];
    [[Data sharedData] updateJSON:@"events"];
    [[Data sharedData] updateJSON:@"clubs"];
    if ([Data estConnecte])
        [[Data sharedData] updateJSON:@"cmds"];
    [[Data sharedData] updateJSON:@"service"];
    [[Data sharedData] updateJSON:@"sponsors"];
    
    NSDateComponents *comps = [NSDateComponents new];
    [comps setDay:4];
    [comps setMonth:02];
    [comps setYear:2016];
    NSDate *bm = [[NSCalendar currentCalendar] dateFromComponents:comps];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"nouveauBoutonEventVu"] &&
        [[NSDate date] compare:bm] == NSOrderedAscending)
        self.viewControllers[1].tabBarItem.badgeValue = @"1";
}

/*- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[SDImageCache sharedImageCache] clearMemory];
}*/

/*
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [(UITabBarItem *)([[self tabBar] items][0]) setSelectedImage:[UIImage imageNamed:@"newsSel"]];
    [(UITabBarItem *)([[self tabBar] items][1]) setSelectedImage:[UIImage imageNamed:@"eventsSel"]];
    [(UITabBarItem *)([[self tabBar] items][2]) setSelectedImage:[UIImage imageNamed:@"clubsSel"]];
    [(UITabBarItem *)([[self tabBar] items][3]) setSelectedImage:[UIImage imageNamed:@"cafetSel"]];
    [(UITabBarItem *)([[self tabBar] items][4]) setSelectedImage:[UIImage imageNamed:@"sponsorsSel"]];
}
*/

/*- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self secret];
}*/

#pragma mark - Actions

- (void) secret
{
    /*if (tap)
        [self retirerTap];
    if ([NSDate timeIntervalSinceReferenceDate] - launchTime > 10)
        return;
    */
    GameVC *gameVC = [GameVC new];
    [self presentViewController:gameVC animated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }];
}/*

- (void) ajouterTap
{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"userId"] isEqualToString:@""])
        return;
    
    launchTime = [NSDate timeIntervalSinceReferenceDate];
    if (!tap)
    {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(secret)];
        [tap setNumberOfTapsRequired:10];
//        [tap setNumberOfTouchesRequired:2];
        [self.view addGestureRecognizer:tap];
    }
    [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(retirerTap) userInfo:nil repeats:NO];
}

- (void) retirerTap
{
    if (tap)
    {
        [self.view removeGestureRecognizer:tap];
        tap = nil;
    }
}*/

- (void) ecranConnex
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"Connex"];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:vc animated:YES completion:NULL];
}

#pragma mark - Tab Bar Controller delegate

- (BOOL)  tabBarController:(UITabBarController *)tabBarController
shouldSelectViewController:(UIViewController *)viewController
{
    if ([viewController isEqual:self.selectedViewController])
        if ([viewController respondsToSelector:@selector(visibleViewController)] &&
            [[(UINavigationController *)viewController visibleViewController] isKindOfClass:[CommandesTVC class]])
            retapCmd = YES;
    return YES;
}

- (void) tabBarController:(UITabBarController *)tabBarController
  didSelectViewController:(UIViewController *)viewController
{
    // Debug bandeau club
    if (tabBarController.selectedIndex == 2)
    {
        NSArray *vcs = [(UISplitViewController *)viewController viewControllers];
        UIViewController *vc = [(UINavigationController *)[vcs lastObject] viewControllers][0];
        if ([vc isKindOfClass:[ClubsDetailTVC class]])
            [(ClubsDetailTVC *)vc loadClub];
    }
    
    // 2e tap
    static UIViewController *previousController = nil;
    if (previousController == viewController)
    {
        switch (tabBarController.selectedIndex)
        {
            case 0:
                if ([viewController isKindOfClass:[NewsSplitVC class]])
                {
                    NewsSplitVC *split = (NewsSplitVC *)viewController;
                    if (split.collapsed)
                        [(UINavigationController *)split.viewControllers[0] popToRootViewControllerAnimated:YES];
                }
                break;
                
            case 1:
                [(EventsTVC *)[(UINavigationController *)viewController visibleViewController] scrollerMoisActuel];
                break;
                
            case 2:
                if ([viewController isKindOfClass:[ClubsSplitVC class]])
                {
                    ClubsSplitVC *split = (ClubsSplitVC *)viewController;
                    if (split.collapsed)
                        [(UINavigationController *)split.viewControllers[0] popToRootViewControllerAnimated:YES];
                }
                break;
                
            case 3:
                if (retapCmd)
                {
                    [[(CommandesTVC *)[(UINavigationController *)viewController visibleViewController] tableView] scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
                    retapCmd = NO;
                }
                break;
                
            case 4:
                [[(SponsorsTVC *)[(UINavigationController *)viewController visibleViewController] tableView] scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
                break;
                
            default:
                break;
        }
    }
    previousController = viewController;
}

#pragma mark - Mail Compose View Controller delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
