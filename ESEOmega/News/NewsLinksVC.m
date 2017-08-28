//
//  NewsLinksVC.m
//  ESEOmega
//
//  Created by Thomas NAUDET on 07/08/2015.
//  Copyright © 2015 Thomas NAUDET

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

#import "NewsLinksVC.h"

@implementation NewsLinksVC

- (instancetype) init
{
    if (self = [super init])
    {
        self.modalPresentationStyle = UIModalPresentationPopover;
        self.popoverPresentationController.sourceView = self.view;
        self.preferredContentSize = CGSizeMake(230, 230);
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self;
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadLinks];
}

- (void) loadLinks
{
    NSArray *clubs = [[Data sharedData] clubs][@"clubs"];
    
    titles = [NSMutableArray array];
    links  = [NSMutableArray array];
    imgs   = [NSMutableArray array];
    
    if (clubs.count > 0)
    {
        NSDictionary *club = clubs[0][@"contacts"];
    //for (NSDictionary *club in clubs)
    //{
        //if ([club[@"id"] intValue] == 1)
        //{
            if (club[@"web"] != nil && ![club[@"web"] isEqualToString:@""] && [NSURL URLWithString:club[@"web"]] != nil)
            {
                [titles addObject:SITE_BDE_TITLE];
                [links  addObject:club[@"web"]];
                [imgs   addObject:[[UIImage imageNamed:@"web"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                
                [titles addObject:@"Portail vie asso."];
                [links  addObject:([club[@"web"] hasSuffix:@"/"]) ? [club[@"web"] stringByAppendingString:@"portail"]
                                                                  : [club[@"web"] stringByAppendingString:@"/portail"]];
                [imgs   addObject:[[UIImage imageNamed:@"web"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            if (club[@"mail"] != nil && ![club[@"mail"] isEqualToString:@""] && [NSURL URLWithString:club[@"mail"]] != nil)
            {
                [titles addObject:MAIL_BDE_TITLE];
                [links  addObject:club[@"mail"]];
                [imgs   addObject:[[UIImage imageNamed:@"mail"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            if (club[@"fb"] != nil && ![club[@"fb"] isEqualToString:@""] && [NSURL URLWithString:club[@"fb"]] != nil)
            {
                [titles addObject:@"Facebook"];
                [links  addObject:club[@"fb"]];
                [imgs   addObject:[[UIImage imageNamed:@"fb"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            if (club[@"instagram"] != nil && ![club[@"instagram"] isEqualToString:@""] && [NSURL URLWithString:club[@"instagram"]] != nil)
            {
                [titles addObject:@"Instagram"];
                [links  addObject:club[@"instagram"]];
                [imgs   addObject:[[UIImage imageNamed:@"instagram"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            if (club[@"snap"] != nil && ![club[@"snap"] isEqualToString:@""] && [NSURL URLWithString:club[@"snap"]] != nil)
            {
                [titles addObject:@"Snapchat"];
                [links  addObject:club[@"snap"]];
                [imgs   addObject:[[UIImage imageNamed:@"snap"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            if (club[@"twitter"] != nil && ![club[@"twitter"] isEqualToString:@""] && [NSURL URLWithString:club[@"twitter"]] != nil)
            {
                [titles addObject:@"Twitter"];
                [links  addObject:club[@"twitter"]];
                [imgs   addObject:[[UIImage imageNamed:@"twitter"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            if (club[@"youtube"] != nil && ![club[@"youtube"] isEqualToString:@""] && [NSURL URLWithString:club[@"youtube"]] != nil)
            {
                [titles addObject:@"YouTube"];
                [links  addObject:club[@"youtube"]];
                [imgs   addObject:[[UIImage imageNamed:@"youtube"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            //break;
        //}
    //}
    }
    
    self.tableView.rowHeight = 44;  // iOS 11 dynamic row height disabled
    if ([titles count])
    {
        [self.tableView setBackgroundColor:[UIColor whiteColor]];   // -1 because no separator
        self.preferredContentSize = CGSizeMake(200, ([titles count] * self.tableView.rowHeight) - 1);
        self.tableView.tableFooterView = nil;
        self.tableView.alwaysBounceVertical = YES;
    }
    else
    {
        [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        self.preferredContentSize = CGSizeMake(230, 230);
        self.tableView.tableFooterView = [UIView new];
        self.tableView.alwaysBounceVertical = NO;
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [links count];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView
                  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eseomegaLinkCell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"eseomegaLinkCell"];
    
    cell.textLabel.text  = titles[indexPath.row];
    cell.imageView.image =   imgs[indexPath.row];
    
    return cell;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    
    if ([titles[index] isEqualToString:MAIL_BDE_TITLE])
        [[Data sharedData] mail:links[index] currentVC:self];
    else {
        // Store parent view controller before self becomes nil
        UIViewController *presenting = self.presentingViewController;
        [self dismissViewControllerAnimated:YES completion:^{
            
            if ([titles[index] isEqualToString:@"Instagram"])
                [[Data sharedData] instagram:links[index] currentVC:presenting];
            else if ([titles[index] isEqualToString:@"Snapchat"])
                [[Data sharedData] snapchat:links[index] currentVC:presenting];
            else if ([titles[index] isEqualToString:@"Twitter"])
                [[Data sharedData] twitter:links[index] currentVC:presenting];
            else
                [[Data sharedData] openURL:links[index] currentVC:presenting];
            
        }];
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
        if ([reseau isEqualToString:MAIL_BDE_TITLE] || [reseau isEqualToString:@"Snapchat"])
            return nil;
        else if ([reseau isEqualToString:@"Instagram"])
            url = [NSString stringWithFormat:@"https://instagram.com/%@/", url];
        else if ([reseau isEqualToString:@"Twitter"])
            url = [NSString stringWithFormat:@"https://twitter.com/%@", url];
        
        previewingContext.sourceRect = [self.tableView rectForRowAtIndexPath:index];
        
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:[url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]]
                                                             entersReaderIfAvailable:NO];
        if ([SFSafariViewController instancesRespondToSelector:@selector(preferredBarTintColor)])
        {
            safari.preferredBarTintColor = [UINavigationBar appearance].barTintColor;
            safari.preferredControlTintColor = [UINavigationBar appearance].tintColor;
        }
        return safari;
    }
    return nil;
}

- (void) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
      commitViewController:(UIViewController *)viewControllerToCommit
{
    [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    [[Data sharedData] setT_currentTopVC:nil];
}

#pragma mark - Mail Compose View Controller delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"autreVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Aucun lien BDE";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Vérifiez votre connexion et rafraîchissez l'onglet Clubs.";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIColor *) backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor groupTableViewBackgroundColor];
}

@end
