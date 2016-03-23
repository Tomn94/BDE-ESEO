//
//  AppDelegate.m
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)          application:(nonnull UIApplication *)application
didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
//    [[SDImageCache sharedImageCache] clearDisk];
//    [[SDImageCache sharedImageCache] clearMemory];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.000 green:0.647 blue:1 alpha:1]];
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.806 green:0.959 blue:1 alpha:1]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] }];
    [_window setTintColor:[UIColor colorWithRed:0.078 green:0.707 blue:1 alpha:1]];
    
    if ([Data estConnecte])
    {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    
    NSDictionary *userInfo = [launchOptions valueForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    if (userInfo[@"aps"])
    {
        NSInteger vers = [userInfo[@"version"] doubleValue];
        if (vers <= VERSION_NOTIFS_iOS)
        {
            NSInteger val = [userInfo[@"action"] integerValue];
            if (val >= 0)
                [self openNotif:userInfo];
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NV_VERSION_TITRE
                                                                           message:NV_VERSION_MESSG
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Mettre à jour" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ignorer" style:UIAlertActionStyleCancel handler:nil]];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    }
    
    return YES;
}

- (void) applicationWillResignActive:(nonnull UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"stopBrightness" object:nil];
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
        [[Data sharedData] openURL:URL_PORTAIL currentVC:tab];
    else if ([shortcutItem.type isEqualToString:@"com.eseomega.ESEOmega.campus"])
        [[Data sharedData] openURL:URL_CAMPUS currentVC:tab];
}

#pragma mark - Notifications

- (void)                             application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[Data sharedData] setPushToken:deviceToken];
    
    EGOCache *ec = [EGOCache globalCache];
    if ([ec hasCacheForKey:@"deviceTokenPush"] && [[ec dataForKey:@"deviceTokenPush"] isEqualToData:deviceToken])
        return;
    
    [Data sendPushToken];
}

- (void)                             application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
//    NSLog(@"%@", error);
}

- (void)         application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSInteger vers = [userInfo[@"version"] doubleValue];
    if (vers <= VERSION_NOTIFS_iOS)
    {
        NSInteger val = [userInfo[@"action"] integerValue];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (val == 85)
            [defaults setValue:@YES forKey:@"GPenabled"];
        else if (val == 86)
            [defaults setValue:@NO forKey:@"GPenabled"];
        [defaults synchronize];
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)          application:(UIApplication *)application
 didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSInteger vers = [userInfo[@"version"] doubleValue];
    NSInteger val = [userInfo[@"action"] integerValue];
    
    if (application.applicationState == UIApplicationStateActive)
    {
        NSString *titre = userInfo[@"aps"][@"title"];
        NSString *message = userInfo[@"aps"][@"body"];
        if (vers > VERSION_NOTIFS_iOS)
        {
            titre = NV_VERSION_TITRE;
            message = NV_VERSION_MESSG;
        }
        /*else if ([titre rangeOfString:@"\n"].location != NSNotFound)
        {
            titre = userInfo[@"aps"][@"title"];
            message = userInfo[@"aps"][@"body"];
            NSMutableArray *sep = [NSMutableArray arrayWithArray:[titre componentsSeparatedByString:@"\n"]];
            titre = sep[0];
            [sep removeObjectAtIndex:0];
            message = [sep componentsJoinedByString:@"\n"];
        }*/
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:titre
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        if (vers > VERSION_NOTIFS_iOS || val == 21 || [userInfo[@"aps"][@"alert"] isKindOfClass:[NSString class]])
        {
            [alert addAction:[UIAlertAction actionWithTitle:@"Mettre à jour" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ignorer" style:UIAlertActionStyleCancel handler:nil]];
        }
        else if (val > 0)
        {
            [alert addAction:[UIAlertAction actionWithTitle:@"Voir" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                              {
                                  [self openNotif:userInfo];
                              }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ignorer" style:UIAlertActionStyleCancel handler:nil]];
        }
        else
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
    else if (val > 0)
        [self openNotif:userInfo];
}

- (void) openNotif:(NSDictionary *)userInfo
{
    NSInteger val = [userInfo[@"action"] integerValue];
    TabBarController *tab = (TabBarController *)(self.window.rootViewController);
    
    if (val == 42)
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:tab selector:@selector(secret) userInfo:nil repeats:NO];
        return;
    }
    else if (val == 99)
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:tab selector:@selector(ecranConnex) userInfo:nil repeats:NO];
        return;
    }
    else if (val == 21)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
        return;
    }
    else if (val == 0)
    {
        NSString *titre   = userInfo[@"aps"][@"alert"][@"title"];
        NSString *message = userInfo[@"aps"][@"alert"][@"body"];
        /*if ([titre rangeOfString:@"\n"].location != NSNotFound)
        {
            NSMutableArray *sep = [NSMutableArray arrayWithArray:[titre componentsSeparatedByString:@"\n"]];
            titre = sep[0];
            [sep removeObjectAtIndex:0];
            message = [sep componentsJoinedByString:@"\n"];
        }*/

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:titre
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSUInteger index = 0;
    if (val > 0)
        index = val - 1;
    if (index >= [tab.viewControllers count])
        index = [tab.viewControllers count] - 1;
    
    if (index == 0)
        [[Data sharedData] updateJSON:@"news"];
    else if (index == 1)
        [[Data sharedData] updateJSON:@"events"];
    else if (index == 2)
        [[Data sharedData] updateJSON:@"clubs"];
    else if (index == 3 && [Data estConnecte])
        [[Data sharedData] updateJSON:@"cmds"];
    else if (index == 4)
        [[Data sharedData] updateJSON:@"sponsors"];
    
    [tab setSelectedIndex:index];
}

#pragma mark - URL Scheme

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
        if ([Data estConnecte])
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSArray *pairs = [url.query componentsSeparatedByString:@"&"];
            
            for (NSString *pair in pairs) {
                NSArray *elements = [pair componentsSeparatedByString:@"="];
                NSString *key = [elements[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSString *val = [elements[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
                [[Data sharedData] checkLydia:dict];
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
    /*
    if (userActivity.activityType == CSSearchableItemActionType)
    {
        NSString *ident = userActivity.userInfo[CSSearchableItemActivityIdentifier];
        if (ident != nil)
        {
            userActivity.userInfo[CSSearchableItemActivityIdentifier]
        }
    }*/
    
    if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.news"])
        [tab setSelectedIndex:0];
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.article"])
    {
        [tab setSelectedIndex:0];
        [[(NewsSplitVC *)([tab viewControllers][0]) master] openWithInfos:userActivity.userInfo];
    }
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.events"])
        [tab setSelectedIndex:1];
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.clubs"])
        [tab setSelectedIndex:2];
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.cafet"])
        [tab setSelectedIndex:3];
    else if ([userActivity.activityType isEqualToString:@"com.eseomega.ESEOmega.sponsors"])
        [tab setSelectedIndex:4];
    
    return YES;
}

@end
