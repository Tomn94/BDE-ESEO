//
//  NewsMasterTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 21/07/2015.
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

#import "NewsMasterTVC.h"
#import "BDE_ESEO-Swift.h"

@implementation NewsMasterTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    ptr = 1;
    isLoadingMoreContent = NO;
    
    NSArray *viewControllers = self.splitViewController.viewControllers;
    if ([viewControllers count] > 1)
    {
        detailNVC = viewControllers[1];
        self.delegate = [detailNVC viewControllers][0];
    }
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    if ([NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}]) {
        self.tableView.prefetchDataSource = self;
    }
    
    [self setUpToolbar];
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(loadNews) name:@"news" object:nil];
    [ctr addObserver:self selector:@selector(debugRefresh) name:@"debugRefresh" object:nil];
    [ctr addObserver:self selector:@selector(endBottomRefresh) name:@"moreNewsSent" object:nil];
    [ctr addObserver:self selector:@selector(hasLoadedMore) name:@"moreNewsOK" object:nil];
    [ctr addObserver:self selector:@selector(updateToolbarIcon) name:@"themeUpdated" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"newsSent" object:nil];
    
    [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    self.tableView.tableFooterView = [UIView new];
    [self loadNews];
    
    if (_delegate && [news count] > 0 && iPAD)
        [_delegate selectedNews:news[0]];
    
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    
    // Handoff
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.news"];
    activity.title = @"News BDE ESEO";
    activity.webpageURL = [NSURL URLWithString:URL_ACT_NEWS];
    activity.eligibleForSearch = YES;
    activity.eligibleForHandoff = YES;
    activity.eligibleForPublicIndexing = YES;
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
    
    [self.tableView reloadEmptyDataSet];
    self.refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Charger les articles récents…"
                                                                            attributes:@{ NSForegroundColorAttributeName: [UINavigationBar appearance].barTintColor }]];
    
    /* Use Large Title on iOS 11 */
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
        self.refreshControl.tintColor = [UIColor whiteColor];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    
    if (_delegate && [news count] > 0 && !iPAD && [UIScreen mainScreen].bounds.size.width >= 736 && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
        [_delegate selectedNews:news[0]];
    
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
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseoMails"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(mails)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseo"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(eseo)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseoPortail"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(portail)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseoCampus"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(campus)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"dreamspark"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(dreamspark)]];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    eseomegaBarItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"eseomega"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(eseomega)];
    [boutons addObject:eseomegaBarItem];
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [self updateToolbarIcon];
    /*
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
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

/**
 Updates the image of Students’ Union button according to the theme.
 Gets the theme icon and applies a rounded rect mask.
 */
- (void) updateToolbarIcon
{
    if (eseomegaBarItem == nil)
        return;
    
    /* Image size constants */
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(40, 40);
    
    /* Create context */
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef mainViewContentContext = CGBitmapContextCreate(NULL, targetSize.width * scale, targetSize.height * scale, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if (mainViewContentContext == NULL)
        return;
    
    /* Get image and its mask on disk */
    int themeNumber    = (int)[ThemeManager objc_currentTheme];
    UIImage *image     = [UIImage imageNamed:[NSString stringWithFormat:@"App-Icon-%d", themeNumber]];
    UIImage *maskImage = [UIImage imageNamed:@"eseo"];
    
    /* Draw image and mask */
    CGRect targetRect = CGRectMake(0, 0, targetSize.width * scale, targetSize.height * scale);
    CGContextClipToMask(mainViewContentContext, targetRect, maskImage.CGImage);
    CGContextDrawImage (mainViewContentContext, targetRect, image.CGImage);

    /* Get result back */
    CGImageRef newImage = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    
    /* Set masked image to the button */
    UIImage *finalImage = [Data scaleAndCropImage:[UIImage imageWithCGImage:newImage] toSize:targetSize retina:YES];
    eseomegaBarItem.image = [finalImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    CGImageRelease(newImage);
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

- (void) dreamspark
{
    if (popoverVisible)
    {
        popoverVisible = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            [[Data sharedData] openURL:URL_DREAMSP currentVC:self];
        }];
        return;
    }
    
    [[Data sharedData] openURL:URL_DREAMSP currentVC:self];
}

- (void) eseomega
{
    NewsLinksVC *pop = [NewsLinksVC new];
    pop.popoverPresentationController.barButtonItem = eseomegaBarItem;
    pop.popoverPresentationController.delegate = self;
    
    /*if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
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
    return [news count] + 1;
}


- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView
                  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.row == news.count) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsMasterMoreCell"];
        if (isLoadingMoreContent)
            [((NewsMasterMoreCell *)cell).refresh startAnimating];
        else
            [((NewsMasterMoreCell *)cell).refresh stopAnimating];
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsMasterCell" forIndexPath:indexPath];
    
    NSDictionary *article = news[indexPath.row];
    NSString *titre = [article[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *contenuFormat = [article[@"preview"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
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
        tempText = [tempText stringByReplacingOccurrencesOfString:@"&lsquo;" withString:@"‘"];
        tempText = [tempText stringByReplacingOccurrencesOfString:@"&rsquo;" withString:@"’"];
        NSArray *codes = [NSArray arrayWithObjects:
                          @"&nbsp;", @"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
                          @"&sect;", @"&uml;", @"&copy;", @"&ordf;", @"&laquo;", @"&not;", @"&shy;", @"&reg;",
                          @"&macr;", @"&deg;", @"&plusmn;", @"&sup2;", @"&sup3;", @"&acute;", @"&micro;",
                          @"&para;", @"&middot;", @"&cedil;", @"&sup1;", @"&ordm;", @"&raquo;", @"&frac14;",
                          @"&frac12;", @"&frac34;", @"&iquest;", @"&Agrave;", @"&Aacute;", @"&Acirc;",
                          @"&Atilde;", @"&Auml;", @"&Aring;", @"&AElig;", @"&Ccedil;", @"&Egrave;",
                          @"&Eacute;", @"&Ecirc;", @"&Euml;", @"&Igrave;", @"&Iacute;", @"&Icirc;", @"&Iuml;",
                          @"&ETH;", @"&Ntilde;", @"&Ograve;", @"&Oacute;", @"&Ocirc;", @"&Otilde;", @"&Ouml;",
                          @"&times;", @"&Oslash;", @"&Ugrave;", @"&Uacute;", @"&Ucirc;", @"&Uuml;", @"&Yacute;",
                          @"&THORN;", @"&szlig;", @"&agrave;", @"&aacute;", @"&acirc;", @"&atilde;", @"&auml;",
                          @"&aring;", @"&aelig;", @"&ccedil;", @"&egrave;", @"&eacute;", @"&ecirc;", @"&euml;",
                          @"&igrave;", @"&iacute;", @"&icirc;", @"&iuml;", @"&eth;", @"&ntilde;", @"&ograve;",
                          @"&oacute;", @"&ocirc;", @"&otilde;", @"&ouml;", @"&divide;", @"&oslash;", @"&ugrave;",
                          @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;", nil];
        NSUInteger i, count = [codes count];
        for (i = 0; i < count; i++)
            tempText = [tempText stringByReplacingOccurrencesOfString:codes[i]
                                                           withString:[NSString stringWithFormat:@"%C", (unsigned short) (160 + i)]];
        
        
        [cell.detailTextLabel setText:tempText];
    }
    else
        cell.detailTextLabel.text = nil;
    
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    if (article[@"img"] != nil && article[@"img"] != [NSNull null] && ![article[@"img"] isEqualToString:@""])
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:article[@"img"]]
                          placeholderImage:[UIImage imageNamed:@"placeholder"]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                     if (error == nil) {
                                         cell.imageView.image = [Data scaleAndCropImage:image
                                                                                 toSize:CGSizeMake(90, 44)
                                                                                 retina:YES];
                                     }
                                 }];
    else
        [cell.imageView setImage:[UIImage imageNamed:@"placeholder"]];
    
    return cell;
}

#pragma mark - Table view data source prefetching

/**
 Prepare data (news image) at specified index paths
 
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
        if (indexPath.row != news.count)
        {
            NSString *imgURL = news[indexPath.row][@"img"];
            if (imgURL != nil && ![imgURL isEqualToString:@""])
                [thumbnails addObject:[NSURL URLWithString:imgURL]];
        }
    }
    
    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:thumbnails];
}

#pragma mark - Table view delegate

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.row == news.count)
    {
        [self startBottomRefresh];
        [self loadMore];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
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
    if ([self isBottomRefreshing])
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
        [self endBottomRefresh];
        return;
    }
    
    [[Data sharedData] updateJSON:@"news" options:ptr];
    
    if ([NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}]) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
}

- (void) hasLoadedMore
{
    ptr++;
    [self endBottomRefresh];
}

- (BOOL) isBottomRefreshing
{
    NewsMasterMoreCell *cell = (NewsMasterMoreCell *)[self tableView:self.tableView
                                               cellForRowAtIndexPath:[NSIndexPath indexPathForRow:news.count
                                                                                        inSection:0]];
    return cell.refresh.isAnimating;
}

- (void) startBottomRefresh
{
    NSIndexPath   *indexPath = [NSIndexPath indexPathForRow:news.count inSection:0];
    NewsMasterMoreCell *cell = (NewsMasterMoreCell *)[self tableView:self.tableView
                                               cellForRowAtIndexPath:indexPath];
    isLoadingMoreContent = YES;
    [cell.refresh startAnimating];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) endBottomRefresh
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSIndexPath   *indexPath = [NSIndexPath indexPathForRow:news.count inSection:0];
        NewsMasterMoreCell *cell = (NewsMasterMoreCell *)[self tableView:self.tableView
                                                   cellForRowAtIndexPath:indexPath];
        isLoadingMoreContent = NO;
        [cell.refresh stopAnimating];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void) debugRefresh
{
    [self.refreshControl endRefreshing];
}

- (IBAction) salles:(nullable id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Salles" bundle:nil];
    UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"Salles"];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction) genealogy:(nullable id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Genealogy" bundle:nil];
    UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"Genealogy"];
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
    if (indexPath != nil && indexPath.row != news.count)
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

#pragma mark - Tool Bar Delegate

- (UIBarPosition) positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

@end


@implementation NewsMasterMoreCell
@end
