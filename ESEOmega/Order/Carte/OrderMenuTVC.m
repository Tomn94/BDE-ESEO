//
//  OrderMenuTVC.m
//  ESEOmega
//
//  Created by Thomas NAUDET on 01/08/2015.
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

#import "OrderMenuTVC.h"

@implementation OrderMenuTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    data = [[Data sharedData] cafetData];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    CGFloat topInset = 0;
    if (@available(iOS 11.0, *)) {
        topInset = self.view.safeAreaInsets.top;
    }
    statut = [[UIView alloc] initWithFrame:CGRectMake(0, topInset, self.view.bounds.size.width, 20)];
    [statut setBackgroundColor:[UIColor colorWithRed:0.447 green:0.627 blue:0.000 alpha:1.000]];
    label  = [[UILabel alloc] initWithFrame:[statut bounds]];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [label setText:@"Ajouté au panier !"];
    [label setTextColor:[UIColor whiteColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:12]];
    [statut addSubview:label];
    UITapGestureRecognizer *tapRecon = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(masquerMessage)];
    [statut addGestureRecognizer:tapRecon];
    [self.pvcHolder addSubview:statut];
    
    [statut setAlpha:0];
    
    [self rotateInsets];
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
//    [ctr addObserver:self selector:@selector(rotateInsets) name:UIDeviceOrientationDidChangeNotification object:nil];
    [ctr addObserver:self selector:@selector(afficherMessageNotif:) name:@"showMessagePanier" object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillTransitionToSize:(CGSize)size
        withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self rotateInsets];
}

- (void) rotateInsets
{
    [self masquerMessageQuick];
    
    CGFloat toolbarHeight = 44;
    if (@available(iOS 11, *)) {
        [self setAdditionalSafeAreaInsets:UIEdgeInsetsMake(toolbarHeight, 0, 0, 0)];
    } else {
        CGFloat dec = toolbarHeight + self.navigationController.navigationBar.frame.size.height
                      + ((iPAD) ? 0 : [UIApplication sharedApplication].statusBarFrame.size.height);
        self.tableView.contentInset = UIEdgeInsetsMake(dec, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    }
}

#pragma mark - Actions

- (void) choseMenu:(NSDictionary *)menu
{
    OrderElemTVC *detail = [[OrderElemTVC alloc] initWithStyle:UITableViewStyleGrouped
                                                       andData:menu];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void) chooseIngredientsFor:(NSDictionary *)element
{
    OrderIngredTVC *detail = [[OrderIngredTVC alloc] initWithStyle:UITableViewStyleGrouped
                                                           andMenu:-1];
    [detail setData:element];
    [self.navigationController pushViewController:detail animated:YES];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [data[0][@"lacmd-categories"] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OrderMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"orderMenuCell" forIndexPath:indexPath];
    
    NSDictionary *donnees = data[0][@"lacmd-categories"][indexPath.row];
    
    cell.nom.text = donnees[@"name"];
    cell.detail.text = donnees[@"briefText"];
    cell.prix.text = [[NSString stringWithFormat:@"À partir de %.2f €", [donnees[@"firstPrice"] doubleValue]] stringByReplacingOccurrencesOfString:@"." withString:@","];
    [cell.back sd_setImageWithURL:[NSURL URLWithString:donnees[@"imgUrl"]]
                 placeholderImage:[UIImage imageNamed:@"placeholder"]];
    
    
    cell.nom.layer.shadowRadius = 4;
    cell.nom.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.nom.layer.shadowOffset = CGSizeMake(0, 0);
    cell.nom.layer.shadowOpacity = 1;
    cell.detail.layer.shadowRadius = 3;
    cell.detail.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.detail.layer.shadowOffset = CGSizeMake(0, 0);
    cell.detail.layer.shadowOpacity = 1;
    cell.prix.layer.shadowRadius = 3;
    cell.prix.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.prix.layer.shadowOffset = CGSizeMake(0, 0);
    cell.prix.layer.shadowOpacity = 1;
    
    return cell;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if ([[Data sharedData] cafetCmdEnCours])
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    NSDictionary *donnees = data[0][@"lacmd-categories"][indexPath.row];
    
    if ([[[Data sharedData] cafetPanier] count] >= NBR_MAX_PANIER)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Votre panier est plein"
                                                                       message:[NSString stringWithFormat:@"Vous ne pouvez avoir que %d items maximum dans votre panier.\nAllez dans Panier puis appuyez sur Modifier pour en retirer.", NBR_MAX_PANIER]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if ([donnees[@"catname"] isEqualToString:@"cat_menus"])
    {
        NSUInteger nbrMenus = 0;
        for (NSDictionary *item in [[Data sharedData] cafetPanier])
            if (item[@"menu"] != nil)
                nbrMenus++;
        if (nbrMenus >= NBR_MAX_MENUS)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous avez encore faim ?"
                                                                           message:[NSString stringWithFormat:@"Vous ne pouvez avoir que %d menus maximum dans votre panier. Allez dans Panier puis appuyez sur Modifier pour en retirer.\nCependant, vous pouvez toujours ajouter d'autres éléments.", NBR_MAX_MENUS]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        UIAlertController *dialog = [UIAlertController alertControllerWithTitle:@"Nos menus"
                                                                        message:@"Pour commencer, choisissez un menu parmi ceux-ci :"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        NSArray *menus = data[1][@"lacmd-menus"];
        for (NSDictionary *menu in menus)
        {
            NSString *titre = menu[@"name"];
            titre = [titre stringByAppendingString:@" ("];
            titre = [titre stringByAppendingString:[[NSString stringWithFormat:@"%.2f €", [menu[@"price"] doubleValue]]
                                                    stringByReplacingOccurrencesOfString:@"." withString:@","]];
            if ([menu[@"nbMainElem"] intValue] > 0 || [menu[@"nbSecoElem"] intValue] > 0)
                titre = [titre stringByAppendingString:@" · "];
            if ([menu[@"nbMainElem"] intValue] > 0)
                titre = [titre stringByAppendingString:[NSString stringWithFormat:@"%d🍔", [menu[@"nbMainElem"] intValue]]];
            if ([menu[@"nbSecoElem"] intValue] > 0)
            {
                if ([menu[@"nbMainElem"] intValue] > 0)
                    titre = [titre stringByAppendingString:@" + "];
                titre = [titre stringByAppendingString:[NSString stringWithFormat:@"%d🍫", [menu[@"nbSecoElem"] intValue]]];
            }
            titre = [titre stringByAppendingString:@")"];
            [dialog addAction:[UIAlertAction actionWithTitle:titre
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [self choseMenu:menu];
                                                     }]];
        }
        
        [dialog addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                   style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:dialog animated:YES completion:nil];
    }
    else
    {
        UIAlertController *dialog = [UIAlertController alertControllerWithTitle:donnees[@"name"]
                                                                        message:@"Choisissez un élément parmi ceux-ci :"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        NSArray *elements = data[2][@"lacmd-elements"];
        for (NSDictionary *element in elements)
        {
            if ([element[@"idcat"] isEqualToString:donnees[@"catname"]] && [element[@"stock"] intValue] > 0)
                [dialog addAction:[UIAlertAction actionWithTitle:[[NSString stringWithFormat:@"%@ (%.2f €)", element[@"name"], [element[@"priceuni"] doubleValue]] stringByReplacingOccurrencesOfString:@"." withString:@","]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       if ([element[@"hasingredients"] integerValue] > 0)
                                           [self chooseIngredientsFor:element];
                                       else
                                       {
                                           [[Data sharedData] cafetPanierAjouter:@{ @"element": element[@"idstr"] }];
                                           [self afficherMessage:element[@"name"]];
                                       }
                                   }]];
        }
        
        if ([dialog.actions count] < 2)
            [dialog setMessage:@""];
        [dialog addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                   style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:dialog animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Messages

- (void) afficherMessage:(NSString *)nom
{
    [timerMessage invalidate];
    [self majFrameMessage];
    [label setText:[NSString stringWithFormat:@"Ajouté au panier : %@", nom]];
    
    CATransition *animation = [CATransition animation];
    [animation setDelegate:self];
    [animation setDuration:0.6f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setType:@"cube"];
    [animation setSubtype:kCATransitionFromBottom];
    [statut.layer addAnimation:animation forKey:NULL];
    
    [statut setAlpha:1];
    
    timerMessage = [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                                  selector:@selector(masquerMessage)
                                                  userInfo:nil repeats:NO];
    
    if (@available(iOS 10.0, *)) {
        UINotificationFeedbackGenerator *generator = [UINotificationFeedbackGenerator new];
        [generator prepare];
        [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
    }
}

- (void) afficherMessageNotif:(NSNotification *)notif
{
    if (notif == nil || notif.userInfo == nil)
        return;
    
    [self afficherMessage:notif.userInfo[@"nom"]];
}

- (void) masquerMessage
{
    [timerMessage invalidate];
    
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.6f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setType:@"cube"];
    [animation setSubtype:kCATransitionFromTop];
    [statut.layer addAnimation:animation forKey:NULL];
    
    [statut setAlpha:0];
}

- (void) masquerMessageQuick
{
    [timerMessage invalidate];
    [UIView animateWithDuration:0.2 animations:^{
        [statut setAlpha:0];
    }];
}

- (void) majFrameMessage
{
    CGFloat topInset = 0;
    if (@available(iOS 11.0, *)) {
        topInset = self.view.safeAreaInsets.top;
    }
    
    [statut setFrame:CGRectMake(0, topInset, self.view.bounds.size.width, 20)];
    [label setFrame:[statut bounds]];
}

@end
