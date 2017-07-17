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
    
    [self rotateInsets];
    
    statut = [[UIWindow alloc] initWithFrame:CGRectMake(0, -20, MIN([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height), 20)];
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
    currentOrientation = [[UIDevice currentDevice] orientation];
    [self majFrameMessage];
    CGFloat dec = 44 + self.navigationController.navigationBar.frame.size.height + ((iPAD) ? 0 : [UIApplication sharedApplication].statusBarFrame.size.height);
    self.tableView.contentInset = UIEdgeInsetsMake(dec, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
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
    [cell.back sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URI_CAFET, donnees[@"imgUrl"]]]
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
    
    CGRect frame   = [statut frame];
    if (currentOrientation == UIDeviceOrientationLandscapeLeft)
        frame.origin.x = MIN([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) - 20;
    else if (currentOrientation == UIDeviceOrientationLandscapeRight)
        frame.origin.x = 0;
    else if (iPAD && currentOrientation == UIDeviceOrientationPortraitUpsideDown)
        frame.origin.y = MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) - 20;
    else
        frame.origin.y = 0;
    [statut setHidden:NO];
    [statut setFrame:frame];
    
    [statut setWindowLevel:UIWindowLevelStatusBar];
    [statut makeKeyAndVisible];
    [statut resignKeyWindow];
    
    CATransition *animation = [CATransition animation];
    [animation setDelegate:self];
    [animation setDuration:0.6f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setType:@"cube"];
    if (currentOrientation == UIDeviceOrientationLandscapeLeft)
        [animation setSubtype:kCATransitionFromRight];
    else if (currentOrientation == UIDeviceOrientationLandscapeRight)
        [animation setSubtype:kCATransitionFromLeft];
    else if (iPAD && currentOrientation == UIDeviceOrientationPortraitUpsideDown)
        [animation setSubtype:kCATransitionFromTop];
    else
        [animation setSubtype:kCATransitionFromBottom];
    [statut.layer addAnimation:animation forKey:NULL];
    
    timerMessage = [NSTimer scheduledTimerWithTimeInterval:2. target:self selector:@selector(masquerMessage) userInfo:nil repeats:NO];
    
    if ([NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}]) {
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
    CGRect frame   = [statut frame];
    if (currentOrientation == UIDeviceOrientationLandscapeLeft)
        frame.origin.x = MIN([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    else if (currentOrientation == UIDeviceOrientationLandscapeRight)
        frame.origin.x = -20;
    else if (iPAD && currentOrientation == UIDeviceOrientationPortraitUpsideDown)
        frame.origin.y = MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    else
        frame.origin.y = -20;
    [UIView animateWithDuration:0.6 animations:^{
        [statut setFrame:frame];
    } completion:^(BOOL finished) {
        [statut setHidden:YES];
    }];
}

- (void) majFrameMessage
{
    CGFloat min = MIN([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    CGFloat max = MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    
    if (currentOrientation == UIDeviceOrientationLandscapeLeft)
    {
        [statut setFrame:CGRectMake(min, 0, 20, max)];
        [label setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    }
    else if (currentOrientation == UIDeviceOrientationLandscapeRight)
    {
        [statut setFrame:CGRectMake(-20, 0, 20, max)];
        [label setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
    }
    else if (iPAD && currentOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
        [statut setFrame:CGRectMake(0, max, min, 20)];
        [label setTransform:CGAffineTransformMakeRotation(M_PI)];
    }
    else // Landscape left
    {
        [statut setFrame:CGRectMake(0, -20, min, 20)];
        [label setTransform:CGAffineTransformIdentity];
    }
    [label setFrame:[statut bounds]];
}

@end
