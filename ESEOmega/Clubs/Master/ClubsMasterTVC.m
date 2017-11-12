//
//  ClubsMasterTVC.m
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

#import "ClubsMasterTVC.h"

@implementation ClubsMasterTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *viewControllers = self.splitViewController.viewControllers;
    if ([viewControllers count] > 1)
    {
        detailNVC = viewControllers[1];
        self.delegate = [detailNVC viewControllers][0];
    }
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    if (@available(iOS 10.0, *)) {
        self.tableView.prefetchDataSource = self;
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    
    /* Use Large Title on iOS 11 */
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
        self.refreshControl.tintColor = [UIColor whiteColor];
    } else {
        [ctr addObserver:self.refreshControl selector:@selector(endRefreshing)
                    name:@"debugRefresh" object:nil];
    }
    
    [ctr addObserver:self selector:@selector(loadClubs) 
                name:@"clubs" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing)
                name:@"clubsSent" object:nil];
    
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    
    [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    self.tableView.tableFooterView = [UIView new];
    [self loadClubs];
    
    if (_delegate && [clubs count] > 0 && iPAD)
        [_delegate selectedClub:clubs[0]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadEmptyDataSet];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self.refreshControl endRefreshing];
    
    if (_delegate && [clubs count] > 0 && !iPAD && [UIScreen mainScreen].bounds.size.width >= 736 && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
        [_delegate selectedClub:clubs[0]];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (IBAction) refresh:(UIRefreshControl *)sender
{
    [self recupClubs:NO];
}

- (void) recupClubs:(BOOL)forcer
{
    if (!forcer && ![[Data sharedData] shouldUpdateJSON:@"clubs"])
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"clubs"];
}

- (void) loadClubs
{
    clubs = [[Data sharedData] clubs][@"clubs"];
    
    if (_delegate && [clubs count] > 0 && iPAD && [NSDate timeIntervalSinceReferenceDate] - [[Data sharedData] launchTime] < 30)
        [_delegate selectedClub:clubs[0]];
    
    if ([clubs count])
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

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [clubs count];
}


- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView
                  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    ClubsMasterCell *cell = [tableView dequeueReusableCellWithIdentifier:@"clubsMasterCell" forIndexPath:indexPath];
    
    cell.titreLabel.layer.shadowRadius = 4;
    cell.titreLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.titreLabel.layer.shadowOffset = CGSizeMake(0, 0);
    cell.titreLabel.layer.shadowOpacity = 1;
    cell.detailLabel.layer.shadowRadius = 3;
    cell.detailLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.detailLabel.layer.shadowOffset = CGSizeMake(0, 0);
    cell.detailLabel.layer.shadowOpacity = 1;
    
    NSDictionary *club = clubs[indexPath.row];
    cell.titreLabel.text = club[@"name"];
    cell.detailLabel.text = club[@"description"];
    
    if (club[@"img"] != nil && ![club[@"img"] isEqualToString:@""])
        [cell.imgView sd_setImageWithURL:club[@"img"]
                        placeholderImage:[UIImage imageNamed:@"placeholder"]];
    else
        [cell.imgView setImage:[UIImage imageNamed:@"placeholder"]];
    
    [cell cellOnTableView:tableView didScrollOnView:self.view.superview];
    
    return cell;
}

#pragma mark - Table view data source prefetching

/**
 Prepare data (club image) at specified index paths
 
 @param tableView This table view
 @param indexPath Position of the cells to preload
 */
- (void)       tableView:(UITableView *)tableView
prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    /* Get every image URL to fetch */
    NSMutableArray *thumbnails = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths)
    {
        NSString *imgURL = clubs[indexPath.row][@"img"];
        if (imgURL != nil && ![imgURL isEqualToString:@""])
            [thumbnails addObject:[NSURL URLWithString:imgURL]];
    }
    
    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:thumbnails];
}

#pragma mark - Table view delegate

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (_delegate)
    {
        [_delegate selectedClub:clubs[indexPath.row]];
        [self.splitViewController showDetailViewController:detailNVC sender:nil];
    }
}

#pragma mark - Scroll view delegate

- (void) scrollViewDidScroll:(nullable UIScrollView *)scrollView
{
    if ([[NSProcessInfo processInfo] isLowPowerModeEnabled])
        return;
    
    NSArray *visibleCells = [self.tableView visibleCells];
    
    for (ClubsMasterCell *cell in visibleCells)
        [cell cellOnTableView:self.tableView didScrollOnView:self.view.superview];
}

#pragma mark - 3D Touch

- (UIViewController *) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
               viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (indexPath != nil)
    {
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ClubsDetailTVC *destinationViewController = [sb instantiateViewControllerWithIdentifier:@"clubsDetailTVC"];
        
        destinationViewController.infos = clubs[indexPath.row];
        
        previewingContext.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
        
        [[Data sharedData] setT_currentTopVC:self];
        
        return destinationViewController;
    }
    
    return nil;
}

- (void) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
      commitViewController:(UIViewController *)viewControllerToCommit
{
    if (_delegate)
    {
        [self.splitViewController showDetailViewController:viewControllerToCommit sender:nil];
        [_delegate selectedClub:((ClubsDetailTVC *)viewControllerToCommit).infos];
        [[Data sharedData] setT_currentTopVC:nil];
    }
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
    return [UIImage imageNamed:@"clubsVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Aucun club";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Les clubs seront bientôt de retour,\nle BDE y travaille.";
    
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
    return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2. - 65);
}

- (UIColor *) backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor groupTableViewBackgroundColor];
}

@end
