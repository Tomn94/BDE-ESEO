//
//  OrderPanierTVC.m
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

#import "OrderPanierTVC.h"

@implementation OrderPanierTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [[Data sharedData] setCafetCmdEnCours:NO];
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    [self rotateInsets];
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(rotateInsets) name:UIDeviceOrientationDidChangeNotification object:nil];
    [ctr addObserver:self selector:@selector(reloadTableViewData) name:@"updPanier" object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) rotateInsets
{
    CGFloat dec = 44 + self.navigationController.navigationBar.frame.size.height
                     + ((iPAD) ? 0 : [UIApplication sharedApplication].statusBarFrame.size.height);
    if (@available(iOS 11, *)) {
        dec = 44;
    }
    self.tableView.contentInset = UIEdgeInsetsMake(dec, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    [self.tableView reloadEmptyDataSet];
}

+ (NSDictionary *) dataForIDStr:(NSDictionary *)d
{
    NSArray *data = [[Data sharedData] cafetData];
    NSArray *elements = data[2][@"lacmd-elements"];
    NSArray *ingredients = data[3][@"lacmd-ingredients"];
    
    NSString *idstr = d[@"menu"];
    if (idstr != nil)
    {
        NSArray *menus = data[1][@"lacmd-menus"];
        
        for (NSDictionary *menu in menus)
        {
            if ([menu[@"idstr"] isEqualToString:idstr])
            {
                NSString *detail = @"";
                double price = [menu[@"price"] doubleValue];
                
                if (d[@"items"] != nil && [d[@"items"] count] > 0)
                {
                    for (NSDictionary *item in d[@"items"])
                    {
                        for (NSDictionary *element in elements)
                        {
                            if ([element[@"idstr"] isEqualToString:item[@"element"]])
                            {
                                price += [element[@"pricemore"] doubleValue];
                                if (![detail isEqualToString:@""])
                                    detail = [detail stringByAppendingString:@"\n"];
                                detail = [detail stringByAppendingString:@"– "];
                                detail = [detail stringByAppendingString:element[@"name"]];
                                
                                if (item[@"items"] != nil && [item[@"items"] count] > 0)
                                {
                                    NSInteger num = 0;
                                    detail = [detail stringByAppendingString:@" ("];
                                    for (NSString *itemElem in item[@"items"])
                                    {
                                        num++;
                                        for (NSDictionary *ingredient in ingredients)
                                        {
                                            if ([ingredient[@"idstr"] isEqualToString:itemElem])
                                            {
                                                if (num > [element[@"hasingredients"] integerValue])
                                                    price += [ingredient[@"priceuni"] doubleValue];
                                                if (num > 1)
                                                    detail = [detail stringByAppendingString:@", "];
                                                detail = [detail stringByAppendingString:ingredient[@"name"]];
                                            }
                                        }
                                    }
                                    detail = [detail stringByAppendingString:@")"];
                                }
                            }
                        }
                    }
                }
                
                if ([detail isEqualToString:@""])
                    detail = @"Menu";
                
                return @{ @"name"  : menu[@"name"],
                          @"price" :@(price),
                          @"detail": detail };
            }
        }
    }
    else
    {
        idstr = d[@"element"];
        
        for (NSDictionary *element in elements)
        {
            if ([element[@"idstr"] isEqualToString:idstr])
            {
                NSString *detail = @"";
                double price = [element[@"priceuni"] doubleValue];
                
                if (d[@"items"] != nil && [d[@"items"] count] > 0)
                {
                    NSInteger num = 0;
                    for (NSString *item in d[@"items"])
                    {
                        num++;
                        for (NSDictionary *ingredient in ingredients)
                        {
                            if ([ingredient[@"idstr"] isEqualToString:item])
                            {
                                if (num > [element[@"hasingredients"] integerValue])
                                    price += [ingredient[@"priceuni"] doubleValue];
                                if (![detail isEqualToString:@""])
                                    detail = [detail stringByAppendingString:@", "];
                                detail = [detail stringByAppendingString:ingredient[@"name"]];
                            }
                        }
                    }
                }
                
                if ([detail isEqualToString:@""])
                {
                    NSArray *categories = data[0][@"lacmd-categories"];
                    for (NSDictionary *categorie in categories)
                        if ([element[@"idcat"] isEqualToString:categorie[@"catname"]])
                            detail = categorie[@"name"];
                }
                
                return @{ @"name"  : element[@"name"],
                          @"price" : @(price),
                          @"detail": detail };
            }
        }
    }
    
    /*
    for (NSDictionary *ingredient in ingredients)
        if ([ingredient[@"idstr"] isEqualToString:idstr])
            return @{ @"name"  : ingredient[@"name"],
                      @"price" : ingredient[@"priceuni"],
                      @"detail": @""};*/
    
    return [NSDictionary dictionary];
}

- (double) getTotalPrice
{
    double somme = 0.;
    for (NSDictionary *element in [[Data sharedData] cafetPanier])
        somme += [[OrderPanierTVC dataForIDStr:element][@"price"] doubleValue];
    return somme;
}

- (void) lancerCommande
{
    UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"Voulez-vous ajouter un commentaire ?"
                                                                    message:@"Vous pouvez taper ci-dessous quelques indications pour votre commande."
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [alert2 addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField)
     {
         textField.placeholder            = @"Consignes, …";
         textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
         textField.autocorrectionType     = UITextAutocorrectionTypeYes;
         textField.delegate               = self;
     }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Finaliser la commande"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Valider la commande ?"
                                                                       message:@"En validant, vous vous engagez à payer et récupérer votre repas au comptoir de la cafet aujourd'hui aux horaires d'ouverture.\n☝🏼\nSi ce n'est pas le cas, il vous sera impossible de passer une nouvelle commande dès demain."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Je confirme, j'ai faim !"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action)
            {
                [[Data sharedData] setCafetCmdEnCours:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"updPanier" object:nil];
                LAContext *context = [LAContext new];
                context.localizedFallbackTitle = @"";
                NSError *error = nil;
                if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
                    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                            localizedReason:@"Valide l'envoi de votre commande"
                                      reply:^(BOOL success, NSError *error)
                     {
                         /*UIAlertController *alert = nil;
                         if (error)NSLog(@"erreur %@", error.localizedDescription);
                         alert = [UIAlertController alertControllerWithTitle:@"La commande n'a pas été validée"
                                                                     message:@"Une erreur est survenue lors de la validation de votre identité."
                                                              preferredStyle:UIAlertControllerStyleAlert];
                         else */if (success)
                             [self sendPanier];
                         else
                         {
                             [[Data sharedData] setCafetCmdEnCours:NO];
                             [self.tableView reloadData];
//                             [[NSNotificationCenter defaultCenter] postNotificationName:@"updPanier" object:nil];
                         }
                         /*else NSLog(@"!success %@", error.localizedDescription);
                         alert = [UIAlertController alertControllerWithTitle:@"La commande n'a pas été validée"
                                                                     message:@"Est-ce vraiment vous ? Impossible de vous reconnaître…"
                                                              preferredStyle:UIAlertControllerStyleAlert];
                         
                         if (alert != nil)
                         {
                             [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                             [self.navigationController presentViewController:alert animated:YES completion:nil];
                         }*/
                     }];
                }
                else
                    [self sendPanier];
            }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
    [alert2 addAction:confirmAction];
    [alert2 addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                               style:UIAlertActionStyleCancel
                                             handler:nil]];
    [alert2 setPreferredAction:confirmAction];
    [self presentViewController:alert2 animated:YES completion:nil];
}

- (void) sendPanier
{
    [self.tableView reloadData];
    
    if ([[[Data sharedData] cafetPanier] count] < 1)
    {
        [[Data sharedData] setCafetCmdEnCours:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updPanier" object:nil];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hm… 🌚"
                                                                       message:@"Impossible de valider un panier vide. Ajoutez quelques éléments de la carte d'abord."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self.tableView reloadData];
        return;
    }
    
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSError *error = nil;
    NSData *panierJSON = [NSJSONSerialization dataWithJSONObject:[[Data sharedData] cafetPanier]
                                                       options:kNilOptions
                                                         error:&error];
    NSData *instruct   = [txtInstructions dataUsingEncoding:NSUTF8StringEncoding];
    if (error != nil)
    {
        [[Data sharedData] setCafetCmdEnCours:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updPanier" object:nil];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                       message:@"Impossible d'analyser votre panier, merci de nous contacter.\nVous pouvez toujours venir commander au comptoir."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self.tableView reloadData];
        return;
    }
    NSString *panier = [panierJSON base64EncodedStringWithOptions:0];
    NSString *instru = [instruct base64EncodedStringWithOptions:0];
    NSString *body = [NSString stringWithFormat:@"token=%@&data=%@&instructions=%@",
                      [Data encoderPourURL:[[Data sharedData] cafetToken]],
                      [Data encoderPourURL:panier],
                      (instru == nil) ? @"" : [Data encoderPourURL:instru]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URL_CMD_SEND]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request
                                                       completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          UIAlertController *alert = nil;
                                          
                                          if (error == nil && data != nil)
                                          {
                                              NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                                   options:kNilOptions
                                                                                                     error:nil];
                                              switch ([JSON[@"status"] intValue])
                                              {
                                                  case 1:
                                                  {
                                                      BOOL cbOK = JSON[@"data"][@"idcmd"] && [JSON[@"data"][@"idcmd"] integerValue] > 0 &&
                                                                 [JSON[@"data"][@"price"] doubleValue] >= 0.5 &&
                                                                 [JSON[@"data"][@"price"] doubleValue] <= 250.0 && 
                                                                 [JSON[@"data"][@"lydia_enabled"] boolValue];
                                                      alert = [UIAlertController alertControllerWithTitle:(cbOK) ? @"Commande validée !\nComment voulez-vous la payer ?" : @"Commande validée !"
                                                                                                  message:@"Celle-ci est en cours de préparation et sera disponible après avoir payé.\nVous serez averti d'une notification (si activées) quand elle vous attendra au comptoir.\nBon appétit ! 👌🏼"
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      if (cbOK) {
                                                          UIAlertAction *payNowAction = [UIAlertAction actionWithTitle:@"Payer immédiatement (Lydia 💳)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                              [[NSNotificationCenter defaultCenter] postNotificationName:@"cmdValideLydia"
                                                                                                                  object:nil userInfo:@{ @"idcmd": @([JSON[@"data"][@"idcmd"] integerValue]), @"catOrder" : @"CAFET" }];
                                                              [[Data sharedData] updateJSON:@"cmds"];
                                                          }];
                                                          [alert addAction:payNowAction];
                                                          [alert setPreferredAction:payNowAction];
                                                      }
                                                      
                                                      [alert addAction:[UIAlertAction actionWithTitle:(cbOK) ? @"Payer plus tard au comptoir 💰" : @"Merci !"
                                                                                                style:(cbOK) ? UIAlertActionStyleDefault : UIAlertActionStyleCancel
                                                                                              handler:^(UIAlertAction * action) {
                                                          [[NSNotificationCenter defaultCenter] postNotificationName:@"cmdValide"
                                                                                                              object:nil];
                                                          [[Data sharedData] updateJSON:@"cmds"];
                                                      }]];
                                                      break;
                                                  }
                                                      
                                                  case -1:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Quelqu'un a déjà commandé avec votre identifiant temporaire de commande.\nMerci de venir nous voir au comptoir."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -2:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Votre commande n'est plus valide (plus de 10 minutes se sont écoulées).\nMerci de venir nous voir au comptoir."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -3:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Votre identifiant de commande est invalide.\nMerci de venir nous voir au comptoir."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -4:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Impossible de décoder votre panier.\nMerci de venir nous voir au comptoir."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  default:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur inconnue"
                                                                                                  message:@"Votre commande a sûrement été déjà validée.\nMerci de venir nous voir au comptoir."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                              }
                                          }
                                          else
                                              alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                          message:@"Impossible de se connecter au serveur\nSi le problème persiste, vous pouvez toujours venir commander au comptoir."
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                          if (alert != nil)
                                          {
                                              if ([alert.actions count] < 1)
                                              {
                                                  [[Data sharedData] setCafetCmdEnCours:NO];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:@"updPanier" object:nil];
                                                  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                                              }
                                              [self presentViewController:alert animated:YES completion:nil];
                                              [self.tableView reloadData];
                                          }
                                      }];
    [dataTask resume];
    [[Data sharedData] updLoadingActivity:YES];
}

#pragma mark - Table view data source

- (void) reloadTableViewData
{
    [self.tableView setEditing:NO animated:YES];
    [self.tableView reloadData];
    [self.tableView reloadEmptyDataSet];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([[[Data sharedData] cafetPanier] count])
        return 3;  // Panier + Total + Valider
    return 0;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    NSUInteger panierC = [[[Data sharedData] cafetPanier] count];
    if (section)
        return 1;
    return panierC;
}


- (CGFloat)   tableView:(nonnull UITableView *)tableView
heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.section)
        return 44;
    
    NSString *cellText = [OrderPanierTVC dataForIDStr:[[Data sharedData] cafetPanier][indexPath.row]][@"detail"];
    UIFont *cellFont = [UIFont systemFontOfSize:11];
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:cellText
                                                                         attributes:@{ NSFontAttributeName: cellFont }];
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(tableView.bounds.size.width - ((self.tableView.isEditing) ? 140 : 100), CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    return MAX(44, rect.size.height + 30);
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        OrderItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"orderItemCell" forIndexPath:indexPath];
        NSDictionary *data = [OrderPanierTVC dataForIDStr:[[Data sharedData] cafetPanier][indexPath.row]];
        cell.titre.text = data[@"name"];
        cell.detail.text = data[@"detail"];
        cell.prix.text = [[NSString stringWithFormat:@"%.2f €", [data[@"price"] doubleValue]] stringByReplacingOccurrencesOfString:@"."
                                                                                                                        withString:@","];
        return cell;
    }
    else if (indexPath.section == 1)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"orderTotalCell" forIndexPath:indexPath];
        cell.detailTextLabel.text = [[NSString stringWithFormat:@"%.2f €", [self getTotalPrice]] stringByReplacingOccurrencesOfString:@"." withString:@","];
        cell.textLabel.text = (self.tableView.isEditing) ? @"Vider tout le panier" : @"Total";
        return cell;
    }
    else
    {
        OrderConfirmCell *cell = [tableView dequeueReusableCellWithIdentifier:@"orderConfirmCell" forIndexPath:indexPath];
        if ([[Data sharedData] cafetCmdEnCours])
            [cell.button setTitle:@"Envoi de la commande…" forState:UIControlStateNormal];
        else
            [cell.button setTitle:@"Valider la commande" forState:UIControlStateNormal];
        [cell.button setEnabled:(![[Data sharedData] cafetCmdEnCours] && !self.tableView.isEditing)];
        [cell setSelectionStyle:([[Data sharedData] cafetCmdEnCours]) ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault];
        return cell;
    }
    
    return nil;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![[Data sharedData] cafetCmdEnCours] && indexPath.section == 2)
        [self lancerCommande];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) setEditing:(BOOL)editing
           animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if ([self.tableView numberOfSections] > 0)
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:0 inSection:2]]
                              withRowAnimation:UITableViewRowAnimationFade];
//    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSRangeFromString(@"{0,2}")]
//                  withRowAnimation:UITableViewRowAnimationFade];
}

- (BOOL)    tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section < 2 && ![[Data sharedData] cafetCmdEnCours];
}

- (void) tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if (!indexPath.section)
            [[Data sharedData] cafetPanierSupprimerAt:indexPath.row];
        else if (indexPath.section == 1)
            [[Data sharedData] cafetPanierVider];
        if ([[[Data sharedData] cafetPanier] count] < 1)
            [self setEditing:NO animated:YES];
    }
}

- (NSString *) tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    if (!section)
        return @"Votre panier";
    /*else if (section == 2)
        return @" ";*/
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView
 titleForFooterInSection:(NSInteger)section
{
    if (section == 2)
        return @"Le paiement par carte n'est disponible que pour un panier ≥ 0,50 €. 💳\n\nLe saviez-vous ? 🎂\nUn menu vous est offert le jour de votre anniversaire !";
    return nil;
}

#pragma mark - text field delegate

- (BOOL)            textField:(nonnull UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
            replacementString:(nonnull NSString *)string
{
    NSString  *proposedNewString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString  *result = [proposedNewString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL ok = result.length <= 100;
    
    if (ok)
        txtInstructions = result;
    
    return ok;
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    if (!iPAD && [UIScreen mainScreen].bounds.size.height <= 320 && (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]) || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown))
        return nil;
    return [UIImage imageNamed:(arc4random_uniform(2)) ? @"cafetVide1" : @"cafetVide2"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Vous n'avez encore rien ajouté à votre panier !";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Sélectionnez des éléments dans l'onglet Carte.\n\nLe saviez-vous ? 🎂\nUn menu vous est offert le jour de votre anniversaire !";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

@end
