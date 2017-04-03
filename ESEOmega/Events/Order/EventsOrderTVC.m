//
//  EventsOrderTVC.m
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

#import "EventsOrderTVC.h"
#import "BDE_ESEO-Swift.h"

@implementation EventsOrderTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    messageQuitterVu = NO;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Événements"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil action:nil];
    
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    dataShuttles = [[Data sharedData] cafetData][0][@"event-navettes"];
    NSArray *events = [[Data sharedData] events][@"events"];
    NSMutableArray *t_dataEvent        = [NSMutableArray array];
    NSMutableArray *t_dataEventTickets = [NSMutableArray array];
    for (NSDictionary *event in events)
    {
        BOOL ajouterEvent = NO;
        CGFloat minPrice  = 65640.;
        NSDate *dateFin   = [df dateFromString:event[@"dateFin"]];
        if ([event[@"tickets"] count] && [dateFin compare:[NSDate date]] == NSOrderedDescending)
        {
            NSMutableArray *ticketsInfos = [NSMutableArray array];
            for (NSDictionary *ticket in event[@"tickets"])
            {
                if ([ticket[@"dispo"] boolValue])
                {
                    if ([ticket[@"prix"] doubleValue] < minPrice)
                        minPrice = [ticket[@"prix"] doubleValue];
                    [ticketsInfos addObject:ticket];
                    ajouterEvent = YES;
                }
            }
            [t_dataEventTickets addObject:ticketsInfos];
            if (ajouterEvent)
            {
                NSMutableDictionary *dE = [NSMutableDictionary dictionaryWithDictionary:event];
                [dE setObject:@(minPrice) forKey:@"minPrice"];
                [t_dataEvent addObject:[NSDictionary dictionaryWithDictionary:dE]];
            }
        }
    }
    dataEvents        = [NSArray arrayWithArray:t_dataEvent];
    dataEventsTickets = [NSArray arrayWithArray:t_dataEventTickets];
    
    if ([dataEvents count])
    {
        [self.tableView setBackgroundColor:[UIColor whiteColor]];
        self.tableView.tableFooterView = nil;
    }
    else
    {
        [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        self.tableView.tableFooterView = [UIView new];
    }
    
    [[Data sharedData] setCafetCmdEnCours:NO];
    [[Data sharedData] setCafetDebut:[[NSDate date] timeIntervalSinceReferenceDate]];
    [NSTimer scheduledTimerWithTimeInterval:MAX_ORDER_TIME target:self selector:@selector(timeout) userInfo:nil repeats:NO];
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(fermerForcer) name:@"cmdValide" object:nil];
    [ctr addObserver:self selector:@selector(fermerForcerLydia:) name:@"cmdValideLydia" object:nil];
    [ctr addObserver:self selector:@selector(timeout) name:@"retourAppCafetFin" object:nil];
    [ctr addObserver:self selector:@selector(validerAchatN:) name:@"commandeNavetteOK" object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [ThemeManager useEventThemeOn:self.navigationController];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [ThemeManager updateThemeWithAppIcon:false];
}

- (void) timeout
{
    if (messageQuitterVu)
        return;
    messageQuitterVu = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Votre commande a expiré"
                                                                   message:@"Pour des raisons de sécurité, il n'est possible de passer commande que pendant 10 minutes sans valider.\nMerci de bien vouloir recommencer. 😇"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self fermerForcer];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction) fermer:(id)sender
{
    [self fermerForcer];
}

- (void) fermerForcer
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[Data sharedData] setCafetCmdEnCours:NO];
        [[Data sharedData] setCafetToken:@""];
        [[Data sharedData] setCafetDebut:0];
    }];
}

- (void) fermerForcerLydia:(NSNotification *)n
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[Data sharedData] setCafetCmdEnCours:NO];
        [[Data sharedData] setCafetToken:@""];
        [[Data sharedData] setCafetDebut:0];
        [[Data sharedData] startLydia:[n.userInfo[@"idcmd"] intValue]
                              forType:n.userInfo[@"catOrder"]];
    }];
}

#pragma mark - Actions

- (void) chooseShuttleFor:(NSDictionary *)ticket
{
    EventsOrderNavTVC *detail = [[EventsOrderNavTVC alloc] initWithStyle:UITableViewStyleGrouped
                                                                 andData:ticket];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void) validerAchat:(NSDictionary *)achat
{
    double prixAchat = [achat[@"ticket"][@"prix"] doubleValue];
    if (prixAchat < 0.5 || prixAchat > 250.0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Impossible d'acheter ce produit"
                                                                       message:@"Un paiement Lydia ne peut être effectué qu'entre 0.5 et 250 €."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSString *prix = [[NSString stringWithFormat:@"%.2f", prixAchat] stringByReplacingOccurrencesOfString:@"."
                                                                                               withString:@","];
    
    NSString *resume = [NSString stringWithFormat:@"%@\n%@ · %@ €", achat[@"ticket"][@"donneesEvenement"][@"titre"],
                        achat[@"ticket"][@"nom"], prix];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    if (achat[@"navette"] != nil)
    {
        NSString *depart  = [NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:achat[@"navette"][@"departure"]]
                                                           dateStyle:NSDateFormatterShortStyle
                                                           timeStyle:NSDateFormatterShortStyle];
        NSString *arrivee = [NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:achat[@"navette"][@"arrival"]]
                                                           dateStyle:NSDateFormatterNoStyle
                                                           timeStyle:NSDateFormatterShortStyle];
        resume = [NSString stringWithFormat:@"%@\n%@ → %@ (%@)", resume, depart, arrivee, achat[@"navette"][@"departplace"]];
    }
    else
    {
        NSString *date = [NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:achat[@"ticket"][@"donneesEvenement"][@"date"]]
                                                        dateStyle:NSDateFormatterMediumStyle
                                                        timeStyle:NSDateFormatterShortStyle];
        resume = [NSString stringWithFormat:@"%@\n%@", resume, date];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmez-vous votre achat ?"
                                                                   message:[resume stringByAppendingString:@"\n\n⚠️ Les réservations sont nominatives.\nS'il s'agit d'une place pour événement, une pièce d'identité peut vous être demandée à l'entrée.\nLes CGV s'appliquent."]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Valider et payer ma place" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                LAContext *context = [LAContext new];
                                                context.localizedFallbackTitle = @"";
                                                NSError *error = nil;
                                                if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
                                                    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                                                            localizedReason:@"Valide l'envoi de votre réservation"
                                                                      reply:^(BOOL success, NSError *error)
                                                     {
                                                         if (success)
                                                             [self sendAchat:achat];
                                                     }];
                                                }
                                                else
                                                    [self sendAchat:achat];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) validerAchatN:(NSNotification *)notif
{
    [self validerAchat:notif.userInfo];
}

- (void) sendAchat:(NSDictionary *)achat
{
    [[Data sharedData] setCafetCmdEnCours:YES];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSError *error = nil;
    if (error != nil)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                       message:@"Impossible d'analyser votre commande, merci de nous contacter."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self.tableView reloadData];
        return;
    }
    NSData *idEvent = [achat[@"ticket"][@"id"] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *body  = [NSString stringWithFormat:@"token=%@&idevent=%@",
                       [Data encoderPourURL:[[Data sharedData] cafetToken]],
                       [Data encoderPourURL:[idEvent base64EncodedStringWithOptions:0]]];
    if (achat[@"navette"] != nil)
    {
        NSData *navette = [[achat[@"navette"][@"idshuttle"] stringValue] dataUsingEncoding:NSUTF8StringEncoding];
        body = [body stringByAppendingString:[NSString stringWithFormat:@"&nav=%@",
                                              [Data encoderPourURL:[navette base64EncodedStringWithOptions:0]]]];
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URL_EVENT_SD]];
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
                                                      [self dismissViewControllerAnimated:YES completion:^{
                                                          [[Data sharedData] setCafetCmdEnCours:NO];
                                                          [[Data sharedData] setCafetToken:@""];
                                                          [[Data sharedData] setCafetDebut:0];
                                                          [[NSNotificationCenter defaultCenter] postNotificationName:@"finEventCmdGoLydia"
                                                                                                              object:nil
                                                                                                            userInfo:@{ @"idcmd": @([JSON[@"data"][@"idcmd"] integerValue]), @"catOrder" : @"EVENT" }];
                                                          [[Data sharedData] updateJSON:@"eventsCmds"];
                                                      }];
                                                      break;
                                                  }
                                                      
                                                  case -1:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Quelqu'un a déjà commandé avec votre identifiant temporaire de commande.\nMerci de venir nous voir."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -2:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Votre réservation n'est plus valide (plus de 10 minutes se sont écoulées)."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -3:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Votre identifiant de commande est invalide.\nMerci de nous contacter."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -4:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"L'événement dont vous souhaitez réserver une place n'est plus disponible à l'achat."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -5:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"La navette sélectionnée n'a plus de place disponible.\nChoisissez-en une autre !"
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  default:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur inconnue"
                                                                                                  message:@"Votre réservation a sûrement été déjà validée.\nMerci de venir nous voir."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                              }
                                          }
                                          else
                                              alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                          message:@"Impossible de se connecter au serveur.\nSi le problème persiste, contactez-nous."
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                          if (alert != nil)
                                          {
                                              [[Data sharedData] setCafetCmdEnCours:NO];
                                              [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                                              [self presentViewController:alert animated:YES completion:nil];
                                          }
                                      }];
    [dataTask resume];
    [[Data sharedData] updLoadingActivity:YES];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [dataEvents count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OrderMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"orderMenuCell" forIndexPath:indexPath];
    
    NSDictionary *donnees        = dataEvents[indexPath.row];
//    NSArray      *donneesTickets = dataEventsTickets[indexPath.row];
    
    cell.nom.text = donnees[@"titre"];
    cell.detail.text = donnees[@"detail"];
    cell.prix.text = [[NSString stringWithFormat:@"À partir de %.2f €", [donnees[@"minPrice"] doubleValue]] stringByReplacingOccurrencesOfString:@"." withString:@","];
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
    
    NSDictionary *donnees = dataEvents[indexPath.row];
    NSArray      *donneesTickets = dataEventsTickets[indexPath.row];
    
    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:donnees[@"titre"]
                                                                    message:@"Choisissez votre achat :"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    for (NSDictionary *ticket in donneesTickets)
    {
        NSInteger nbrPlacesRest = 0;
        BOOL hasNavettes = NO;
        for (NSDictionary *navette in dataShuttles)
        {
            if ([ticket[@"id"] isEqualToString:navette[@"idevent"]])
            {
                nbrPlacesRest += [navette[@"restseats"] integerValue];
                hasNavettes = YES;
            }
        }
        
        NSString *prix = [[NSString stringWithFormat:@"%.2f", [ticket[@"prix"] doubleValue]] stringByReplacingOccurrencesOfString:@"."
                                                                                                                       withString:@","];
        NSMutableDictionary *t_ticket = [NSMutableDictionary dictionaryWithDictionary:ticket];
        [t_ticket setObject:donnees forKey:@"donneesEvenement"];
        if (nbrPlacesRest > 0 || !hasNavettes)
            [dialog addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ · %@ €", ticket[@"nom"], prix]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action)
                               {
                                   if (hasNavettes)
                                       [self chooseShuttleFor:t_ticket];
                                   else
                                       [self validerAchat:@{ @"ticket": t_ticket }];
                               }]];
    }
    
    [dialog addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:dialog animated:YES completion:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"autreVide2"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Aucun événement en vente actuellement";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Revenez plus tard !";
    
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
    return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2. - 50);
}

@end
