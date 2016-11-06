//
//  AppDelegate.h
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

@import UIKit;
@import CoreSpotlight;
@import UserNotifications;
#import "Data.h"
#import "TabBarController.h"
#import "SallesTVC.h"
#import "SDWebImage/UIImageView+WebCache.h"

#define VERSION_NOTIFS_iOS 1.2
#define NV_VERSION_TITRE @"Une nouvelle version de l'app est disponible"
#define NV_VERSION_MESSG @"Impossible de recevoir les notifications, merci de mettre l'application à jour sur l'App Store."

@interface AppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void) openNotif:(NSDictionary *)userInfo;
- (void) delayedAlert:(NSTimer *)timer;

@end

