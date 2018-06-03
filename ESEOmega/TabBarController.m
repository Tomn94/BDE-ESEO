//
//  TabBarController.m
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
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

#import "TabBarController.h"
#import "BDE_ESEO-Swift.h"

@implementation TabBarController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [[Data sharedData] setLaunchTime:[NSDate timeIntervalSinceReferenceDate]];
    self.delegate = self;
    retapCmd = NO;

//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GPenabled"])
    [self ajouterTap];
    
    [Data checkAvailability];
    [[Data sharedData] updateJSON:@"events"];
    [[Data sharedData] updateJSON:@"clubs"];
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
    if (!DataStore.isUserLogged)
        return;
    /*
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"GPenabled"])
        return;*/
    
    if (tap)
        [self retirerTap];
//    if ([NSDate timeIntervalSinceReferenceDate] - launchTime > 10)
//        return;
    
    GameVC *gameVC = [GameVC new];
    [self presentViewController:gameVC animated:YES completion:nil];
}

- (void) ajouterTap
{
    if (!DataStore.isUserLogged)
        return;
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:[NSURL URLWithString:URL_GP_STATE]
                                                   completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          
                                          NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                          
                                          BOOL ok = [result containsString:@"g"] && [result containsString:@"P"];
                                          [[NSUserDefaults standardUserDefaults] setBool:ok
                                                                                  forKey:@"GPenabled"];
                                          [[NSUserDefaults standardUserDefaults] synchronize];
                                          
                                          if (ok)
                                          {
                                              //    launchTime = [NSDate timeIntervalSinceReferenceDate];
                                              if (!tap)
                                              {
                                                  tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(secret)];
                                                  [tap setNumberOfTapsRequired:10];
                                                  [self.view addGestureRecognizer:tap];
                                              }
                                              //    [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(retirerTap) userInfo:nil repeats:NO];
                                          }
                                      }];
    [dataTask resume];
    [[Data sharedData] updLoadingActivity:YES];
}

- (void) retirerTap
{
    if (tap)
    {
        [self.view removeGestureRecognizer:tap];
        tap = nil;
    }
}

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
            [[(UINavigationController *)viewController visibleViewController] isKindOfClass:[CafetOrdersTVC class]])
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
                if ([viewController isKindOfClass:[NewsSplit class]])
                {
                    NewsSplit *split = (NewsSplit *)viewController;
                    if (split.collapsed)
                        [(UINavigationController *)split.viewControllers[0] popToRootViewControllerAnimated:YES];
                }
                break;
                
            case 1:
                [(EventsTVC *)[(UINavigationController *)viewController visibleViewController] scrollerMoisActuel];
                break;
                
            case 2:
                if ([viewController isKindOfClass:[ClubsSplit class]])
                {
                    ClubsSplit *split = (ClubsSplit *)viewController;
                    if (split.collapsed)
                        [(UINavigationController *)split.viewControllers[0] popToRootViewControllerAnimated:YES];
                }
                break;
                
            case 3:
                if (retapCmd)
                {
                    [[(CafetOrdersTVC *)[(UINavigationController *)viewController visibleViewController] tableView] scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
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


@implementation LightStatusBarNVC

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
