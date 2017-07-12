//
//  EventOrderNavTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 11/01/2016.
//  Copyright © 2016 Thomas Naudet

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

#import "EventsOrderNavTVC.h"

@implementation EventsOrderNavTVC

- (instancetype) initWithStyle:(UITableViewStyle)style
                       andData:(NSDictionary *)data
{
    if (self = [super initWithStyle:style])
    {
        [self setData:data];
        
        selectionNavette = nil;
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                [[UIBarButtonItem alloc] initWithTitle:@"Acheter" style:UIBarButtonItemStylePlain
                                                                target:self action:@selector(valider)]]];
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void) setData:(NSDictionary *)data
{
    _data = data;
    
    NSMutableArray *t_navettes = [NSMutableArray array];
    for (NSDictionary *navette in [[Data sharedData] cafetData][0][@"event-navettes"])
        if ([navette[@"idevent"] isEqualToString:_data[@"id"]])
            [t_navettes addObject:navette];
    navettes = [NSArray arrayWithArray:t_navettes];
    
    self.title = _data[@"nom"];
    [self.tableView reloadData];
}

- (void) valider
{
    if ([[Data sharedData] cafetCmdEnCours])
        return;
    if (selectionNavette == nil)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous n'avez pas choisi de navette"
                                                                       message:@"Tapez sur une de la liste pour la sélectionner."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"commandeNavetteOK" object:nil
                                                      userInfo:@{@"ticket": _data,
                                                                 @"navette": selectionNavette}];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [navettes count];
}

- (NSString *) tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    return @"Choisissez une navette";
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellNavette"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"cellNavette"];
    
    NSDictionary *navette = navettes[indexPath.row];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *shortMinusYear = [NSDateFormatter dateFormatFromTemplate:@"dd/MM HH:mm" options:0 locale:[NSLocale currentLocale]];
    NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
    [dateFormatter2 setDateFormat:shortMinusYear];
    NSString *depart = [dateFormatter2 stringFromDate:[dateFormatter dateFromString:navette[@"departure"]]];
    NSString *arrivee = [NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:navette[@"arrival"]]
                                                       dateStyle:NSDateFormatterNoStyle
                                                       timeStyle:NSDateFormatterShortStyle];

    cell.textLabel.text = [NSString stringWithFormat:@"%@ · %@", depart, navette[@"departplace"]];
    if ([navette isEqualToDictionary:selectionNavette])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    if ([navette[@"restseats"] integerValue] > 1)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld/%ld places disponibles · Arrivée %@",
                                     (long)[navette[@"restseats"] integerValue], (long)[navette[@"totseats"] integerValue], arrivee];
    else
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld/%ld place disponible · Arrivée %@",
                                     (long)[navette[@"restseats"] integerValue], (long)[navette[@"totseats"] integerValue], arrivee];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.imageView.image = [[UIImage imageNamed:@"bus"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imageView.tintColor = [UIColor grayColor];
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectionNavette = navettes[indexPath.row];
    [tableView reloadData];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
