//
//  CommandeDetailSegue.m
//  ESEOmega
//
//  Created by Thomas Naudet on 28/07/2015.
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

#import "CommandeDetailSegue.h"

@implementation CommandeDetailSegue


- (void) perform
{
    CommandesTVC *sourceViewController = self.sourceViewController;
    CommandesDetailVC *destinationViewController = self.destinationViewController;
    
    if (iPAD)
    {
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:destinationViewController];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        
        destinationViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                                    target:sourceViewController
                                                                                                                    action:@selector(masquerDetailModal)];
        
        [sourceViewController presentViewController:nc animated:YES completion:^{
            [sourceViewController.tableView deselectRowAtIndexPath:[sourceViewController.tableView indexPathForSelectedRow]
                                                          animated:YES];
        }];
    }
    else
        [sourceViewController.navigationController pushViewController:destinationViewController animated:YES];
}

@end
