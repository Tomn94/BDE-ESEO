//
//  EventsHistoryTVC.m
//  ESEOmega
//
//  Created by Tomn on 11/01/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

#import "EventsHistoryTVC.h"

@implementation EventsHistoryTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.929 green:0.11 blue:0.141 alpha:1];
    self.navigationController.navigationBar.tintColor    = [UIColor colorWithRed:0.9964 green:0.8461 blue:0.8497 alpha:1];
    
//    self.infosCmdSel = nil;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.refreshControl.tintColor = self.navigationController.navigationBar.barTintColor;
    
    /*
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
        (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable))
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];*/
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(loadEventsCmds) name:@"eventsCmds" object:nil];
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isLowPowerModeEnabled)])
        [ctr addObserver:self selector:@selector(majTimerRecup)
                    name:NSProcessInfoPowerStateDidChangeNotification object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"debugRefresh" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"eventsCmdsSent" object:nil];
    [ctr addObserver:self selector:@selector(commandeValidee:) name:@"finEventCmdGoLydia" object:nil];
    
    [self loadEventsCmds];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self.refreshControl endRefreshing];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [upd invalidate];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [cmd count];
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [cmd[section] count];
}

- (NSString *) tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && [cmd[section] count])
        return @"Événements à venir";
    if ([cmd[section] count])
        return @"Événements passés";
    return nil;
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EventsHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventsHistoryCell" forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsMake(0, 79, 0, 0);
    
    NSDictionary *commande = cmd[indexPath.section][indexPath.row];
    
    UIColor *color;
    
    cell.nomLabel.font = [UIFont systemFontOfSize:16];
    cell.prixLabel.font = [UIFont systemFontOfSize:16];
    cell.dateLabel.textColor = [UIColor darkGrayColor];
    cell.numLabel.textColor = [UIColor darkGrayColor];
    
    cell.imgView.contentMode = UIViewContentModeCenter;
    if (indexPath.section == 0)
    {
        color = [UIColor colorWithRed:1 green:45/255. blue:85/255. alpha:1];
        cell.nomLabel.font = [UIFont boldSystemFontOfSize:16];
        cell.prixLabel.font = [UIFont boldSystemFontOfSize:16];
        [cell.imgView setImage:[UIImage imageNamed:@"eventUp"]];
    }
    else
    {
        color = [UIColor darkGrayColor];
        cell.dateLabel.textColor = [UIColor lightGrayColor];
        cell.numLabel.textColor = [UIColor lightGrayColor];
        [cell.imgView setImage:[UIImage imageNamed:@"eventDone"]];
    }
    
    cell.nomLabel.textColor = color;
    cell.prixLabel.textColor = color;
    
    cell.color = color;
    cell.imgView.layer.cornerRadius = 24;
    cell.imgView.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    cell.imgView.layer.shadowOffset = CGSizeMake(0, 1);
    cell.imgView.layer.shadowOpacity = 1;
    cell.imgView.layer.shadowRadius = 1;
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    [numberFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"fr_FR"]];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    cell.nomLabel.text = commande[@"name"];
    cell.dateLabel.text = [NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:commande[@"datetime"]]
                                                         dateStyle:NSDateFormatterFullStyle
                                                         timeStyle:NSDateFormatterShortStyle];
    cell.prixLabel.text = [numberFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:[commande[@"price"] stringValue]]];
    cell.numLabel.text = [NSString stringWithFormat:@"%@%03d", commande[@"strcmd"], [commande[@"modcmd"] intValue]];
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *commande = cmd[indexPath.section][indexPath.row];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Réservation validée"
                                                                   message:@"Les informations nécessaires ont été envoyées à l'adresse mail fournie lors de la réservation.\nAu moindre problème, contactez-nous."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Renvoyer la place par mail"
                                             style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [[Data sharedData] sendMail:@{ @"id": [commande[@"idlydia"] stringValue],
                                                                               @"cat": @"EVENT" }
                                                                       inVC:self];
                                           }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction) fermer:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) reserver:(id)sender
{
    UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [spin startAnimating];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:spin] animated:YES];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    NSURL *url = [NSURL URLWithString:@"https://itunes.apple.com/fr/lookup?bundleId=com.eseomega.ESEOmega"];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:url
                                                   completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          UIAlertController *alert = nil;
                                          BOOL nvApp = NO;
                                          
                                          if (error == nil && data != nil)
                                          {
                                              NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                                   options:kNilOptions
                                                                                                     error:nil];
                                              if (JSON == nil || JSON[@"results"] == nil || [JSON[@"results"] count] < 1)
                                                  alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                              message:@"Impossible de vérifier si l'application est à jour"
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                                              else if ([JSON[@"results"][0][@"version"] doubleValue] > [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] doubleValue])
                                              {
                                                  nvApp = YES;
                                                  alert = [UIAlertController alertControllerWithTitle:NEW_UPD_TI
                                                                                              message:NEW_UPD_TE
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                                              }
                                              else
                                                  [self verifsCommande];
                                          }
                                          else
                                              alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                          message:@"Impossible de récupérer la dernière version de l'application"
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                          if (alert != nil)
                                          {
                                              [self.navigationItem setLeftBarButtonItem:_ajoutBtn animated:YES];
                                              
                                              if (nvApp)
                                                  [alert addAction:[UIAlertAction actionWithTitle:NEW_UPD_BT style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
                                                  }]];
                                              [alert addAction:[UIAlertAction actionWithTitle:(nvApp) ? @"Annuler" : @"OK" style:UIAlertActionStyleCancel handler:nil]];
                                              [self presentViewController:alert animated:YES completion:nil];
                                          }
                                      }];
    [dataTask resume];
    [[Data sharedData] updLoadingActivity:YES];
}

- (void) verifsCommande
{
    if (![Data estConnecte])
        return;
    
    UIAlertController *alert = nil;
    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    if (![[timeZone name] isEqualToString:@"Europe/Paris"])
    {
        alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                    message:@"L'accès à la réservation ne peut se faire depuis un autre pays que la France.\nEnvoyez-nous une carte postale !"
                                             preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"D'accord" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self.navigationItem setLeftBarButtonItem:_ajoutBtn animated:YES];
        [[Data sharedData] updLoadingActivity:NO];
        return;
    }
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:URL_EVENT_NE];
    NSString *client = [Data encoderPourURL:[JNKeychain loadValueForKey:@"login"]];
    NSString *pass   = [Data encoderPourURL:[JNKeychain loadValueForKey:@"passw"]];
    NSString *body = [NSString stringWithFormat:@"client=%@&password=%@&os=%@&hash=%@",
                      client, pass, @"IOS",
                      [Data encoderPourURL:[Data hashed_string:[[[@"(c) Team Sheep Dev" stringByAppendingString:client] stringByAppendingString:pass]stringByAppendingString:@"IOS"]]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request
                                                       completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                          message:@"Impossible de se connecter au serveur\nSi le problème persiste, vous pouvez toujours venir commander au comptoir."
                                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                          
                                          if (error == nil && data != nil)
                                          {
                                              NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                                   options:kNilOptions
                                                                                                     error:nil];
                                              switch ([JSON[@"status"] intValue])
                                              {
                                                  case 1:
                                                      alert = nil;
                                                      [self showCommande:JSON[@"data"]];
                                                      break;
                                                      
                                                  case -2:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Impossible de vous connecter avec ce nom d'utilisateur/mot de passe.\n\nSi vous avez changé de mot de passe récemment, merci de bien vouloir vous déconnecter puis reconnecter."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -3:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Le système n'est pas ouvert aujourd'hui ou le système est en maintenance"
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -6:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Le système est en maintenance pour iOS, nous sommes en train de corriger cela."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -7:
                                                  {
                                                      NSString *raison = (![JSON[@"cause"] isEqualToString:@""])
                                                      ? [@"Raison :\n" stringByAppendingString:JSON[@"cause"]]
                                                      : @"Raison inconnue.";
                                                      alert = [UIAlertController alertControllerWithTitle:@"Vous n'êtes pas autorisé à accéder au service"
                                                                                                  message:raison
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                  }
                                                      
                                                  case -8:
                                                      alert = [UIAlertController alertControllerWithTitle:NEW_UPD_TI
                                                                                                  message:NEW_UPD_TE
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                                      
                                                  case -10:
                                                      alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                  message:@"Impossible de détecter si vous êtes bien sur iOS…\nSi le problème persiste, vous pouvez toujours venir commander au comptoir."
                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                      break;
                                              }
                                          }
                                          
                                          if (alert != nil)
                                          {
                                              [self.navigationItem setLeftBarButtonItem:_ajoutBtn animated:YES];
                                              if ([alert.title isEqualToString:NEW_UPD_TI])
                                                  [alert addAction:[UIAlertAction actionWithTitle:NEW_UPD_BT style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_APPSTORE]];
                                                  }]];
                                              [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                                              [self presentViewController:alert animated:YES completion:nil];
                                          }
                                      }];
    [dataTask resume];
    [[Data sharedData] updLoadingActivity:YES];
    
    if (alert != nil)
    {
        [self.navigationItem setLeftBarButtonItem:_ajoutBtn animated:YES];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void) showCommande:(NSDictionary *)dataToken
{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:URL_EVENT_DT];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:url
                                                   completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          [self.navigationItem setLeftBarButtonItem:_ajoutBtn animated:YES];
                                          UIAlertController *alert = nil;
                                          
                                          if (dataToken[@"token"] != nil && ![dataToken[@"token"] isEqualToString:@""] &&
                                              error == nil && data != nil)
                                          {
                                              NSArray *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                              options:kNilOptions
                                                                                                error:nil];
                                              if (JSON == nil || [JSON count] < 1)
                                                  alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                              message:@"Impossible d'interpréter les réservations disponibles"
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                                              else
                                              {
                                                  [[Data sharedData] setCafetData:JSON];
                                                  [[Data sharedData] setCafetToken:dataToken[@"token"]];
                                                  
                                                  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Events" bundle:nil];
                                                  UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"EventsOrder"];
                                                  vc.modalTransitionStyle = (iPAD || (!iPAD && [UIScreen mainScreen].bounds.size.width >= 736 && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))) ? UIModalTransitionStyleCoverVertical : UIModalTransitionStyleFlipHorizontal;
                                                  vc.modalPresentationStyle = UIModalPresentationFormSheet;
                                                  [self presentViewController:vc animated:YES completion:nil];
                                              }
                                          }
                                          else
                                              alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                          message:@"Impossible de récupérer les réservations disponibles"
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                          if (alert != nil)
                                          {
                                              [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                                              [self presentViewController:alert animated:YES completion:nil];
                                          }
                                      }];
    [dataTask resume];
    [[Data sharedData] updLoadingActivity:YES];
}

- (void) majTimerRecup
{
    [upd invalidate];
    nbrUpd = 0;
    
    if (![Data estConnecte])
        return;
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isLowPowerModeEnabled)] &&
        [[NSProcessInfo processInfo] isLowPowerModeEnabled])
        return;
    
    upd = [NSTimer scheduledTimerWithTimeInterval:42
                                           target:self
                                         selector:@selector(recupCommandes:)
                                         userInfo:nil
                                          repeats:YES];
    [upd setTolerance:21];
}

- (void) loadEventsCmds
{
    if ([[Data sharedData] eventsCmds] == nil)
    {
        cmd = [NSArray array];
        [self.tableView reloadData];
        return;
    }
    
    NSArray *eventsBruts = [[Data sharedData] eventsCmds][@"tickets"];
    NSMutableArray *t_cmd = [NSMutableArray array];
    for (int i = 0 ; i < 2 ; ++i)
        [t_cmd addObject:[NSMutableArray new]];
    for (NSDictionary *event in eventsBruts)
    {
        BOOL ajoute = NO;
        NSMutableDictionary *ev = [NSMutableDictionary dictionaryWithDictionary:event];
        for (NSDictionary *e in [[Data sharedData] events][@"events"])
        {
            for (NSDictionary *ticket in e[@"tickets"])
            {
                if ([ticket[@"id"] isEqualToString:ev[@"idevent"]])
                {
//                    [ev setValue:e[@"titre"] forKey:@"nom"];
                    
                    NSDateFormatter *df = [NSDateFormatter new];
                    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSDate *date = [df dateFromString:e[@"dateFin"]];
                    if ([[NSDate date] compare:date] == NSOrderedAscending)
                        [t_cmd[0] addObject:ev];
                    else
                        [t_cmd[1] addObject:ev];
                    ajoute = YES;
                    break;
                }
            }
        }
        if (!ajoute)
            [t_cmd[1] addObject:ev];
    }
    cmd = [NSArray arrayWithArray:t_cmd];
    
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (IBAction) refresh:(UIRefreshControl *)sender
{
    [self recupCommandes:NO];
}

- (void) recupCommandes:(BOOL)forcer
{
    if (!forcer && ![[Data sharedData] shouldUpdateJSON:@"eventsCmds"] && nbrUpd >= 60)
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    nbrUpd++;
    [[Data sharedData] updateJSON:@"eventsCmds"];
}

- (void) commandeValidee:(NSNotification *)n
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[Data sharedData] startLydia:[n.userInfo[@"idcmd"] intValue]
                              forType:n.userInfo[@"catOrder"]];
    }];
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"autreVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Vous n'avez pas acheté de places";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Tapez sur le bouton ＋ pour réserver,\nvos places s'afficheront ici.";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) buttonTitleForEmptyDataSet:(UIScrollView *)scrollView
                                           forState:(UIControlState)state
{
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0],
                                 NSForegroundColorAttributeName: self.tableView.tintColor};
    
    return [[NSAttributedString alloc] initWithString:@"Commander" attributes:attributes];
}

- (void) emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    [self reserver:scrollView];
}

- (CGPoint) offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2. - 50);
}

@end
