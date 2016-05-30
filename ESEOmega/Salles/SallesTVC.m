//
//  SallesTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 28/11/2015.
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

#import "SallesTVC.h"

@implementation SallesTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [[Data sharedData] updateJSON:@"salles"];
    
    filtre = [NSMutableArray array];
    search = [[UISearchController alloc] initWithSearchResultsController:nil];
    search.searchResultsUpdater = self;
    search.dimsBackgroundDuringPresentation = NO;
    [search.searchBar sizeToFit];
    search.searchBar.delegate = self;
    search.searchBar.placeholder = @"Rechercher une salle";
    self.tableView.tableHeaderView = search.searchBar;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(loadSalles) name:@"salles" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"debugRefresh" object:nil];
    
    [self loadSalles];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (search.active)
        return [filtre count];
    return [salles count];
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    if (search.active)
        return [filtre[section] count];
    return [salles[section] count];
}

- (NSString *) tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    if (search.active)
    {
        if (![filtre[section] count])
            return nil;
        if ([filtre[section][0][@"nom"] isEqualToString:@""])
            return @"#";
        return [filtre[section][0][@"nom"] substringToIndex:1];
    }
    if ([salles[section][0][@"nom"] isEqualToString:@""])
        return @"#";
    return [salles[section][0][@"nom"] substringToIndex:1];
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (search.active || ![salles count])
        return nil;
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];
    [array insertObject:UITableViewIndexSearch atIndex:0];
    [array removeLastObject];

    return array;
}

- (NSInteger)     tableView:(UITableView *)tableView
sectionForSectionIndexTitle:(NSString *)title
                    atIndex:(NSInteger)index
{
    if (!index)
    {
        self.tableView.contentOffset = CGPointMake(0, -64);
        return NSNotFound;
    }
    
    NSInteger i = 0;
    for (NSArray *lettre in salles)
    {
        NSComparisonResult res;
        if ([lettre[0][@"nom"] isEqualToString:@""])
            res = [@"" caseInsensitiveCompare:title];
        else
            res = [[lettre[0][@"nom"] substringToIndex:1] caseInsensitiveCompare:title];
        if (res == NSOrderedSame)
            return i;
        else if (res == NSOrderedAscending)
            ++i;
        else if (res == NSOrderedDescending)
            break;
    }
    
    return i;
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sallesCell" forIndexPath:indexPath];
    
    NSDictionary *salle;
    if (search.active)
        salle = filtre[indexPath.section][indexPath.row];
    else
        salle = salles[indexPath.section][indexPath.row];
    
    
    cell.textLabel.text = salle[@"nom"];
    NSString *desc = [NSString stringWithFormat:@"%@%@Bâtiment %@ · Étage %d", salle[@"num"], ([salle[@"num"] isEqualToString:@""]) ? @"" : @" · ", salle[@"bat"], [salle[@"etage"] intValue]];
    if (![salle[@"info"] isEqualToString:@""])
        desc = [desc stringByAppendingString:[NSString stringWithFormat:@" · %@", salle[@"info"]]];
    cell.detailTextLabel.text = desc;
    
    UIFontDescriptor *const existingDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    
    NSDictionary *const fontAttributes = @{ UIFontDescriptorFeatureSettingsAttribute: @[
                                                   @{ UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                                      UIFontFeatureSelectorIdentifierKey: @(kProportionalNumbersSelector)
                                                    }]
                                           };
    
    UIFontDescriptor *const proportionalDescriptor = [existingDescriptor fontDescriptorByAddingAttributes:fontAttributes];
    UIFont *const proportionalFont = [UIFont fontWithDescriptor:proportionalDescriptor size:cell.detailTextLabel.font.pointSize];
    cell.detailTextLabel.font = proportionalFont;
    
    return cell;
}

- (void) updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [filtre removeAllObjects];
    filtre = [NSMutableArray array];
    
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(nom contains[cd] %@) OR (num contains[cd] %@) OR (info contains[cd] %@)", search.searchBar.text, search.searchBar.text, search.searchBar.text, search.searchBar.text];
    for (NSArray *lettre in salles)
        [filtre addObject:[lettre filteredArrayUsingPredicate:resultPredicate]];
    
    [self.tableView reloadData];
}

- (IBAction) fermer:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) refresh:(id)sender
{
    if (![[Data sharedData] shouldUpdateJSON:@"salles"])
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"salles"];
}

- (void) loadSalles
{
    [self.refreshControl endRefreshing];
    
    NSMutableArray *t_salles = [NSMutableArray array];
    NSMutableArray *lesSalles = [NSMutableArray arrayWithArray:[[Data sharedData] salles][@"salles"]];
    
    // Tri ordre alpha
    [lesSalles sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"nom"
                                                                    ascending:YES
                                                                     selector:@selector(caseInsensitiveCompare:)]]];
    
    // Séparation ordre alpha
    NSString *lettreActuelle = nil;
    for (NSDictionary *salle in lesSalles)
    {
        NSString *lettreTest;
        if ([salle[@"nom"] isEqualToString:@""])
            lettreTest = @" ";
        else
            lettreTest = [salle[@"nom"] substringToIndex:1];
        if ([lettreTest caseInsensitiveCompare:lettreActuelle] == NSOrderedSame)
            [[t_salles lastObject] addObject:salle];
        else
        {
            NSMutableArray *nv = [NSMutableArray arrayWithObject:salle];
            [t_salles addObject:nv];
        }
        lettreActuelle = lettreTest;
    }
    
    salles = [NSArray arrayWithArray:t_salles];
    
    if ([salles count] || search.active)
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

- (IBAction) afficherPlans:(id)sender
{
    JTSImageInfo *imageInfo = [JTSImageInfo new];
    imageInfo.image = [UIImage imageNamed:@"plan"];
    
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc] initWithImageInfo:imageInfo
                                                                                       mode:JTSImageViewControllerMode_Image
                                                                            backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled | JTSImageViewControllerBackgroundOption_Blurred];
    
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOffscreen];
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    if (search.active)
        return nil;
    return [UIImage imageNamed:@"autreVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    if (search.active)
        return nil;
    NSString *text = @"Aucune salle trouvée";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    if (search.active)
        return nil;
    NSString *text = @"Le bâtiment ESEO a peut-être été détruit, ou alors votre connexion Internet n'est pas au top de sa forme…";
    
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
    if (search.active)
        return [UIColor whiteColor];
    return [UIColor groupTableViewBackgroundColor];
}

@end
