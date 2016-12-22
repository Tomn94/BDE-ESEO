//
//  IngeNewsTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 22/12/2015.
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

#import "IngeNewsTVC.h"

@implementation IngeNewsCell
@end

@implementation IngeNewsCVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    messageLu = NO;
    [[Data sharedData] updateJSON:@"ingenews"];
    
    self.collectionView.emptyDataSetSource = self;
    self.collectionView.emptyDataSetDelegate = self;
    refreshControl = [UIRefreshControl new];
    refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Liste"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil action:nil];
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(loadFichiers) name:@"ingenews" object:nil];
    [ctr addObserver:refreshControl selector:@selector(endRefreshing) name:@"debugRefresh" object:nil];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
        (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable))
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    
    [self loadFichiers];
}

- (IBAction) fermer:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) refresh:(id)sender
{
    if (![[Data sharedData] shouldUpdateJSON:@"ingenews"])
    {
        [refreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"ingenews"];
}

- (void) loadFichiers
{
    [refreshControl endRefreshing];
    
    fichiers = [[Data sharedData] ingenews][@"fichiers"];
    
    if ([fichiers count])
        [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    else
        [self.collectionView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [self.collectionView reloadData];
}

#pragma mark - Collection View Controller

- (NSInteger) collectionView:(UICollectionView *)collectionView
      numberOfItemsInSection:(NSInteger)section
{
    return [fichiers count];
}

- (CGSize) collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat w = collectionView.frame.size.width;
    if (!iPAD)
    {
        if (w > 410)         // iPhone 5.5”
            return CGSizeMake(192, 192);
        else if (w > 370)    // iPhone 4.7”
            return CGSizeMake(172, 172);
    }
    return CGSizeMake(140, 140);
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView
                   cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IngeNewsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"fichierCollCell" forIndexPath:indexPath];
    
    NSDictionary *fichier = fichiers[indexPath.row];
    
    cell.titreLabel.text = fichier[@"name"];
    NSString *displayFileSize = [NSByteCountFormatter stringFromByteCount:[fichier[@"size"] integerValue]
                                                               countStyle:NSByteCountFormatterCountStyleFile];
    cell.sousLabel.text = [NSString stringWithFormat:@"%@ · %@", fichier[@"date"], displayFileSize];
    
    UIFontDescriptor *const existingDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    
    NSDictionary *const fontAttributes = @{ UIFontDescriptorFeatureSettingsAttribute: @[
                                                    @{ UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                                       UIFontFeatureSelectorIdentifierKey: @(kProportionalNumbersSelector)
                                                       }]
                                            };
    
    UIFontDescriptor *const proportionalDescriptor = [existingDescriptor fontDescriptorByAddingAttributes:fontAttributes];
    UIFont *const proportionalFont = [UIFont fontWithDescriptor:proportionalDescriptor size:cell.sousLabel.font.pointSize];
    cell.sousLabel.font = proportionalFont;
    
    if ([fichier[@"img"] isEqualToString:@""])
        cell.iconeView.image = [UIImage imageNamed:@"doc"];
    else
        [cell.iconeView sd_setImageWithURL:[NSURL URLWithString:fichier[@"img"]]
                          placeholderImage:[UIImage imageNamed:@"doc"]];
    
    cell.contentView.layer.cornerRadius = 6.0f;
    cell.contentView.layer.masksToBounds = YES;
    
    return cell;
}

- (void)  collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *URL = [NSURL URLWithString:[fichiers[indexPath.row][@"file"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    
    if ([SFSafariViewController class])
    {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:URL
                                                             entersReaderIfAvailable:NO];
        if ([SFSafariViewController instancesRespondToSelector:@selector(preferredBarTintColor)])
        {
            safari.preferredBarTintColor = [UINavigationBar appearance].barTintColor;
            safari.preferredControlTintColor = [UINavigationBar appearance].tintColor;
        }
        [self presentViewController:safari animated:YES completion:^{
            NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
            if ([d integerForKey:@"messageImpressionLu"] != 2 && !messageLu)
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous désirez partager le document, l'imprimer ou effectuer une recherche ?"
                                                                               message:@"Pour rechercher dans le document ou le transférer vers n'importe quelle app, tapez sur l'icône de partage en bas.\n\nPour l'imprimer, tapez d'abord sur l'icône Ouvrir dans Safari en bas à droite, puis sur l'icône de partage.\n\nBonne lecture !"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                messageLu = YES;
                [alert addAction:[UIAlertAction actionWithTitle:@"Merci" style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * _Nonnull action) {
                    [d setInteger:1 forKey:@"messageImpressionLu"];
                    [d synchronize];
                }]];
                if ([d integerForKey:@"messageImpressionLu"] == 1)
                    [alert addAction:[UIAlertAction actionWithTitle:@"Ne plus me rappeler" style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * _Nonnull action) {
                        [d setInteger:2 forKey:@"messageImpressionLu"];
                        [d synchronize];
                    }]];
                [safari presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
    else
    {
        UIViewController *vc = [UIViewController new];
        [vc setTitle:fichiers[indexPath.row][@"name"]];
        UIWebView *v = [UIWebView new];
        [v loadRequest:[NSURLRequest requestWithURL:URL]];
        [vc setView:v];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

- (void)     collectionView:(UICollectionView *)collectionView
didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
}

- (void)     collectionView:(UICollectionView *)collectionView
didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor whiteColor];
}

#pragma mark - 3D Touch

- (UIViewController *) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
               viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *index = [self.collectionView indexPathForItemAtPoint:location];
    if (index != nil)
    {
        NSString *url = fichiers[index.row][@"file"];
        
        previewingContext.sourceRect = [self.collectionView layoutAttributesForItemAtIndexPath:index].frame;
        
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
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"autreVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Aucun fichier";
    
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
    return CGPointMake(0, -80);
}

- (UIColor *) backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor groupTableViewBackgroundColor];
}

@end







@implementation IngeNewsTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    [[Data sharedData] updateJSON:@"ingenews"];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Liste"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil action:nil];
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(loadFichiers) name:@"ingenews" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"debugRefresh" object:nil];
    
    [self loadFichiers];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [fichiers count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fichierCell" forIndexPath:indexPath];
    
    NSDictionary *fichier = fichiers[indexPath.row];
    
    cell.textLabel.text = fichier[@"name"];
    NSString *displayFileSize = [NSByteCountFormatter stringFromByteCount:[fichier[@"size"] integerValue]
                                                               countStyle:NSByteCountFormatterCountStyleFile];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", fichier[@"date"], displayFileSize];
    
    UIFontDescriptor *const existingDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    
    NSDictionary *const fontAttributes = @{ UIFontDescriptorFeatureSettingsAttribute: @[
                                                    @{ UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                                       UIFontFeatureSelectorIdentifierKey: @(kProportionalNumbersSelector)
                                                       }]
                                            };
    
    UIFontDescriptor *const proportionalDescriptor = [existingDescriptor fontDescriptorByAddingAttributes:fontAttributes];
    UIFont *const proportionalFont = [UIFont fontWithDescriptor:proportionalDescriptor size:cell.detailTextLabel.font.pointSize];
    cell.detailTextLabel.font = proportionalFont;
    
    CGSize imgSize = CGSizeMake(60, 44);
    UIImage *placeholder = [Data imageByScalingAndCroppingForSize:[UIImage imageNamed:@"doc"]
                                                               to:imgSize
                                                           retina:YES
                                                              fit:YES];
    if ([fichier[@"img"] isEqualToString:@""])
        cell.imageView.image = placeholder;
    else
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:fichier[@"img"]]
                          placeholderImage:placeholder
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                     if (error == nil) {
                                         cell.imageView.image = [Data imageByScalingAndCroppingForSize:image
                                                                                                    to:imgSize
                                                                                                retina:YES
                                                                                                   fit:YES];
                                     }
                                 }];
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *URL = [NSURL URLWithString:[fichiers[indexPath.row][@"file"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    
    if ([SFSafariViewController class])
    {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:URL
                                                             entersReaderIfAvailable:NO];
        if ([SFSafariViewController instancesRespondToSelector:@selector(preferredBarTintColor)])
        {
            safari.preferredBarTintColor = [UINavigationBar appearance].barTintColor;
            safari.preferredControlTintColor = [UINavigationBar appearance].tintColor;
        }
        [self presentViewController:safari animated:YES completion:nil];
    }
    else
    {
        UIViewController *vc = [UIViewController new];
        [vc setTitle:fichiers[indexPath.row][@"name"]];
        UIWebView *v = [UIWebView new];
        [v loadRequest:[NSURLRequest requestWithURL:URL]];
        [vc setView:v];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction) fermer:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) refresh:(id)sender
{
    if (![[Data sharedData] shouldUpdateJSON:@"ingenews"])
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"ingenews"];
}

- (void) loadFichiers
{
    [self.refreshControl endRefreshing];
    
    fichiers = [[Data sharedData] ingenews][@"fichiers"];
    
    if ([fichiers count])
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

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"autreVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Aucun fichier";
    
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
    return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2. - 56.5);
}

- (UIColor *) backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor groupTableViewBackgroundColor];
}

@end
