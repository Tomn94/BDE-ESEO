//
//  ClubsSplitVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "ClubsMasterTVC.h"
#import "ClubsDetailTVC.h"

@interface ClubsSplitVC : UISplitViewController <UISplitViewControllerDelegate>
{
    UIBarButtonItem *userButton;
    ClubsMasterTVC *master;
}

@end
