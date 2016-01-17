//
//  NewsSplitVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "NewsMasterTVC.h"
#import "NewsDetailVC.h"

@interface NewsSplitVC : UISplitViewController <UISplitViewControllerDelegate>
{
//    UIBarButtonItem *userButton;
    NSArray *barButtons;
//    NewsMasterTVC *master;
}

@property (nonatomic, strong) NewsMasterTVC *master;

@end
