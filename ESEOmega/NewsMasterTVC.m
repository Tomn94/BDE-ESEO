//
//  NewsMasterTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

#import "NewsMasterTVC.h"

@implementation NewsMasterTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    ptr = 1;
    
    NSArray *viewControllers = self.splitViewController.viewControllers;
    if ([viewControllers count] > 1)
    {
        detailNVC = viewControllers[1];
        self.delegate = [detailNVC viewControllers][0];
    }
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    
    [self setUpToolbar];
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(loadNews) name:@"news" object:nil];
    [ctr addObserver:self selector:@selector(debugRefresh) name:@"debugRefresh" object:nil];
    [ctr addObserver:self.tableView.bottomRefreshControl selector:@selector(endRefreshing) name:@"moreNewsSent" object:nil];
    [ctr addObserver:self selector:@selector(hasLoadedMore) name:@"moreNewsOK" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"newsSent" object:nil];
    
    [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    self.tableView.tableFooterView = [UIView new];
    [self loadNews];
    
    if (_delegate && [news count] > 0 && iPAD)
        [_delegate selectedNews:news[0]];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
        (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable))
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    
    // Handoff
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.news"];
    activity.title = @"News BDE ESEO";
    activity.webpageURL = [NSURL URLWithString:URL_ACT_NEWS];
    if ([SFSafariViewController class])
    {
        activity.eligibleForSearch = YES;
        activity.eligibleForHandoff = YES;
        activity.eligibleForPublicIndexing = YES;
    }
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadEmptyDataSet];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Charger les articles récents…"
                                                                            attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRed:0.051 green:0.396 blue:1.000 alpha:1.000] }]];
    
    if (_delegate && [news count] > 0 && !iPAD && [UIScreen mainScreen].bounds.size.width >= 736 && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
        [_delegate selectedNews:news[0]];
    
    if (self.tableView.bottomRefreshControl == nil)
    {
        UIRefreshControl *refreshControl = [UIRefreshControl new];
        //    refreshControl.triggerVerticalOffset = 100.;
        refreshControl.tintColor = self.tableView.tintColor;
        [refreshControl addTarget:self action:@selector(loadMore) forControlEvents:UIControlEventValueChanged];
        [refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Charger les anciens articles…"
                                                                           attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRed:0.051 green:0.396 blue:1.000 alpha:1.000] }]];
        self.tableView.bottomRefreshControl = refreshControl;
    }
    [self.refreshControl beginRefreshing];
    [self debugRefresh];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void) recupNews:(BOOL)forcer
{
    if (!forcer && ![[Data sharedData] shouldUpdateJSON:@"news"])
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"news"];
}

- (void) loadNews
{
    /*NSString *path = [[NSBundle mainBundle] pathForResource:@"news" ofType:@"json"];
    NSData   *data = [NSData dataWithContentsOfFile:path];
    news = nil;
    if (data != nil)
        news = [NSJSONSerialization JSONObjectWithData:data
                                               options:kNilOptions
                                                 error:nil][@"articles"];*/
    
    // Vérifier le besoin
    /*CATransition *animation = [CATransition animation];
    [animation setDuration:0.25f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [animation setType:kCATransitionFade];
    [self.view.layer addAnimation:animation forKey:NULL];*/
    
    news = [[Data sharedData] news][@"articles"];
    if (_delegate && [news count] > 0 && iPAD && [NSDate timeIntervalSinceReferenceDate] - [[Data sharedData] launchTime] < 30)
        [_delegate selectedNews:news[0]];
    
    if ([news count])
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

#pragma mark Toolbar

- (void) setUpToolbar
{
    popoverVisible = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(-0.5, 0, 0, 0);
    
    UIView *header = [UIView new];
    header.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 64);
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    header.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    UIView *border = [UIView new];
    border.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    border.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 0.33);
    border.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:border];
    
    UILabel *headerHeader = [UILabel new];
    headerHeader.text = @"LIENS RAPIDES";
    headerHeader.font = [UIFont systemFontOfSize:11];
    headerHeader.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    headerHeader.frame = CGRectMake(4, 0, 100, 20);
    [header addSubview:headerHeader];
    
    NSMutableArray *boutons = [NSMutableArray array];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseoPortail"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(portail)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseoCampus"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(campus)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseoMails"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(mails)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseo"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(eseo)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseoProjets"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(projets)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    eseomegaBarItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseomega"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(eseomega)];
    [boutons addObject:eseomegaBarItem];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    /*
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
        (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable))
    {
        [self registerForPreviewingWithDelegate:self sourceView:[((UIBarButtonItem *)boutons[1]) valueForKey:@"view"]];
        [self registerForPreviewingWithDelegate:self sourceView:[((UIBarButtonItem *)boutons[3]) valueForKey:@"view"]];
        [self registerForPreviewingWithDelegate:self sourceView:[((UIBarButtonItem *)boutons[4]) valueForKey:@"view"]];
        [self registerForPreviewingWithDelegate:self sourceView:[((UIBarButtonItem *)boutons[5]) valueForKey:@"view"]];
        [self registerForPreviewingWithDelegate:self sourceView:[((UIBarButtonItem *)boutons[7]) valueForKey:@"view"]];
        [self registerForPreviewingWithDelegate:self sourceView:[((UIBarButtonItem *)boutons[9]) valueForKey:@"view"]];
    }*/
    
    toolbar = [UIToolbar new];
    [toolbar setFrame:CGRectMake(0, 16, self.tableView.frame.size.width, 48)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [toolbar setDelegate:self];
    [toolbar setItems:boutons];
    [toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [header addSubview:toolbar];
    self.tableView.tableHeaderView = header;
}

- (void) portail
{
    if (popoverVisible)
    {
        popoverVisible = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            [[Data sharedData] openURL:URL_PORTAIL currentVC:self];
        }];
        return;
    }
    
    [[Data sharedData] openURL:URL_PORTAIL currentVC:self];
}

- (void) campus
{
    if (popoverVisible)
    {
        popoverVisible = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            [[Data sharedData] openURL:URL_CAMPUS currentVC:self];
        }];
        return;
    }
    
    [[Data sharedData] openURL:URL_CAMPUS currentVC:self];
}

- (void) mails
{
    if (popoverVisible)
    {
        popoverVisible = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            [[Data sharedData] openURL:URL_MAIL currentVC:self];
        }];
        return;
    }
    
    [[Data sharedData] openURL:URL_MAIL currentVC:self];
}

- (void) eseo
{
    if (popoverVisible)
    {
        popoverVisible = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            [[Data sharedData] openURL:URL_ESEO currentVC:self];
        }];
        return;
    }
    
    [[Data sharedData] openURL:URL_ESEO currentVC:self];
}

- (void) projets
{
    if (popoverVisible)
    {
        popoverVisible = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            [[Data sharedData] openURL:URL_PROJETS currentVC:self];
        }];
        return;
    }
    
    [[Data sharedData] openURL:URL_PROJETS currentVC:self];
}

- (void) eseomega
{
    NewsLinksVC *pop = [NewsLinksVC new];
    pop.popoverPresentationController.barButtonItem = eseomegaBarItem;
    pop.popoverPresentationController.delegate = self;
    
    /*if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
        (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable))
    {
        [self registerForPreviewingWithDelegate:pop sourceView:pop.tableView];
        [[Data sharedData] setT_currentTopVC:self];
    }*/
    
    [self presentViewController:pop animated:YES completion:^{
        popoverVisible = YES;
    }];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [news count];
}


- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView
                  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsMasterCell" forIndexPath:indexPath];
    
    NSDictionary *article = news[indexPath.row];
    NSString *titre = [article[@"titre"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *contenuFormat = [article[@"resume"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"  +"
                                                                           options:NSRegularExpressionCaseInsensitive error:nil];
    if (titre)
        [cell.textLabel setText:[regex stringByReplacingMatchesInString:titre options:0
                                                                  range:NSMakeRange(0, [titre length])
                                                           withTemplate:@" "]];
    else
        cell.textLabel.text = nil;
    if (contenuFormat)
    {
        NSString *tempText = [regex stringByReplacingMatchesInString:contenuFormat options:0
                                                               range:NSMakeRange(0, [contenuFormat length])
                                                        withTemplate:@" "];
        tempText = [tempText stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        tempText = [tempText stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        [cell.detailTextLabel setText:tempText];
    }
    else
        cell.detailTextLabel.text = nil;
    
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    if (article[@"img"] != nil && ![article[@"img"] isEqualToString:@""])
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:article[@"img"]]
                          placeholderImage:[UIImage imageNamed:@"placeholder"]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                     if (error == nil) {
                                         cell.imageView.image = [Data imageByScalingAndCroppingForSize:image
                                                                                                    to:CGSizeMake(90, 44)
                                                                                                retina:YES];
                                     }
                                 }];
    else
        [cell.imageView setImage:nil];
    
    return cell;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [self openWithInfos:news[indexPath.row]];
}

- (void) openWithInfos:(NSDictionary *)infosNews
{
    if (_delegate)
    {
        [self.splitViewController showDetailViewController:detailNVC sender:nil];
        [_delegate selectedNews:infosNews];
    }
}

#pragma mark Refresh spin

- (IBAction) refresh:(UIRefreshControl *)sender
{
    if (self.tableView.bottomRefreshControl.isRefreshing)
    {
        [sender endRefreshing];
        return;
    }
    
    [self recupNews:NO];
}

- (void) loadMore
{
    if (self.refreshControl.isRefreshing)
    {
        [self.tableView.bottomRefreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"news" options:ptr];
}

- (void) hasLoadedMore
{
    ptr++;
    [self.tableView.bottomRefreshControl endRefreshing];
}

- (void) debugRefresh
{
    [self.refreshControl endRefreshing];
    [self.tableView.bottomRefreshControl beginRefreshing];
    [self.tableView.bottomRefreshControl endRefreshing];
}

- (IBAction) salles:(nullable id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Salles" bundle:nil];
    UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"Salles"];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction) ingenews:(nullable id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"IngeNews" bundle:nil];
    UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"IngeNews"];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Pop over delegate

- (BOOL) popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    popoverVisible = NO;
    return YES;
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

#pragma mark - 3D Touch

- (UIViewController *) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
               viewControllerForLocation:(CGPoint)location
{/*
    CGRect rect;
    NSInteger index = 0;
    for (NSInteger i = 1 ; i < 10 ; i += 2)
    {
        rect = [toolbar.subviews[i] convertRect:toolbar.subviews[i].bounds toView:self.tableView];
        if (CGRectContainsPoint(rect, location))
        {
            index = i;
            break;
        }
    }
    if (index == 0)
    {
        previewingContext.sourceRect = rect;
        
        NSString *url = @"https://portail.eseo.fr";
        if (index == 3)
            url = @"http://campus.eseo.fr";
        else if (index == 5)
            url = @"http://mail.office365.com";
        else if (index == 7)
            url = @"http://www.eseo.fr";
        else if (index == 9)
            url = @"http://www.projets.eseo.fr";
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]
                                                             entersReaderIfAvailable:NO];
        safari.delegate = self;
        return safari;
    }
    return nil;*/
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (indexPath != nil)
    {
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        NewsDetailVC *destinationViewController = [sb instantiateViewControllerWithIdentifier:@"newsDetailVC"];
        
        destinationViewController.infos = news[indexPath.row];
        
        previewingContext.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
        
        [[Data sharedData] setT_currentTopVC:self];
        
        return destinationViewController;
    }
    
//    [self.splitViewController showDetailViewController:detailNVC sender:nil];
//    [_delegate selectedNews:infosNews];
    return nil;
}

- (void) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
      commitViewController:(UIViewController *)viewControllerToCommit
{
    if (_delegate)
    {
        [self.splitViewController showDetailViewController:viewControllerToCommit sender:nil];
        [_delegate selectedNews:((NewsDetailVC *)viewControllerToCommit).infos];
        [[Data sharedData] setT_currentTopVC:nil];
    }
}

#pragma mark - Handoff

- (void) updateUserActivityState:(NSUserActivity *)activity
{
    [super updateUserActivityState:activity];
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"newsVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Aucune news";
    
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
    return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2. + 7.5);
}

- (UIColor *) backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor groupTableViewBackgroundColor];
}

#pragma mark - Mail Compose View Controller delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Safari Controller Delegate

- (void) safariViewControllerDidFinish:(nonnull SFSafariViewController *)controller
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

#pragma mark - Tool Bar Delegate

- (UIBarPosition) positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

@end
