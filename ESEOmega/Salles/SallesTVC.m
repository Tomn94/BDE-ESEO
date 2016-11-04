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
    
    [[Data sharedData] updateJSON:@"rooms"];
    
    sortMode = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"roomsSortMode"];
    
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
    [ctr addObserver:self selector:@selector(loadSalles) name:@"rooms" object:nil];
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
    NSString *key = ROOM_KEY_NAME;
    NSString *pre = @"";
    if (sortMode == 1) {
        key = ROOM_KEY_BUILDING;
        pre = @"Bâtiment ";
    }
    else if (sortMode == 2) {
        key = ROOM_KEY_FLOOR;
        pre = @"Étage ";
    }
    
    NSString *res = @"#";
    if (search.active)
    {
        if (![filtre[section] count])
            return nil;
        
        NSString *value = (sortMode == 2) ? [filtre[section][0][key] stringValue] : filtre[section][0][key];
        if (![value isEqualToString:@""])
            res = (sortMode == 0) ? [value substringToIndex:1] : value;
        return [NSString stringWithFormat:@"%@%@", pre, res];
    }
    
    NSString *value = (sortMode == 2) ? [salles[section][0][key] stringValue] : salles[section][0][key];
    if (![value isEqualToString:@""])
        res = (sortMode == 0) ? [value substringToIndex:1] : value;
    return [NSString stringWithFormat:@"%@%@", pre, res];
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (search.active || ![salles count])
        return nil;
    
    NSMutableArray *array;
    if (sortMode == 0)  // Just letters
        array = [[[UILocalizedIndexedCollation currentCollation] sectionIndexTitles] mutableCopy];
    else
    {
        array = [NSMutableArray array];
        /* Let's get each Building or Floor ID */
        for (NSArray *section in salles)
        {
            if (section.count) {
                id header = section[0][(sortMode == 2) ? ROOM_KEY_FLOOR : ROOM_KEY_BUILDING];
                if (sortMode == 2)
                    header = [header stringValue];
                [array addObject:header];
            }
        }
    }
    [array insertObject:UITableViewIndexSearch atIndex:0];

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
    if ([title isEqualToString:@"#"])
        return salles.count - 1;
    
    NSString *key = ROOM_KEY_NAME;
    if (sortMode == 1)
        key = ROOM_KEY_BUILDING;
    else if (sortMode == 2)
        key = ROOM_KEY_FLOOR;
    
    NSInteger i = 0;
    for (NSArray *lettre in salles)
    {
        NSString *value = (sortMode == 2) ? [lettre[0][key] stringValue] : lettre[0][key];
        NSComparisonResult res;
        if (sortMode != 0 || [value isEqualToString:@""])
            res = [value caseInsensitiveCompare:title];
        else
            res = [[value substringToIndex:1] caseInsensitiveCompare:title];
        
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
    
    
    cell.textLabel.text = salle[ROOM_KEY_NAME];
    NSString *desc = [NSString stringWithFormat:@"%@%@Bâtiment %@ · Étage %d",
                      salle[ROOM_KEY_NUM], ([salle[ROOM_KEY_NUM] isEqualToString:@""]) ? @"" : @" · ", salle[ROOM_KEY_BUILDING], [salle[ROOM_KEY_FLOOR] intValue]];
    if (![salle[ROOM_KEY_INFO] isEqualToString:@""])
        desc = [desc stringByAppendingString:[NSString stringWithFormat:@" · %@", salle[ROOM_KEY_INFO]]];
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
    
    NSString *query = search.searchBar.text;
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(%K contains[cd] %@) OR (%K contains[cd] %@) OR (%K contains[cd] %@)",
                                    ROOM_KEY_NAME, query, ROOM_KEY_NUM, query, ROOM_KEY_INFO, query];
    
    for (NSArray *lettre in salles)
        [filtre addObject:[lettre filteredArrayUsingPredicate:resultPredicate]];
    
    [self.tableView reloadData];
}

#pragma mark - Actions

/** Close this View Controller */
- (IBAction) fermer:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/** Refresh rooms data if needed */
- (IBAction) refresh:(id)sender
{
    if (![[Data sharedData] shouldUpdateJSON:@"rooms"])
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"rooms"];
}

/** Sort rooms from the received data */
- (void) loadSalles
{
    [self.refreshControl endRefreshing];
    
    NSMutableArray *sortedRooms = [NSMutableArray array];
    NSMutableArray *allRooms = [NSMutableArray arrayWithArray:[[Data sharedData] salles][@"rooms"]];
    
    /* Sort alphabetically or by building or byfloor */
    NSString *sortKey = ROOM_KEY_NAME;
    if (sortMode == 1)
        sortKey = ROOM_KEY_BUILDING;
    else if (sortMode == 2)
        sortKey = ROOM_KEY_FLOOR;
    if (sortMode == 2)
        [allRooms sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES]]];
    else
        [allRooms sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortKey
                                                                       ascending:YES
                                                                        selector:@selector(localizedStandardCompare:)]]];
    
    /* Split rooms into building sections or floor sections or letter sections for alpha */
    NSString *currentSectionID = nil;
    for (NSDictionary *room in allRooms)
    {
        NSString *roomID = (sortMode == 2) ? [room[sortKey] stringValue] : room[sortKey];
        if (sortMode == 0)  // alpha = sort by 1st letter
            roomID = [room[sortKey] substringToIndex:1];
        
        // Let's fill the current section if it belongs to it
        if ([roomID caseInsensitiveCompare:currentSectionID] == NSOrderedSame)
            [[sortedRooms lastObject] addObject:room];
        else   // or create a new section
            [sortedRooms addObject:[NSMutableArray arrayWithObject:room]];
        
        // In any case we take the current ID for the next test
        currentSectionID = roomID;
    }
    
    /* Inner sorting */
    if (sortMode) {
        for (NSMutableArray *rooms in sortedRooms)
        {
            NSSortDescriptor *alphaSD = [NSSortDescriptor sortDescriptorWithKey:ROOM_KEY_NAME
                                                                      ascending:YES
                                                                       selector:@selector(localizedStandardCompare:)];
            if (sortMode == 1)  // Sort by building inner sorting by floor, then alpha
                [rooms sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:ROOM_KEY_FLOOR
                                                                            ascending:YES], alphaSD]];
            else                // Sort by floor inner sorting alphabetically
                [rooms sortUsingDescriptors:@[alphaSD]];
        }
    }
    
    salles = [NSArray arrayWithArray:sortedRooms];
    
    /* Now, present */
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

/** Display the map picture on the whole screen */
- (IBAction) afficherPlans:(id)sender
{
    JTSImageInfo *imageInfo = [JTSImageInfo new];
    imageInfo.image = [UIImage imageNamed:@"plan"];
    
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc] initWithImageInfo:imageInfo
                                                                                       mode:JTSImageViewControllerMode_Image
                                                                            backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled | JTSImageViewControllerBackgroundOption_Blurred];
    
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOffscreen];
}

/** Change rooms sorting mode,
    cycles through alphabetically → building → floor */
- (IBAction) sort:(id)sender
{
    sortMode = (sortMode + 1) % 3;
    [[NSUserDefaults standardUserDefaults] setInteger:sortMode forKey:USR_DEFAULTS_KEY];
    
    /* Animate during the change */
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.45f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [self.tableView.layer addAnimation:animation forKey:NULL];

    /* Sort data again */
    [self loadSalles];
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
