//
//  AppDelegate.m
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

#import "AppDelegate.h"
#import "BDE_ESEO-Swift.h"

@implementation AppDelegate

- (BOOL)          application:(nonnull UIApplication *)application
didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"alreadyLaunchedv4NewAPI"])
    {
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
        [[SDImageCache sharedImageCache] clearMemory];
        [[EGOCache globalCache] clearCache];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"alreadyLaunchedv4NewAPI"];
    }
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"alreadyLaunchedv5NewAPI"])
    {
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
        [[SDImageCache sharedImageCache] clearMemory];
        [[EGOCache globalCache] clearCache];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"alreadyLaunchedv5NewAPI"];
    }
    
    /* UI COLORS */
    [ThemeManager updateThemeWithAppIcon:false];
    
    /* NOTIFICATIONS */
    if (DataStore.isUserLogged)
        [Data registeriOSPush:self];
    
    /* APPLE WATCH */
    [ConnectivityHandler.sharedHandler startSession];
    
    // OPENED APP FROM NOTIFICATION
    if (![NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}])
    {
        NSDictionary *userInfo = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo[@"aps"])
        {
            double vers = [userInfo[@"version"] doubleValue];
            if (vers <= VERSION_NOTIFS_iOS)
            {
                NSInteger val = [userInfo[@"action"] integerValue];
                if (val >= 0)
                    [self openNotif:userInfo];
            }
            else
                [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(delayedAlert:)
                                               userInfo:@{@"titre": NV_VERSION_TITRE, @"message": NV_VERSION_MESSG, @"upd": @YES} repeats:NO];
        }
    }
    
    return YES;
}

- (void) applicationWillResignActive:(nonnull UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void) applicationDidEnterBackground:(nonnull UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void) applicationWillEnterForeground:(nonnull UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"debugRefresh" object:nil];
    
    if ([[Data sharedData] cafetDebut] != 0 &&
        [[NSDate date] timeIntervalSinceReferenceDate] - [[Data sharedData] cafetDebut] > MAX_ORDER_TIME)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"retourAppCafetFin" object:nil];
}

- (void) applicationDidBecomeActive:(nonnull UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void) applicationWillTerminate:(nonnull UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - 3D Touch

- (void)          application:(UIApplication *)application
 performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
            completionHandler:(void (^)(BOOL))completionHandler
{
    TabBarController *tab = (TabBarController *)(self.window.rootViewController);
    if ([shortcutItem.type isEqualToString:@"com.eseomega.ESEOmega.cafet"])
    {
        [tab setSelectedIndex:3];
        NSNotification *notif = [NSNotification notificationWithName:@"btnCommanderCafet" object:nil];
        [[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) withObject:notif afterDelay:0.5];
    }
    else if ([shortcutItem.type isEqualToString:@"com.eseomega.ESEOmega.events"])
        [tab setSelectedIndex:1];
    else if ([shortcutItem.type isEqualToString:@"com.eseomega.ESEOmega.portail"])
        [[Data sharedData] openURL:[LinksToolbar portalQuickLink]
                         currentVC:tab];
    else if ([shortcutItem.type isEqualToString:@"com.eseomega.ESEOmega.campus"])
        [[Data sharedData] openURL:[LinksToolbar campusQuickLink]
                         currentVC:tab];
    else if ([shortcutItem.type isEqualToString:@"com.eseomega.ESEOmega.salles"]) {
        BOOL dontReopen = NO;
        UIViewController *vc = self.window.rootViewController.presentedViewController;
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nvc = (UINavigationController *)self.window.rootViewController.presentedViewController;
            if ([nvc isKindOfClass:[RoomsTVC class]]) {
                dontReopen = YES;
            }
        }
        if (!dontReopen) {
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Rooms" bundle:nil];
            UINavigationController *vc = [sb instantiateInitialViewController];
            vc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
        }
    }
    
    completionHandler(YES);
}

#pragma mark - Notifications

- (void)                             application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[Data sharedData] setPushToken:deviceToken];
    
    [Data sendPushToken];
}

- (void)                             application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
}


// iOS 10: In-app support
- (void) userNotificationCenter:(UNUserNotificationCenter *)center
        willPresentNotification:(UNNotification *)notification
          withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    NSDictionary *userInfo = notification.request.content.userInfo;
    
    double vers = [userInfo[@"version"] doubleValue];
    NSInteger val = [userInfo[@"action"] integerValue];
    
    if (vers > VERSION_NOTIFS_iOS || val == 21)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NV_VERSION_TITRE
                                                                       message:NV_VERSION_MESSG
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *updateAction = [UIAlertAction actionWithTitle:@"Mettre à jour"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
        }];
        [alert addAction:updateAction];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ignorer"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [alert setPreferredAction:updateAction];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        
        completionHandler(UNNotificationPresentationOptionNone);
        return;
    }
    
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
}


// iOS 10: Action response
- (void) userNotificationCenter:(UNUserNotificationCenter *)center
 didReceiveNotificationResponse:(UNNotificationResponse *)response
          withCompletionHandler:(void (^)(void))completionHandler
{
    if (![response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
        [self openNotif:response.notification.request.content.userInfo];
    }
    completionHandler();
}

// pre-iOS 10
- (void)          application:(UIApplication *)application
 didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    double vers = [userInfo[@"version"] doubleValue];
    NSInteger val = [userInfo[@"action"] integerValue];
    
    if (vers > VERSION_NOTIFS_iOS || val == 21)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NV_VERSION_TITRE
                                                                       message:NV_VERSION_MESSG
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *updateAction = [UIAlertAction actionWithTitle:@"Mettre à jour"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
        }];
        [alert addAction:updateAction];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ignorer"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [alert setPreferredAction:updateAction];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if (application.applicationState == UIApplicationStateActive)
    {
        NSString *titre   = @"";//userInfo[@"aps"][@"alert"][@"title"];
        NSString *message = @"";//userInfo[@"aps"][@"alert"][@"body"];
        if (![userInfo[@"aps"][@"alert"] isKindOfClass:[NSString class]] && ![userInfo[@"aps"][@"body"] isKindOfClass:[NSString class]])
        {
            titre   = userInfo[@"aps"][@"alert"][@"title"];
            message = userInfo[@"aps"][@"alert"][@"body"];
        }
        else if ([userInfo[@"aps"][@"alert"] rangeOfString:@"\n"].location != NSNotFound)
        {
            NSMutableArray *sep = [NSMutableArray arrayWithArray:[userInfo[@"aps"][@"alert"] componentsSeparatedByString:@"\n"]];
            titre = sep[0];
            [sep removeObjectAtIndex:0];
            message = [sep componentsJoinedByString:@"\n"];
        }
        else
            message = userInfo[@"aps"][@"alert"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:titre
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        if (val > 0)
        {
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Voir" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                                            {
                                                [self openNotif:userInfo];
                                            }];
            [alert addAction:defaultAction];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ignorer"
                                                      style:UIAlertActionStyleCancel handler:nil]];
            [alert setPreferredAction:defaultAction];
        }
        else
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel handler:nil]];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
    else if (val >= 0)
        [self openNotif:userInfo];
}

- (void) openNotif:(NSDictionary *)userInfo
{
    NSInteger val = [userInfo[@"action"] integerValue];
    TabBarController *tab = (TabBarController *)(self.window.rootViewController);
    
    if (val == 42)
    {
        if (!DataStore.isUserLogged)
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:tab selector:@selector(ecranConnex) userInfo:nil repeats:NO];
        else
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:tab selector:@selector(secret) userInfo:nil repeats:NO];
        return;
    }
    else if (val == 99)
    {
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:tab selector:@selector(ecranConnex) userInfo:nil repeats:NO];
        return;
    }
    else if (val == 21)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
        return;
    }
    else if (val == 85)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:@YES forKey:@"GPenabled"];
        [defaults synchronize];
        return;
    }
    else if (val == 86)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:@NO forKey:@"GPenabled"];
        [defaults synchronize];
        return;
    }
    else if (val == 0)
    {
        NSString *titre   = @"";
        NSString *message = @"";
        if (![userInfo[@"aps"][@"alert"] isKindOfClass:[NSString class]] && ![userInfo[@"aps"][@"body"] isKindOfClass:[NSString class]])
        {
            titre   = userInfo[@"aps"][@"alert"][@"title"];
            message = userInfo[@"aps"][@"alert"][@"body"];
        }
        else if ([userInfo[@"aps"][@"alert"] rangeOfString:@"\n"].location != NSNotFound)
        {
            NSMutableArray *sep = [NSMutableArray arrayWithArray:[userInfo[@"aps"][@"alert"] componentsSeparatedByString:@"\n"]];
            titre = sep[0];
            [sep removeObjectAtIndex:0];
            message = [sep componentsJoinedByString:@"\n"];
        }
        else
            message = userInfo[@"aps"][@"alert"];

        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(delayedAlert:) userInfo:@{@"titre": titre, @"message": message} repeats:NO];
        return;
    }
    
    NSUInteger index = 0;
    if (val > 0)
        index = val - 1;
    if (index >= [tab.viewControllers count])
        index = [tab.viewControllers count] - 1;
    
    if (index == 1)
        [[Data sharedData] updateJSON:@"events"];
    else if (index == 2)
        [[Data sharedData] updateJSON:@"clubs"];
    else if (index == 4)
        [[Data sharedData] updateJSON:@"sponsors"];
    
    [tab setSelectedIndex:index];
}

- (void) delayedAlert:(NSTimer *)timer
{
    NSDictionary *infos = timer.userInfo;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:infos[@"titre"]
                                                                   message:infos[@"message"]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    if (infos[@"upd"] != nil && infos[@"upd"])
    {
        UIAlertAction *updateAction = [UIAlertAction actionWithTitle:@"Mettre à jour"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
        }];
        [alert addAction:updateAction];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ignorer"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [alert setPreferredAction:updateAction];
    } else {
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel handler:nil]];
    }
    
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - URL Scheme Lydia

- (BOOL) application:(UIApplication *)application
       handleOpenURL:(NSURL *)url
{
    TabBarController *tab = (TabBarController *)(self.window.rootViewController);
    
    if ([url.host isEqualToString:@"news"])
        [tab setSelectedIndex:0];
    else if ([url.host isEqualToString:@"events"])
        [tab setSelectedIndex:1];
    else if ([url.host isEqualToString:@"clubs"])
        [tab setSelectedIndex:2];
    else if ([url.host isEqualToString:@"cafet"])
        [tab setSelectedIndex:3];
    else if ([url.host isEqualToString:@"sponsors"])
        [tab setSelectedIndex:4];
    else if ([url.host isEqualToString:@"pay"])  // eseomega://pay?id=4242&cat=CAFET
    {
        if (DataStore.isUserLogged)
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSArray *pairs = [url.query componentsSeparatedByString:@"&"];
            
            for (NSString *pair in pairs) {
                NSArray *elements = [pair componentsSeparatedByString:@"="];
                NSString *key = [elements[0] stringByRemovingPercentEncoding];
                NSString *val = [elements[1] stringByRemovingPercentEncoding];
                [dict setObject:val forKey:key];
            }
            
            if (dict[@"id"] != nil && dict[@"cat"] != nil)
            {
                if ([[Data sharedData] alertRedir] != nil)
                {
                    UIAlertController *alert = [[Data sharedData] alertRedir];
                    [alert dismissViewControllerAnimated:NO completion:nil];
                    [[Data sharedData] setAlertRedir:nil];
                }
                if ([dict[@"cat"] isEqualToString:@"CAFET"])
                    [tab setSelectedIndex:3];
                else if ([dict[@"cat"] isEqualToString:@"EVENT"])
                    [tab setSelectedIndex:1];
                [Lydia checkStatusObjCBridge:dict showRating:YES];
            }
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"État du paiement Lydia"
                                                                           message:@"Erreur : impossible de vérifier le paiement, vous n'êtes pas connecté à votre compte.\nParlez-en à un membre du BDE"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil]];
            [tab presentViewController:alert animated:YES completion:Nil];
        }
    }
    
    return YES;
}

#pragma mark - Handoff

- (BOOL) application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
  restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    TabBarController *tab = (TabBarController *)(self.window.rootViewController);
    if (tab.presentedViewController != nil) {
        [tab dismissViewControllerAnimated:true completion:nil];
    }
    
    if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.news"])
        [tab setSelectedIndex:0];
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.article"])
    {
        [tab setSelectedIndex:0];
        
        NewsSplit *newsSplit = tab.viewControllers.firstObject;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        NewsArticleVC *detail = (NewsArticleVC *)[storyboard instantiateViewControllerWithIdentifier:@"newsArticleVC"];
        [detail continueReadingWithUserInfo:userActivity.userInfo];
        [newsSplit showDetailViewController:detail sender:nil];
    }
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.events"])
        [tab setSelectedIndex:1];
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.clubs"])
        [tab setSelectedIndex:2];
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.cafet"])
        [tab setSelectedIndex:3];
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.order"])
    {
        [tab setSelectedIndex:3];
        
        if (![Data sharedData].cafetCmdEnCours)
        {
            UINavigationController *navVC =   tab.viewControllers.firstObject;
            CafetOrdersTVC      *ordersVC = navVC.viewControllers.firstObject;
            if ([ordersVC isKindOfClass:[CafetOrdersTVC class]])
                [ordersVC order];
        }
    }
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.sponsors"])
        [tab setSelectedIndex:4];
    
    return YES;
}

@end
