//
//  ClubsDetailNVC.m
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

#import "ClubsDetailTVC.h"

@implementation ClubsDetailTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    /* JSON key, UI Name, 3D Touch peek action, selector */
    contactModes  = @[ @[@"web",       @"Site",      PREVIEW_ACTION_BLOCK { [self site]; },      @"site"],
                       @[@"fb",        @"Facebook",  PREVIEW_ACTION_BLOCK { [self facebook]; },  @"facebook"],
                       @[@"twitter",   @"Twitter",   PREVIEW_ACTION_BLOCK { [self twitter]; },   @"twitter"],
                       @[@"youtube",   @"YouTube",   PREVIEW_ACTION_BLOCK { [self youtube]; },   @"youtube"],
                       @[@"snap",      @"Snapchat",  PREVIEW_ACTION_BLOCK { [self snapchat]; },  @"snapchat"],
                       @[@"instagram", @"Instagram", PREVIEW_ACTION_BLOCK { [self instagram]; }, @"instagram"],
                       @[@"linkedin",  @"LinkedIn",  PREVIEW_ACTION_BLOCK { [self linkedin]; },  @"linkedin"],
                       @[@"mail",      @"Mail…",     PREVIEW_ACTION_BLOCK { [self mail]; },      @"mail"],
                       @[@"tel",       @"Appeler…",  PREVIEW_ACTION_BLOCK { [self tel]; },       @"tel"] ];
    
    self.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
    self.navigationItem.leftItemsSupplementBackButton = true;
    self.tableView.backgroundColor = [UIColor colorWithRed:248/255. green:248/255. blue:248/255. alpha:1];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotatePic)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];

}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) selectedClub:(nonnull NSDictionary *)infos
{
    self.infos = infos;
    [self loadPic];
    [[Data sharedData] setT_currentTopVC:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadPic];
    [self getDetailData];
}

- (NSArray<id<UIPreviewActionItem>> *) previewActionItems
{
    /* Online club data */
    NSDictionary *contacts = _infos[@"contacts"];
    
    /* Add a peek action for each available method */
    NSMutableArray *array = [NSMutableArray array];
    for (NSArray *contactMode in contactModes)
        if (contacts[contactMode[0]] != nil && ![contacts[contactMode[0]] isEqualToString:@""])
            [array addObject:[UIPreviewAction actionWithTitle:contactMode[1]
                                                        style:UIPreviewActionStyleDefault
                                                      handler:contactMode[2]]];
    
    return [array copy];
}

#pragma mark - Actions

- (void) loadPic
{
    [self.titleImageView removeFromSuperview];
    [self.blurImageView removeFromSuperview];
    [self.contentView removeFromSuperview];
    
    self.offsetBase = self.tableView.contentOffset.y;
    
    [self configureBannerWithImage:[UIImage imageNamed:@"placeholder"]];
    if (_infos[@"img"] != nil && ![_infos[@"img"] isEqualToString:@""])
        [self configureBannerWithURL:[NSURL URLWithString:_infos[@"img"]]];

    [self loadClub];
}

- (void) loadClub
{
    if (_infos[@"name"] == nil)
        return;
    
    self.title = _infos[@"name"];
    
    [self.tableView reloadData];
    
    /* Description pane */
    CGRect frame = self.contentView.bounds;
    frame.origin.x += 10;
    frame.origin.y -= 15;
    frame.size.width -= 20;
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.font = [UIFont systemFontOfSize:15];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [_infos[@"description"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHeaderClub)];
    [label addGestureRecognizer:tap];
    [self.contentView addSubview:label];
    
    /* Contact bar buttons */
    NSMutableArray *buttons = [NSMutableArray array];
    NSDictionary *contacts = _infos[@"contacts"];
    for (NSArray *contactMode in contactModes)
    {
        if (contacts[contactMode[0]] != nil && ![contacts[contactMode[0]] isEqualToString:@""])
        {
            [buttons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil action:nil]];
            [buttons addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:contactMode[0]]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:NSSelectorFromString(contactMode[3])]];
        }
    }
    [buttons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                     target:nil action:nil]];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.contentView.frame.size.height - 44, self.contentView.frame.size.width, 44)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [toolbar setDelegate:self];
    [toolbar setItems:buttons];
    [toolbar setBarStyle:UIBarStyleBlack];
    [toolbar setTranslucent:YES];
    [toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    toolbar.layer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.42].CGColor;
    [self.contentView addSubview:toolbar];
    
    /* Handoff */
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.clubs"];
    activity.title = @"Clubs & BDE ESEO";
    activity.webpageURL = [NSURL URLWithString:URL_ACT_CLUB];
    if ([SFSafariViewController class])
    {
        activity.eligibleForSearch = YES;
        activity.eligibleForHandoff = YES;
        activity.eligibleForPublicIndexing = YES;
    }
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
}

- (void) getDetailData
{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:[URL_JSONS stringByAppendingString:@"/%d"],
                                       @"clubs", (int)arc4random_uniform(9999), [_infos[@"id"] intValue]]];
    
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:url
                                                   completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          if (error == nil && data != nil)
                                          {
                                              NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                                   options:kNilOptions
                                                                                                     error:nil];
                                              
                                              NSMutableDictionary *infos = [_infos mutableCopy];
                                              [infos addEntriesFromDictionary:JSON];
                                              _infos = [infos copy];
                                              
                                              [self.tableView reloadData];
                                          }

                                      }];
    [dataTask resume];
    [[Data sharedData] updLoadingActivity:YES];
}

- (void) rotatePic
{
    UIImage *precImage = self.titleImageView.image;
    if (precImage == nil)
        return;
    
    [self.titleImageView removeFromSuperview];
    [self.blurImageView removeFromSuperview];
    [self.contentView removeFromSuperview];
    
    self.offsetBase = self.tableView.contentOffset.y;
    
    [self configureBannerWithImage:precImage];
    [self loadClub];
}

- (void) tapHeaderClub
{
    if (self.titleImageView == nil || self.titleImageView.image == nil)
        return;
    
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    imageInfo.image = self.titleImageView.image;
    imageInfo.referenceRect = self.titleImageView.bounds;
    imageInfo.referenceView = self.titleImageView;
    
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc] initWithImageInfo:imageInfo
                                                                                       mode:JTSImageViewControllerMode_Image
                                                                            backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled | JTSImageViewControllerBackgroundOption_Blurred];
    
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

#pragma mark Toolbar actions

- (void) site
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] openURL:_infos[@"contacts"][@"web"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] openURL:_infos[@"contacts"][@"web"] currentVC:self];
}

- (void) facebook
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] openURL:_infos[@"contacts"][@"fb"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] openURL:_infos[@"contacts"][@"fb"] currentVC:self];
}

- (void) twitter
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] twitter:_infos[@"contacts"][@"twitter"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] twitter:_infos[@"contacts"][@"twitter"] currentVC:self];
}

- (void) youtube
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] openURL:_infos[@"contacts"][@"youtube"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] openURL:_infos[@"contacts"][@"youtube"] currentVC:self];
}

- (void) snapchat
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] snapchat:_infos[@"contacts"][@"snap"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] snapchat:_infos[@"contacts"][@"snap"] currentVC:self];
}

- (void) instagram
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] instagram:_infos[@"contacts"][@"instagram"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] instagram:_infos[@"contacts"][@"instagram"] currentVC:self];
}

- (void) linkedin
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] openURL:_infos[@"contacts"][@"linkedin"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] openURL:_infos[@"contacts"][@"linkedin"] currentVC:self];
}

- (void) mail
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] mail:_infos[@"contacts"][@"mail"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] mail:_infos[@"contacts"][@"mail"] currentVC:self];
}

- (void) tel
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] tel:_infos[@"contacts"][@"tel"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] tel:_infos[@"contacts"][@"tel"] currentVC:self];
}

#pragma mark - Mail Compose View Controller delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table controller delegate

- (NSInteger) numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    /* ESEOmega: Crews */
    if (_infos[@"modules"] != nil)
        return [_infos[@"modules"] count];
    
    /* ESEOasis: Board, News & Events */
    return 3;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    /* ESEOmega: Crews */
    if (_infos[@"modules"] != nil)
        return [_infos[@"modules"][section][@"membres"] count];
    
    /* ESEOasis: Board, News & Events */
    if (section == 0)
        return MAX([_infos[@"bureau"] count], 1);
    else if (section == 1)
        return MAX([_infos[@"related"] count], 1);
    else if (section == 2)
        return MAX([_infos[@"events"] count], 1);
    
    return 0;
}

- (nullable NSString *) tableView:(nonnull UITableView *)tableView
          titleForHeaderInSection:(NSInteger)section
{
    /* ESEOmega: Crews */
    if (_infos[@"modules"] != nil)
        return _infos[@"modules"][section][@"nomModule"];
    
    /* ESEOasis: Board, News & Event */
    if (section == 0)
        return @"Bureau";
    else if (section == 1)
        return @"News liées";
    else if (section == 2)
        return @"Événements liés";
    
    return nil;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView
                  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"clubsDetailCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    /* Crew(s) */
    if (_infos[@"modules"] != nil || indexPath.section == 0)
    {
        /* Whether ESEOmega or ESEOasis API is used */
        BOOL eseomega = _infos[@"modules"] != nil;
        
        /* Get data */
        if (!eseomega && [_infos[@"bureau"] count] == 0)
        {
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"\tInformation non disponible";
            cell.imageView.image = nil;
            return cell;
        }
        NSDictionary *membre = (eseomega) ? _infos[@"modules"][indexPath.section][@"membres"][indexPath.row]
                                          : _infos[@"bureau"][indexPath.row];
        
        /* Labels */
        cell.textLabel.text = membre[(eseomega) ? @"nom" : @"name"];
        cell.detailTextLabel.text = membre[(eseomega) ? @"detail" : @"role"];
        
        /* Image */
        [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
        if (membre[@"img"] != nil && ![membre[@"img"] isEqualToString:@""])
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:membre[@"img"]]
                              placeholderImage:[UIImage imageNamed:@"placeholder2"]];
        else
            [cell.imageView setImage:nil];
    }
    else
    {
        NSInteger section = indexPath.section;
        
        /* Get data */
        NSDictionary *infos;
        if (section == 1)
        {
            if ([_infos[@"related"] count] == 0)
            {
                cell.textLabel.text = @"";
                cell.detailTextLabel.text = @"\tAucun article lié au club";
                cell.imageView.image = nil;
                return cell;
            }
            infos = _infos[@"related"][indexPath.row];
        }
        else if (section == 2)
        {
            if ([_infos[@"related"] count] == 0)
            {
                cell.textLabel.text = @"";
                cell.detailTextLabel.text = @"\tAucun événement lié au club";
                cell.imageView.image = nil;
                return cell;
            }
            infos = _infos[@"events"][indexPath.row];
        }
        else
        {
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
            cell.imageView.image = nil;
            return cell;
        }
        
        /* Labels */
        cell.textLabel.text = infos[@"title"];
        
        NSDateFormatter *df = [NSDateFormatter new];
        [df setDateFormat:JSON_DATE_FORMAT];
        NSDate *date = [df dateFromString:infos[@"date"]];
        NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
        NSString *dateTxt = [NSDateFormatter localizedStringFromDate:date
                                                           dateStyle:NSDateFormatterFullStyle
                                                           timeStyle:(dc.hour != 0 || dc.minute != 2) ? NSDateFormatterShortStyle : NSDateFormatterNoStyle];
        cell.detailTextLabel.text = dateTxt;
        
        /* Icon */
        cell.imageView.contentMode = UIViewContentModeCenter;
        cell.imageView.image = [[UIImage imageNamed:(section == 1) ? @"news" : @"events"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    return cell;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    /* ESEOasis: News & Events */
    if (_infos[@"modules"] == nil)
    {
        if (indexPath.section == 1 && [_infos[@"related"] count])
        {
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            NewsDetailVC *articleVC = [sb instantiateViewControllerWithIdentifier:@"newsDetailVC"];
            articleVC.infos = _infos[@"related"][indexPath.row];
            [self presentViewController:articleVC animated:YES completion:nil];
        }
        else if (indexPath.section == 2 && [_infos[@"events"] count])
        {
            NSDictionary *eventsData = _infos[@"events"][indexPath.row];
            CustomIOSAlertView *alert = [EventsTVC popUp:eventsData
                                              inDelegate:self];
            [alert setButtonTitles:[EventsTVC boutonsPopUp:eventsData]];
            [alert setUseMotionEffects:YES];
            [alert show];
        }
    }
}

#pragma mark - CustomIOSAlertView

- (void) customIOS7dialogButtonTouchUpInside:(CustomIOSAlertView *)alertView
                        clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [alertView close];
    
    if (![[alertView buttonTitles][buttonIndex] isEqualToString:DEFAULT_BTN])
    {
        // TODO: Pop-up action buttons
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Action non supportée"
                                                                       message:@"Réessayez d'afficher cet événement depuis l'onglet Events"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Tool Bar Delegate

- (UIBarPosition) positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

#pragma mark - Handoff

- (void) updateUserActivityState:(NSUserActivity *)activity
{
    [super updateUserActivityState:activity];
}

@end
