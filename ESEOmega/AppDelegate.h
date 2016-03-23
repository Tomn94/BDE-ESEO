//
//  AppDelegate.h
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
@import CoreSpotlight;
#import "Data.h"
#import "TabBarController.h"
#import "SDWebImage/UIImageView+WebCache.h"

#define VERSION_NOTIFS_iOS 1.1
#define NV_VERSION_TITRE @"Une nouvelle version de l'app est disponible"
#define NV_VERSION_MESSG @"Impossible de recevoir les notifications, merci de mettre l'application à jour sur l'App Store."

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void) openNotif:(NSDictionary *)userInfo;

@end

