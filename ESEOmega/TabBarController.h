//
//  TabBarController.h
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "NewsSplitVC.h"
#import "EventsTVC.h"
#import "ClubsSplitVC.h"
#import "ClubsDetailTVC.h"
#import "CommandesTVC.h"
#import "SponsorsTVC.h"
#import "GameVC.h"
#import "SDWebImage/UIImageView+WebCache.h"

#define GUY_MODE 0

@interface TabBarController : UITabBarController <UITabBarControllerDelegate, MFMailComposeViewControllerDelegate>
{
    BOOL retapCmd;
#if GUY_MODE == 1
    NSTimeInterval launchTime;
    UITapGestureRecognizer *tap;
#endif
}

- (void) secret;
- (void) ecranConnex;
#if GUY_MODE == 1
- (void) ajouterTap;
- (void) retirerTap;
#endif

@end
