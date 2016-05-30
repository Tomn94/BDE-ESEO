//
//  OrderDetailTVC.m
//  ESEOmega
//
//  Created by Thomas NAUDET on 21/08/2015.
//  Copyright © 2015 Thomas NAUDET

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

#import "OrderIngredTVC.h"

@implementation OrderIngredTVC

- (instancetype) initWithStyle:(UITableViewStyle)style
                       andMenu:(NSInteger)menu
{
    if (self = [super initWithStyle:style])
    {
        _menu = menu;
        
        text = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 21)];
        text.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        text.font = [UIFont systemFontOfSize:11];
        text.textColor = [UIColor grayColor];
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithCustomView:text],
                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                [[UIBarButtonItem alloc] initWithTitle:(_menu != -1) ? @"Ajouter au menu " : @"Ajouter au panier "
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self action:@selector(valider)]]];
        
        ingredients = [[Data sharedData] cafetData][3][@"lacmd-ingredients"];
        selection = [NSMutableArray array];
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self updSupplement];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void) setData:(NSDictionary *)data
{
    _data = data;
    
    self.title = _data[@"name"];
    [self.tableView reloadData];
}

- (double) supplement
{
    NSUInteger sel = [selection count];
    int max = [_data[@"hasingredients"] intValue];
    if (sel > max)
        return [ingredients[0][@"priceuni"] doubleValue] * (sel - max);
    return 0.;
}

- (void) updSupplement
{
    double supp = [self supplement];
    if (supp > 0.)
        text.text = [[NSString stringWithFormat:@"Supplément : + %.2f €", supp] stringByReplacingOccurrencesOfString:@"."
                                                                                                          withString:@","];
    else
        text.text = @"";
}

- (void) sendNotif
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessagePanier" object:nil
                                                      userInfo:@{ @"nom" : _data[@"name"] }];
}

- (void) preselect:(NSArray *)ingr
{
    selection = [NSMutableArray arrayWithArray:ingr];
}

- (void) valider
{
    if (_menu != -1)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"elemMenuSelec" object:nil
                                                          userInfo:@{ @"menu"    : @(_menu),
                                                                      @"element" : _data[@"idstr"],
                                                                      @"items"   : [NSArray arrayWithArray:selection] }];
    else
    {
        [[Data sharedData] cafetPanierAjouter:@{ @"element" : _data[@"idstr"],
                                                 @"items"   : [NSArray arrayWithArray:selection] }];
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendNotif) userInfo:nil repeats:NO];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [ingredients count];
}

- (NSString *) tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    if (!section)
        return [NSString stringWithFormat:@"Vous pouvez ajouter %d ingrédient%@ de votre choix. Au delà, tout supplément est facturé.", [_data[@"hasingredients"] intValue], ([_data[@"hasingredients"] intValue] > 1) ? @"s" : @""];
    /*if (section && [self supplement] > 0)
        return [[NSString stringWithFormat:@"Supplément : + %.2f €", [self supplement]] stringByReplacingOccurrencesOfString:@"."
                                                                                                                  withString:@","];*/
    return nil;
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"orderDetailElemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellID];
    
    cell.textLabel.text = /*(indexPath.section) ? ((_menu != -1) ? @"Ajouter au menu" : @"Ajouter au panier")
                                              : */ingredients[indexPath.row][@"name"];
//    cell.textLabel.textColor = (indexPath.section) ? tableView.tintColor : [UIColor blackColor];
//    cell.textLabel.textAlignment = (indexPath.section) ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    if (/*!indexPath.section && */[selection containsObject:ingredients[indexPath.row][@"idstr"]])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*if (indexPath.section)
    {
    }
    else
    {*/
        NSString *ingredient = ingredients[indexPath.row][@"idstr"];
        if ([selection containsObject:ingredient])
            [selection removeObject:ingredient];
        else
            [selection addObject:ingredient];
        [tableView reloadData];
//    }
    
    [self updSupplement];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
