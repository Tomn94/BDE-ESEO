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
    
    self.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
    self.navigationItem.leftItemsSupplementBackButton = true;
    self.tableView.backgroundColor = [UIColor colorWithRed:248/255. green:248/255. blue:248/255. alpha:1];
//    _toolbar.clipsToBounds = YES;
    /*
    
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
//        self.view.backgroundColor = [UIColor clearColor];
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = _backImg.frame;
        [self.view addSubview:blurEffectView];
        
        [blurEffectView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:blurEffectView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:blurEffectView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:blurEffectView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:blurEffectView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    }  else {
        self.view.backgroundColor = [UIColor blackColor];
    }*/
    
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
}

- (NSArray<id<UIPreviewActionItem>> *) previewActionItems
{
    NSMutableArray *array = [NSMutableArray array];
    
    if (_infos[@"web"] != nil && ![_infos[@"web"] isEqualToString:@""])
        [array addObject:[UIPreviewAction actionWithTitle:@"Site" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self site]; }]];
    if (_infos[@"fb"] != nil && ![_infos[@"fb"] isEqualToString:@""])
        [array addObject:[UIPreviewAction actionWithTitle:@"Facebook" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self facebook]; }]];
    if (_infos[@"mail"] != nil && ![_infos[@"mail"] isEqualToString:@""] && [MFMailComposeViewController canSendMail])
        [array addObject:[UIPreviewAction actionWithTitle:@"Mail" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self mail]; }]];
    if (_infos[@"tel"] != nil && ![_infos[@"tel"] isEqualToString:@""])
        [array addObject:[UIPreviewAction actionWithTitle:@"Appeler" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self tel]; }]];
    if (_infos[@"youtube"] != nil && ![_infos[@"youtube"] isEqualToString:@""])
        [array addObject:[UIPreviewAction actionWithTitle:@"YouTube" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self youtube]; }]];
    if (_infos[@"instagram"] != nil && ![_infos[@"instagram"] isEqualToString:@""])
        [array addObject:[UIPreviewAction actionWithTitle:@"Instagram" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self instagram]; }]];
    if (_infos[@"snap"] != nil && ![_infos[@"snap"] isEqualToString:@""])
        [array addObject:[UIPreviewAction actionWithTitle:@"Snapchat" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self snapchat]; }]];
    if (_infos[@"twitter"] != nil && ![_infos[@"twitter"] isEqualToString:@""])
        [array addObject:[UIPreviewAction actionWithTitle:@"Twitter" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self twitter]; }]];
    if (_infos[@"linkedin"] != nil && ![_infos[@"linkedin"] isEqualToString:@""])
        [array addObject:[UIPreviewAction actionWithTitle:@"LinkedIn" style:UIPreviewActionStyleDefault
                                                  handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self linkedin]; }]];
    
    return [NSArray arrayWithArray:array];
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
    {
        /*[[Data sharedData] moreLoadingActivity];
        [SDWebImageDownloader.sharedDownloader downloadImageWithURL:[NSURL URLWithString:_infos[@"img"]]
                                                            options:0
                                                           progress:nil
                                                          completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished)
         {
             if (image && finished)
             {
                 [self configureBannerWithImage:image];
                 [self loadClub];
             }
             [[Data sharedData] lessLoadingActivity];
         }];*/
        [self configureBannerWithURL:[NSURL URLWithString:_infos[@"img"]]];
    }

    [self loadClub];
}

- (void) loadClub
{
    if (_infos[@"nom"] == nil)
        return;
    
    self.title = _infos[@"nom"];
    
    [self.tableView reloadData];
    
    // Description
    CGRect frame = self.contentView.bounds;
    frame.origin.x += 10;
    frame.origin.y -= 15;
    frame.size.width -= 20;
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.font = [UIFont systemFontOfSize:15];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [_infos[@"detail"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHeaderClub)];
    [label addGestureRecognizer:tap];
    [self.contentView addSubview:label];
    
    // Boutons
    NSMutableArray *boutons = [NSMutableArray array];
    if (_infos[@"web"] != nil && ![_infos[@"web"] isEqualToString:@""])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"site"] style:UIBarButtonItemStylePlain target:self action:@selector(site)];
        [boutons addObject:item];
    }
    if (_infos[@"fb"] != nil && ![_infos[@"fb"] isEqualToString:@""])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"fb"] style:UIBarButtonItemStylePlain target:self action:@selector(facebook)];
        [boutons addObject:item];
    }
    if (_infos[@"twitter"] != nil && ![_infos[@"twitter"] isEqualToString:@""])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"twitter"] style:UIBarButtonItemStylePlain target:self action:@selector(twitter)];
        [boutons addObject:item];
    }
    if (_infos[@"youtube"] != nil && ![_infos[@"youtube"] isEqualToString:@""])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"youtube"] style:UIBarButtonItemStylePlain target:self action:@selector(youtube)];
        [boutons addObject:item];
    }
    if (_infos[@"snap"] != nil && ![_infos[@"snap"] isEqualToString:@""])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"snap"] style:UIBarButtonItemStylePlain target:self action:@selector(snapchat)];
        [boutons addObject:item];
    }
    if (_infos[@"instagram"] != nil && ![_infos[@"instagram"] isEqualToString:@""])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"instagram"] style:UIBarButtonItemStylePlain target:self action:@selector(instagram)];
        [boutons addObject:item];
    }
    if (_infos[@"linkedin"] != nil && ![_infos[@"linkedin"] isEqualToString:@""])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"linkedin"] style:UIBarButtonItemStylePlain target:self action:@selector(linkedin)];
        [boutons addObject:item];
    }
    if (_infos[@"mail"] != nil && ![_infos[@"mail"] isEqualToString:@""] && [MFMailComposeViewController canSendMail])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mail"] style:UIBarButtonItemStylePlain target:self action:@selector(mail)];
        [boutons addObject:item];
    }
    if (_infos[@"tel"] != nil && ![_infos[@"tel"] isEqualToString:@""])
    {
        [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tel"] style:UIBarButtonItemStylePlain target:self action:@selector(tel)];
        [boutons addObject:item];
    }
    [boutons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.contentView.frame.size.height - 44, self.contentView.frame.size.width, 44)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [toolbar setDelegate:self];
    [toolbar setItems:boutons];
    [toolbar setBarStyle:UIBarStyleBlack];
    [toolbar setTranslucent:YES];
    [toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    toolbar.layer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.42].CGColor;
    [self.contentView addSubview:toolbar];
    
    // Handoff
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
        [[Data sharedData] openURL:_infos[@"web"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] openURL:_infos[@"web"] currentVC:self];
}

- (void) facebook
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] openURL:_infos[@"fb"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] openURL:_infos[@"fb"] currentVC:self];
}

- (void) twitter
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] twitter:_infos[@"twitter"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] twitter:_infos[@"twitter"] currentVC:self];
}

- (void) youtube
{
//    [[Data sharedData] youtube:_infos[@"youtube"] currentVC:self];
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] openURL:_infos[@"youtube"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] openURL:_infos[@"youtube"] currentVC:self];
}

- (void) snapchat
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] snapchat:_infos[@"snap"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] snapchat:_infos[@"snap"] currentVC:self];
}

- (void) instagram
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] instagram:_infos[@"instagram"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] instagram:_infos[@"instagram"] currentVC:self];
}

- (void) linkedin
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] openURL:_infos[@"linkedin"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] openURL:_infos[@"linkedin"] currentVC:self];
}

- (void) mail
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] mail:_infos[@"mail"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] mail:_infos[@"mail"] currentVC:self];
}

- (void) tel
{
    if ([[Data sharedData] t_currentTopVC] != nil)
        [[Data sharedData] tel:_infos[@"tel"] currentVC:[[Data sharedData] t_currentTopVC]];
    else
        [[Data sharedData] tel:_infos[@"tel"] currentVC:self];
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
    return [_infos[@"modules"] count];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [_infos[@"modules"][section][@"membres"] count];
}

- (nullable NSString *) tableView:(nonnull UITableView *)tableView
          titleForHeaderInSection:(NSInteger)section
{
    return _infos[@"modules"][section][@"nomModule"];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView
                  cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"clubsDetailCell" forIndexPath:indexPath];
    
    NSDictionary *membre = _infos[@"modules"][indexPath.section][@"membres"][indexPath.row];
    cell.textLabel.text = membre[@"nom"];
    cell.detailTextLabel.text = membre[@"detail"];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    if (membre[@"img"] != nil && ![membre[@"img"] isEqualToString:@""])
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:membre[@"img"]]
                          placeholderImage:[UIImage imageNamed:@"placeholder2"]];
    else
        [cell.imageView setImage:nil];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
