//
//  SponsorsTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
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

#import "SponsorsTVC.h"

@implementation SponsorsTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 131.;
    self.refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
        (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable))
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(credits) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(loadSponsors) name:@"sponsors" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"debugRefresh" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"sponsorsSent" object:nil];
    
    [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    self.tableView.tableFooterView = [UIView new];
    [self loadSponsors];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.refreshControl endRefreshing];
    
    // Handoff
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.sponsors"];
    activity.title = @"Partenaires BDE ESEO";
    activity.webpageURL = [NSURL URLWithString:URL_ACT_SPON];
    if ([SFSafariViewController class])
    {
        activity.eligibleForSearch = YES;
        activity.eligibleForHandoff = YES;
        activity.eligibleForPublicIndexing = YES;
    }
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void) recupSponsors:(BOOL)forcer
{
    if (!forcer && ![[Data sharedData] shouldUpdateJSON:@"sponsors"])
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"sponsors"];
}

- (void) loadSponsors
{
    sponsors = [[Data sharedData] sponsors][@"sponsors"];
    
    if ([sponsors count])
    {
        [self.tableView setBackgroundColor:[UIColor whiteColor]];
        self.tableView.tableFooterView = nil;
    }
    else
    {
        [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        self.tableView.tableFooterView = [UIView new];
    }
    [self.tableView reloadData];
}

- (IBAction) refresh:(UIRefreshControl *)sender
{
    [self recupSponsors:NO];
}

- (void) credits
{
    CreditsTVC *credits = [[CreditsTVC alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:credits];
    [nc setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:nc animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [sponsors count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView
                 cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    SponsorsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sponsorsCell" forIndexPath:indexPath];
    
    NSDictionary *sponsor = sponsors[indexPath.row];
    cell.nomLabel.text = sponsor[@"nom"];
    cell.descLabel.text = [sponsor[@"detail"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    
    NSString *contact = [[[sponsor[@"url"] stringByReplacingOccurrencesOfString:@"http://"
                                                                     withString:@""] stringByReplacingOccurrencesOfString:@"www." withString:@""] stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    if (![contact isEqualToString:@""] && ![sponsor[@"adr"] isEqualToString:@""])
        contact = [contact stringByAppendingString:@"\n"];
    contact = [contact stringByAppendingString:sponsor[@"adr"]];
    cell.contactLabel.text = contact;
    
    if (sponsor[@"img"] != nil && ![sponsor[@"img"] isEqualToString:@""])
        [cell.logoView sd_setImageWithURL:[NSURL URLWithString:sponsor[@"img"]]
                         placeholderImage:[UIImage imageNamed:@"placeholder"]];
    else
        [cell.logoView setImage:[UIImage imageNamed:@"placeholder"]];
    cell.logoView.layer.cornerRadius = 4;
    cell.logoView.clipsToBounds = YES;
    
    [cell setAvantages:sponsor[@"avantages"]];
    
    [cell setSelectionStyle:([sponsor[@"url"] isEqualToString:@""]) ? UITableViewCellSelectionStyleNone
                                                                    : UITableViewCellSelectionStyleDefault];
    
    return cell;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *url = sponsors[indexPath.row][@"url"];
    if ([url isEqualToString:@""])
        return;
    
    [[Data sharedData] openURL:url currentVC:self];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - 3D Touch

- (UIViewController *) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
               viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *index = [self.tableView indexPathForRowAtPoint:location];
    if (index != nil)
    {
        NSString *url = sponsors[index.row][@"url"];
        if ([url isEqualToString:@""])
            return nil;
        
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
}

#pragma mark - Handoff

- (void) updateUserActivityState:(NSUserActivity *)activity
{
    [super updateUserActivityState:activity];
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"autreVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Aucun partenaire";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Vérifiez votre connexion et tirez pour rafraîchir.";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGPoint) offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2. - 25.5);
}

- (UIColor *) backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor groupTableViewBackgroundColor];
}

#pragma mark - Safari Controller Delegate

- (void) safariViewControllerDidFinish:(nonnull SFSafariViewController *)controller
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

@end