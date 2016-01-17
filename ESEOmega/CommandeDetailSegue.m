//
//  CommandeDetailSegue.m
//  ESEOmega
//
//  Created by Thomas Naudet on 28/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

#import "CommandeDetailSegue.h"

@implementation CommandeDetailSegue


- (void) perform
{
    CommandesTVC *sourceViewController = self.sourceViewController;
    CommandesDetailVC *destinationViewController = self.destinationViewController;
    
//    destinationViewController.infos = sourceViewController.infosCmdSel;
    
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
