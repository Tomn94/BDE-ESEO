//
//  CommandesTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

#import "CommandesTVC.h"

@implementation CommandesTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.infosCmdSel = nil;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
        (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable))
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(loadCmds) name:@"cmds" object:nil];
    [ctr addObserver:self selector:@selector(loadService) name:@"service" object:nil];
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isLowPowerModeEnabled)])
        [ctr addObserver:self selector:@selector(majTimerRecup)
                    name:NSProcessInfoPowerStateDidChangeNotification object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"debugRefresh" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing) name:@"cmdsSent" object:nil];
    [ctr addObserver:self selector:@selector(upd) name:@"connecte" object:nil];
    [ctr addObserver:self selector:@selector(commander:) name:@"btnCommanderCafet" object:nil];
    
    [self loadCmds];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self.refreshControl endRefreshing];
    
    // Handoff
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.cafet"];
    activity.title = @"Cafet BDE ESEO";
    activity.webpageURL = [NSURL URLWithString:URL_ACTIVITY];
    if ([SFSafariViewController class])
    {
        activity.eligibleForSearch = YES;
        activity.eligibleForHandoff = YES;
        activity.eligibleForPublicIndexing = YES;
    }
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
    
    [self loadService];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self upd];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [upd invalidate];
}
/*
- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    UIView *headerView = self.tableView.tableHeaderView;
    
    [headerView setNeedsLayout];
    [headerView layoutIfNeeded];
//    return; 
    CGFloat height = [headerView systemLayoutSizeFittingSize:(UILayoutFittingCompressedSize)].height;
    CGRect frame = headerView.frame;
    frame.size.height = height;
    headerView.frame = frame;
    
    self.tableView.tableHeaderView = headerView;
}*/

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void) upd
{
    [self.navigationItem setLeftBarButtonItem:([Data estConnecte]) ? _ajoutBtn : nil animated:YES];
    [self majTimerRecup];
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
    
    upd = [NSTimer scheduledTimerWithTimeInterval:10
                                           target:self
                                         selector:@selector(recupCommandes:)
                                         userInfo:nil
                                          repeats:YES];
    [upd setTolerance:21];
}

- (void) recupCommandes:(BOOL)forcer
{
    if (!forcer && ![[Data sharedData] shouldUpdateJSON:@"cmds"] && nbrUpd >= 60)
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    nbrUpd++;
    [[Data sharedData] updateJSON:@"cmds"];
}

- (void) loadCmds
{
    if ([[Data sharedData] cmds] == nil)
    {
        cmd = [NSArray array];
        cmdStatus = [NSArray array];
        [self.tableView reloadData];
        return;
    }
    
    NSArray *cafetBrut = [[Data sharedData] cmds][@"history"];
    NSMutableArray *t_cmd = [NSMutableArray array];
    for (int i = 0 ; i < 4 ; ++i)
        [t_cmd addObject:[NSMutableArray new]];
    int enCours = 0;
    for (NSDictionary *entry in cafetBrut)
    {
        NSInteger index;
        if ([entry[@"status"] intValue] != Done)
            enCours++;
        switch ([entry[@"status"] intValue])
        {
            case NotPaid:
                index = 0;
                break;
                
            case Done:
                index = 3;
                break;
                
            case Ready:
                index = 1;
                break;
                
            case Preparing:
            default:
                index = 2;
                break;
        }
        [t_cmd[index] addObject:entry];
    }
    NSMutableArray *aSupprimer = [NSMutableArray array];
    for (int i = 0 ; i < 4 ; ++i)
    {
        if ([t_cmd[i] count] == 0)
            [aSupprimer addObject:t_cmd[i]];
    }
    [t_cmd removeObjectsInArray:aSupprimer];
    NSMutableArray *t_cmdStatus = [NSMutableArray array];
    for (NSArray *categorie in t_cmd)
    {
        [t_cmdStatus addObject:@([categorie[0][@"status"] intValue])];
    }
    cmd = [NSArray arrayWithArray:t_cmd];
    cmdStatus = [NSArray arrayWithArray:t_cmdStatus];
//    if ([cmd count])
//        [[Data sharedData] didUpdateJSON:@"cmds"];
    
    [self.tableView reloadData];
}

- (void) loadService
{
    CustomHeaderView *header = (CustomHeaderView *)self.tableView.tableHeaderView;
    header.serviceLabel.text = [[[Data sharedData] service][@"service"] stringByReplacingOccurrencesOfString:@"\\n"
                                                                                                  withString:@"\n"];
    
    CGRect frame = header.frame;
    CGSize labelSize = [header.serviceLabel.text boundingRectWithSize:CGSizeMake(self.tableView.bounds.size.width - 100, MAXFLOAT)
                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                           attributes:@{ NSFontAttributeName : header.serviceLabel.font }
                                                              context:nil].size;
    frame.size.height = labelSize.height + 15;
    header.frame = frame;
    
    self.tableView.tableHeaderView = header;
}

- (IBAction) refresh:(UIRefreshControl *)sender
{
    [self recupCommandes:NO];
}

- (IBAction) commander:(id)sender
{
    if (![Data estConnecte])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connectez-vous !"
                                                                       message:@"Connectez-vous grâce au bouton en haut à droite pour commander à la cafet !"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
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
                                              [self.navigationItem setLeftBarButtonItem:([Data estConnecte]) ? _ajoutBtn : nil animated:YES];
                                              
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
                                                    message:@"L'accès à la cafet ne peut se faire depuis un autre pays que la France.\nEnvoyez-nous une carte postale !"
                                             preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"D'accord" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self.navigationItem setLeftBarButtonItem:([Data estConnecte]) ? _ajoutBtn : nil animated:YES];
        [[Data sharedData] updLoadingActivity:NO];
        return;
    }
    
    //NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:[NSDate date]];
    //if (dc.hour >= 10 && dc.hour <= 12) // || (dc.hour == 13 && dc.minute <= 10))
    //{
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                       delegate:nil
                                                                                  delegateQueue:[NSOperationQueue mainQueue]];
    
        NSURL *url = [NSURL URLWithString:URL_CMD_NEW];
        NSString *client = [Data encoderPourURL:[JNKeychain loadValueForKey:@"login"]];
        NSString *pass   = [Data encoderPourURL:[JNKeychain loadValueForKey:@"passw"]];
        NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
        NSString *body = [NSString stringWithFormat:@"tstp=%@&client=%@&password=%@&os=%@&hash=%@",
                          timestamp, client, pass, @"IOS",
                          [Data encoderPourURL:[Data hashed_string:[[[[@"Mauvais Login / Mot de passe" stringByAppendingString:client] stringByAppendingString:pass] stringByAppendingString:timestamp] stringByAppendingString:@"IOS"]]]];
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
                                                          
                                                      case -1:
                                                          alert = [UIAlertController alertControllerWithTitle:@"Erreur 😏"
                                                                                                      message:@"On dirait que votre appareil n'est pas à l'heure.\nBien tenté, mais vous ne pouvez pas tricher pour commander à la cafet avant les autres."
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                          break;
                                                          
                                                      case -2:
                                                          alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                      message:@"Impossible de vous connecter avec ce nom d'utilisateur/mot de passe.\n\nSi vous avez changé de mot de passe récemment, merci de bien vouloir vous déconnecter puis reconnecter."
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                          break;
                                                          
                                                      case -3:
                                                          alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                      message:@"La cafet n'est pas ouverte aujourd'hui ou le système est en maintenance (dans ce cas vous pouvez toujours venir commander au comptoir)."
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                          break;
                                                          
                                                      case -4:
                                                          alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                      message:@"Vous ne pouvez pas commander, veuillez d'abord régler toutes vos commandes dues."
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                          break;
                                                          
                                                      case -6:
                                                          alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                                      message:@"Le système est en maintenance pour iOS, nous sommes en train de corriger cela.\nEn attendant, vous pouvez toujours commander au comptoir. ☺️"
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
                                                          
                                                      case -11:
                                                          alert = [UIAlertController alertControllerWithTitle:@"Vous n'êtes plus autorisé à commander"
                                                                                                      message:@"Vous ne pouvez pas passer plus de 3 commandes par jour ! Attendez demain …"
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                          break;
                                                  }
                                              }
                                              
                                              if (alert != nil)
                                              {
                                                  [self.navigationItem setLeftBarButtonItem:([Data estConnecte]) ? _ajoutBtn : nil animated:YES];
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
    /*}
    else
        alert = [UIAlertController alertControllerWithTitle:@"Revenez !"
                                                    message:@"La commande à la cafet n'est possible qu'entre 10h et 13h."
                                             preferredStyle:UIAlertControllerStyleAlert];*/
    
    if (alert != nil)
    {
        [self.navigationItem setLeftBarButtonItem:([Data estConnecte]) ? _ajoutBtn : nil animated:YES];
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
    
    NSURL *url = [NSURL URLWithString:URL_CMD_DATA];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:url
                                                   completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          [self.navigationItem setLeftBarButtonItem:([Data estConnecte]) ? _ajoutBtn : nil animated:YES];
                                          UIAlertController *alert = nil;
                                          
                                          if (dataToken[@"token"] != nil && ![dataToken[@"token"] isEqualToString:@""] &&
                                              error == nil && data != nil)
                                          {
                                              NSArray *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                              options:kNilOptions
                                                                                                error:nil];
                                              if (JSON == nil || [JSON count] < 1)
                                                  alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                              message:@"Impossible d'interpréter les menus"
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                                              else
                                              {
                                                  [[Data sharedData] setCafetCmdEnCours:NO];
                                                  [[Data sharedData] setCafetData:JSON];
                                                  [[Data sharedData] setCafetToken:dataToken[@"token"]];
                                                  
                                                  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
                                                  UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"Order"];
                                                  vc.modalTransitionStyle = (iPAD || (!iPAD && [UIScreen mainScreen].bounds.size.width >= 736 && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))) ? UIModalTransitionStyleCoverVertical : UIModalTransitionStyleFlipHorizontal;
                                                  vc.modalPresentationStyle = UIModalPresentationFormSheet;
                                                  [self presentViewController:vc animated:YES completion:nil];
                                              }
                                          }
                                          else
                                              alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                          message:@"Impossible de récupérer les menus"
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

- (void) masquerDetailModal
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (nullable NSString *) tableView:(nonnull UITableView *)tableView
          titleForHeaderInSection:(NSInteger)section
{
    NSArray *titresPluriel = @[@"En préparation", @"Prêtes", @"Terminées", @"Impayées"];    // Même ordre que enum CmdStatus
    NSArray *titresSingul  = @[@"En préparation", @"Prête",  @"Terminée",  @"Impayée"];
    NSUInteger nbr = [cmd[section] count];
    
    if (nbr > 1)
        return titresPluriel[[cmdStatus[section] intValue]];
    else if (nbr == 1)
        return titresSingul[[cmdStatus[section] intValue]];
    return nil;
}

- (nullable NSString *) tableView:(nonnull UITableView *)tableView
          titleForFooterInSection:(NSInteger)section
{
    NSArray *sousTitres = @[@"", @"Merci de venir à la cafet chercher votre repas.", @"",   // Même ordre que enum CmdStatus
                            @"Merci de venir à la cafet ou au BDE régler au plus vite, sinon contactez-nous."];
    NSUInteger nbr = [cmd[section] count];
    
    if (nbr > 0)
        return sousTitres[[cmdStatus[section] intValue]];
    return nil;
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommandesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commandeCell" forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsMake(0, 79, 0, 0);
    
    NSDictionary *commande = cmd[indexPath.section][indexPath.row];
    
    UIColor *color;
    
    cell.nomLabel.font = [UIFont systemFontOfSize:16];
    cell.prixLabel.font = [UIFont systemFontOfSize:16];
    cell.dateLabel.textColor = [UIColor darkGrayColor];
    cell.numLabel.textColor = [UIColor darkGrayColor];
    switch ([commande[@"status"] intValue])
    {
        case NotPaid:
            color = [UIColor colorWithRed:1 green:45/255. blue:85/255. alpha:1];
            cell.nomLabel.font = [UIFont boldSystemFontOfSize:16];
            cell.prixLabel.font = [UIFont boldSystemFontOfSize:16];
            [cell.imgView setImage:[UIImage imageNamed:@"cafetNotPaid"]];
            break;
            
        case Ready:
            color = [UIColor colorWithRed:0.549 green:0.824 blue:0 alpha:1];
            cell.nomLabel.font = [UIFont boldSystemFontOfSize:16];
            cell.prixLabel.font = [UIFont boldSystemFontOfSize:16];
            [cell.imgView setImage:[UIImage imageNamed:@"cafetReady"]];
            break;
            
        case Preparing:
            color = [UIColor colorWithRed:0 green:122/255. blue:1 alpha:1];
            [cell.imgView setImage:[UIImage imageNamed:@"cafetPreparing"]];
            break;
            
        case Done:
        default:
            color = [UIColor darkGrayColor];
            cell.dateLabel.textColor = [UIColor lightGrayColor];
            cell.numLabel.textColor = [UIColor lightGrayColor];
            [cell.imgView setImage:[UIImage imageNamed:@"cafetDone"]];
            break;
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
    
    cell.nomLabel.text = [commande[@"resume"] stringByReplacingOccurrencesOfString:@"<br>" withString:@", "];
    cell.dateLabel.text = [NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:commande[@"datetime"]]
                                                         dateStyle:NSDateFormatterFullStyle
                                                         timeStyle:NSDateFormatterShortStyle];
    cell.prixLabel.text = [numberFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:[commande[@"price"] stringValue]]];
    cell.numLabel.text = [NSString stringWithFormat:@"%@%03d", commande[@"strcmd"], [commande[@"modcmd"] intValue]];
    
    return cell;
}

- (nullable NSIndexPath *) tableView:(nonnull UITableView *)tableView
            willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    _infosCmdSel = cmd[indexPath.section][indexPath.row];
    
    return indexPath;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue
                  sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"commandeDetailSegue"])
    {
        CommandesDetailVC *destinationViewController = [segue destinationViewController];
        destinationViewController.infos = _infosCmdSel;
    }
}

#pragma mark - 3D Touch

- (UIViewController *) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
               viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (indexPath != nil)
    {
        _infosCmdSel = cmd[indexPath.section][indexPath.row];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        CommandesDetailVC *destinationViewController = [sb instantiateViewControllerWithIdentifier:@"detailCmd"];
        
        destinationViewController.infos = _infosCmdSel;
        
        previewingContext.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
        
        return destinationViewController;
    }
    
    return nil;
}

- (void) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
      commitViewController:(UIViewController *)viewControllerToCommit
{
    CommandesTVC *sourceViewController = self;
    CommandesDetailVC *destinationViewController = (CommandesDetailVC *)viewControllerToCommit;
    
    if (iPAD)
    {
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:destinationViewController];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        
        destinationViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                                    target:sourceViewController
                                                                                                                    action:@selector(masquerDetailModal)];
        
        [sourceViewController presentViewController:nc animated:YES completion:^{
            [sourceViewController.tableView deselectRowAtIndexPath:[sourceViewController.tableView indexPathForSelectedRow]
                                                          animated:YES];
        }];
    }
    else
        [sourceViewController.navigationController pushViewController:destinationViewController animated:YES];
}

#pragma mark - Handoff

- (void) updateUserActivityState:(NSUserActivity *)activity
{
    [super updateUserActivityState:activity];
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:([Data estConnecte]) ? @"cafetVide1" : @"cafetVide2"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = ([Data estConnecte]) ? @"Vous n'avez encore rien commandé" : @"Vous n'êtes pas connecté";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = ([Data estConnecte])
                      ? @"Tapez sur le bouton ＋ pour commander,\nvos commandes s'afficheront ici."
                      : @"Connectez-vous à votre profil ESEO pour commander à la cafet.";
    //@"Connectez-vous à votre profil ESEO\npour commander à la cafet.";
    
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
    
    return [[NSAttributedString alloc] initWithString:([Data estConnecte]) ? @"Commander" : @"Me connecter" attributes:attributes];
}

- (void) emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    if (![Data estConnecte])
        [[UIApplication sharedApplication] sendAction:_userBtn.action
                                                   to:_userBtn.target
                                                 from:nil
                                             forEvent:nil];
    else
        [self commander:scrollView];
}

- (CGPoint) offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2.);
}

@end


@implementation CustomHeaderView

- (void) layoutSubviews
{
    [super layoutSubviews];
    _serviceLabel.preferredMaxLayoutWidth = _serviceLabel.bounds.size.width;
}

@end
