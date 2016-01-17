//
//  NewsLinksVC.m
//  ESEOmega
//
//  Created by Tomn on 07/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

#import "NewsLinksVC.h"

@implementation NewsLinksVC

- (instancetype) init
{
    if (self = [super init])
    {
        titles = @[URL_BDE_TTLE, @"Nous contacter", @"Facebook", @"Instagram", @"Snapchat", @"Twitter", @"YouTube"];
        links  = @[URL_BDE, MAIL_BDE, URL_FACEBOOK, USR_INSTA, USR_SNAP, USR_TWITTER, URL_YOUTUBE];
        
        self.modalPresentationStyle = UIModalPresentationPopover;
        self.popoverPresentationController.sourceView = self.view;
        self.preferredContentSize = CGSizeMake(200, (44 * [titles count]) - 1);
    }
    return self;
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [titles count];
}


- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView
                  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eseomegaLinkCell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"eseomegaLinkCell"];
    
    cell.textLabel.text = titles[indexPath.row];
    switch (indexPath.row)
    {
        case 0:
            cell.imageView.image = [[UIImage imageNamed:@"site"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case 1:
            cell.imageView.image = [[UIImage imageNamed:@"mail"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case 2:
            cell.imageView.image = [[UIImage imageNamed:@"fb"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case 3:
            cell.imageView.image = [[UIImage imageNamed:@"instagram"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case 4:
            cell.imageView.image = [[UIImage imageNamed:@"snap"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case 5:
            cell.imageView.image = [[UIImage imageNamed:@"twitter"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case 6:
            cell.imageView.image = [[UIImage imageNamed:@"youtube"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        default:
            break;
    }
    
    return cell;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0:
        case 2:
        case 6:
            [[Data sharedData] openURL:links[indexPath.row] currentVC:self];
            break;
        case 1:
            [[Data sharedData] mail:links[indexPath.row] currentVC:self];
            break;
        case 3:
            [[Data sharedData] instagram:links[indexPath.row] currentVC:self];
            break;
        case 4:
            [[Data sharedData] snapchat:links[indexPath.row] currentVC:self];
            break;
        case 5:
            [[Data sharedData] twitter:links[indexPath.row] currentVC:self];
            break;
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - 3D Touch

- (UIViewController *) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
               viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *index = [self.tableView indexPathForRowAtPoint:location];
    if (index != nil)
    {
        NSString *url    = links[index.row];
        NSString *reseau = titles[index.row];
        if ([url isEqualToString:MAIL_BDE] || [reseau isEqualToString:@"Snapchat"])
            return nil;
        else if ([reseau isEqualToString:@"Instagram"])
            url = [NSString stringWithFormat:@"https://instagram.com/%@/", url];
        else if ([reseau isEqualToString:@"Twitter"])
            url = [NSString stringWithFormat:@"https://twitter.com/%@", url];
        
        previewingContext.sourceRect = [self.tableView rectForRowAtIndexPath:index];
        
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]
                                                             entersReaderIfAvailable:NO];
        safari.delegate = self;
        return safari;
    }
    return nil;
}

- (void) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
      commitViewController:(UIViewController *)viewControllerToCommit
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    [[Data sharedData] setT_currentTopVC:nil];
}

#pragma mark - Safari Controller Delegate

- (void) safariViewControllerDidFinish:(nonnull SFSafariViewController *)controller
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

#pragma mark - Mail Compose View Controller delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
