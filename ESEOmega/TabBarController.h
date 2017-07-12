//
//  TabBarController.h
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

@interface TabBarController : UITabBarController <UITabBarControllerDelegate, MFMailComposeViewControllerDelegate>
{
    BOOL retapCmd;
    NSTimeInterval launchTime;
    UITapGestureRecognizer *tap;
}

- (void) secret;
- (void) ecranConnex;
- (void) ajouterTap;
- (void) retirerTap;

@end

/** Used by Events, Cafet, Sponsors tabs to display a light status bar */
@interface LightStatusBarNVC : UINavigationController
@end
