//
//  OrderElemTVC.m
//  ESEOmega
//
//  Created by Tomn on 21/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

#import "OrderElemTVC.h"

@implementation OrderElemTVC

- (instancetype) initWithStyle:(UITableViewStyle)style
                       andData:(NSDictionary *)data
{
    if (self = [super initWithStyle:style])
    {
        [self setData:data];
        
        text = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 21)];
        text.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        text.font = [UIFont systemFontOfSize:11];
        text.textColor = [UIColor grayColor];
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithCustomView:text],
                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                [[UIBarButtonItem alloc] initWithTitle:@"Ajouter au panier " style:UIBarButtonItemStylePlain
                                                                target:self action:@selector(valider)]]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSandw:) name:@"elemMenuSelec" object:nil];
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

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setData:(NSDictionary *)data
{
    _data = data;
    
    NSMutableArray *t_sandwiches = [NSMutableArray array];
    NSMutableArray *t_elements   = [NSMutableArray array];
    NSArray *elems = [[Data sharedData] cafetData][2][@"lacmd-elements"];
    NSArray *sandwichesAcceptes = [_data[@"mainElemStr"] componentsSeparatedByString:@"|"];
    for (NSDictionary *element in elems)
    {
        if ([element[@"outofmenu"] intValue] == 0)
        {
            if ([element[@"hasingredients"] intValue] == 0)
                [t_elements   addObject:element];
            else if ([sandwichesAcceptes containsObject:element[@"idstr"]])
                [t_sandwiches addObject:element];
        }
    }
    sandwiches = [NSArray arrayWithArray:t_sandwiches];
    elements = [NSArray arrayWithArray:t_elements];
    
    selectionElements   = [NSMutableArray array];
    selectionSandwiches = [NSMutableArray array];
    for (int i = 0 ; i < [_data[@"nbMainElem"] intValue] ; ++i)
        [selectionSandwiches addObject:@{ @"element": @"" }];
    
    self.title = _data[@"name"];
    [self.tableView reloadData];
}

- (double) supplementSand:(NSDictionary *)sandwich
{
    double somme = 0.;
    for (NSDictionary *sand in sandwiches)
    {
        if ([sandwich[@"element"] isEqualToString:sand[@"idstr"]])
        {
            somme += [sand[@"pricemore"] doubleValue];
            NSUInteger nbrSel = [sandwich[@"items"] count];
            NSInteger nbrMax = [sand[@"hasingredients"] integerValue];
            if (nbrSel > nbrMax)
                somme += [[[Data sharedData] cafetData][3][@"lacmd-ingredients"][0][@"priceuni"] doubleValue] * (nbrSel - nbrMax);
            break;
        }
    }
    return somme;
}

- (double) supplement
{
    double somme = 0.;
    for (NSDictionary *sandwich in selectionSandwiches)
        somme += [self supplementSand:sandwich];
    for (NSDictionary *element in selectionElements)
        somme += [element[@"pricemore"] doubleValue];
    return somme;
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

- (void) newSandw:(NSNotification *)notif
{
    [selectionSandwiches replaceObjectAtIndex:[notif.userInfo[@"menu"] integerValue]
                                   withObject:@{ @"element" : notif.userInfo[@"element"],
                                                 @"items"   : notif.userInfo[@"items"] }];
//    [self updSupplement];
    [self.tableView reloadData];
}

- (void) sendNotif
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessagePanier" object:nil
                                                      userInfo:@{ @"nom" : _data[@"name"] }];
}

- (void) valider
{
    BOOL assez = YES;
    for (NSDictionary *sandwich in selectionSandwiches)
    {
        if ([sandwich[@"element"] isEqualToString:@""])
        {
            assez = NO;
            break;
        }
    }
    if (!assez)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous n'avez pas sélectionné tous vos éléments principaux"
                                                                       message:[NSString stringWithFormat:@"Vous devez choisir %d élément%@ parmi ceux présentés pour ce menu.", [_data[@"nbMainElem"] intValue], ([_data[@"nbMainElem"] intValue] > 1) ? @"s" : @""]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if ([selectionElements count] < [_data[@"nbSecoElem"] intValue])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous n'avez pas sélectionné tous vos éléments secondaires"
                                                                       message:[NSString stringWithFormat:@"Vous devez choisir %d élément%@ parmi ceux présentés pour ce menu.", [_data[@"nbSecoElem"] intValue], ([_data[@"nbSecoElem"] intValue] > 1) ? @"s" : @""]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        NSMutableArray *items = [NSMutableArray arrayWithArray:selectionSandwiches];
        for (NSDictionary *element in selectionElements)
            [items addObject:@{ @"element" : element[@"idstr"] }];
        [[Data sharedData] cafetPanierAjouter:@{ @"menu" : _data[@"idstr"],
                                                 @"items" : [NSArray arrayWithArray:items] }];
        [self.navigationController popViewControllerAnimated:YES];
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendNotif) userInfo:nil repeats:NO];
    }
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data[@"nbMainElem"] intValue] + 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    if (section == [_data[@"nbMainElem"] intValue])
        return [elements count];
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    if (section < [_data[@"nbMainElem"] intValue])
    {
        NSString *ordinal = @"ᴱ";
        if (section == 0)
            ordinal = @"ᴱᴿ";
        else if (section == 1 && [_data[@"nbMainElem"] intValue] == 2)
            ordinal = @"ᴺᴰ";
        if ([_data[@"nbMainElem"] intValue] > 1)
            return [NSString stringWithFormat:@"Choisissez votre %d%@ élément principal", (int)(section + 1), ordinal];
        return @"Choisissez votre élément principal";
    }
    else if (section == [_data[@"nbMainElem"] intValue] && [_data[@"nbSecoElem"] intValue] > 0)
    {
        if ([_data[@"nbSecoElem"] intValue] > 1)
            return [NSString stringWithFormat:@"Choisissez vos %d éléments secondaires", [_data[@"nbSecoElem"] intValue]];
        return @"Choisissez votre élément secondaire";
    }
    /*else if (section > [_data[@"nbMainElem"] intValue] && [self supplement] > 0)
        return [[NSString stringWithFormat:@"Supplément : + %.2f €", [self supplement]] stringByReplacingOccurrencesOfString:@"."
                                                                                                                  withString:@","];*/
    return nil;
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"orderDetailMenuCell";
    static NSString *cellID2 = @"orderDetailMenuBtnCell";
    UITableViewCell *cell;
    if (indexPath.section > [_data[@"nbMainElem"] intValue] ||
        (indexPath.section < [_data[@"nbMainElem"] intValue] && [selectionSandwiches[indexPath.section][@"element"] isEqualToString:@""]))
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellID2];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellID2];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:cellID];
    }
    
    cell.detailTextLabel.text = @"";
    cell.textLabel.textColor = tableView.tintColor;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (indexPath.section < [_data[@"nbMainElem"] intValue])
    {
        NSDictionary *sel = selectionSandwiches[indexPath.section];
        if ([sel[@"element"] isEqualToString:@""])
            cell.textLabel.text = @"Choisir…";
        else
        {
            NSDictionary *infos = [OrderPanierTVC dataForIDStr:sel];
            NSString *txt = infos[@"name"];
            /*if (![infos[@"detail"] isEqualToString:@""])
            {
                txt = [txt stringByAppendingString:@" ("];
                txt = [txt stringByAppendingString:infos[@"detail"]];
                txt = [txt stringByAppendingString:@" )"];
            }*/
            cell.textLabel.text = txt;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
            if ([self supplementSand:sel] != 0.)
                cell.detailTextLabel.text = [[NSString stringWithFormat:@"+ %.2f €", [self supplementSand:sel]]
                                             stringByReplacingOccurrencesOfString:@"."
                                             withString:@","];
        }
    }
    else if (indexPath.section == [_data[@"nbMainElem"] intValue])
    {
        cell.textLabel.text = elements[indexPath.row][@"name"];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        if ([selectionElements containsObject:elements[indexPath.row]])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        if ([elements[indexPath.row][@"pricemore"] doubleValue] != 0.)
            cell.detailTextLabel.text = [[NSString stringWithFormat:@"+ %.2f €", [elements[indexPath.row][@"pricemore"] doubleValue]]
                                         stringByReplacingOccurrencesOfString:@"."
                                         withString:@","];
    }
    /*else if (indexPath.section > [_data[@"nbMainElem"] intValue])
        cell.textLabel.text = @"Ajouter au panier";*/
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section < [_data[@"nbMainElem"] intValue])
    {
        UIAlertController *dialog = [UIAlertController alertControllerWithTitle:@"Choix de l'élément principal"
                                                                        message:[[self tableView:tableView titleForHeaderInSection:indexPath.section] stringByAppendingString:@" parmi ceux-ci :"]
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        for (NSDictionary *sandwich in sandwiches)
        {
            NSString *title = @"";
            if ([selectionSandwiches[indexPath.section][@"element"] isEqualToString:sandwich[@"idstr"]])
                title = @"Modifier : ";
            title = [title stringByAppendingString:sandwich[@"name"]];
            if ([sandwich[@"pricemore"] doubleValue] > 0.)
                title = [title stringByAppendingString:[[NSString stringWithFormat:@" (+ %.2f €)", [sandwich[@"pricemore"] doubleValue]]
                                                        stringByReplacingOccurrencesOfString:@"." withString:@","]];
            [dialog addAction:[UIAlertAction actionWithTitle:title
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action)
                               {
                                   OrderIngredTVC *detail = [[OrderIngredTVC alloc] initWithStyle:UITableViewStyleGrouped
                                                                                          andMenu:indexPath.section];
                                   [detail setData:sandwich];
                                   NSDictionary *sel = selectionSandwiches[indexPath.section];
                                   if ([sel[@"element"] isEqualToString:sandwich[@"idstr"]])
                                       [detail preselect:sel[@"items"]];
                                   [self.navigationController pushViewController:detail animated:YES];
                               }]];
        }
        
        if ([dialog.actions count] < 2)
            [dialog setMessage:@""];
        [dialog addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:dialog animated:YES completion:nil];
    }
    else if (indexPath.section == [_data[@"nbMainElem"] intValue])
    {
        NSDictionary *element = elements[indexPath.row];
        if ([selectionElements containsObject:element])
            [selectionElements removeObject:element];
        else
        {
            if ([selectionElements count] >= [_data[@"nbSecoElem"] intValue])
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous avez sélectionné trop d'éléments pour ce menu"
                                                                               message:[NSString stringWithFormat:@"Vous ne pouvez sélectionner que %d élément%@ maximum, désélectionnez-%@ ou choisissez un autre menu.", [_data[@"nbSecoElem"] intValue], ([_data[@"nbSecoElem"] intValue] > 1) ? @"s" : @"", ([_data[@"nbSecoElem"] intValue] > 1) ? @"en" : @"le"]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            else
                [selectionElements addObject:element];
        }
        [tableView reloadData];
    }
    /*else if (indexPath.section > [_data[@"nbMainElem"] intValue])
    {
    }*/
    
    [self updSupplement];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}/*
  // TODO: Tester sans
- (void)                       tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}*/

@end
