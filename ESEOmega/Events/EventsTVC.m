//
//  EventsTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
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

#import "EventsTVC.h"
#import "BDE_ESEO-Swift.h"

@implementation EventsTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.refreshControl.tintColor = [UINavigationBar appearance].barTintColor;
    
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    
    /* Use Large Title on iOS 11 */
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
        self.refreshControl.tintColor = [UIColor whiteColor];
    } else {
        [ctr addObserver:self.refreshControl selector:@selector(endRefreshing)
                    name:@"debugRefresh" object:nil];
    }
    
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    
    [ctr addObserver:self selector:@selector(loadEvents)
                name:@"events" object:nil];
    [ctr addObserver:self selector:@selector(showEvent:)
                name:@"switchClubEventToEvent" object:nil];
    [ctr addObserver:self.refreshControl selector:@selector(endRefreshing)
                name:@"eventsSent" object:nil];
    
    [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    self.tableView.tableFooterView = [UIView new];
    [self loadEvents];
    [self scrollerMoisActuel];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.refreshControl endRefreshing];
    
    // Handoff
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.events"];
    activity.title = @"Liste des événements";
    activity.webpageURL = [NSURL URLWithString:URL_ACT_EVNT];
    activity.eligibleForSearch = YES;
    activity.eligibleForHandoff = YES;
    activity.eligibleForPublicIndexing = YES;
    if (@available(iOS 12, *)) {
        activity.eligibleForPrediction = YES;
        activity.suggestedInvocationPhrase = @"Affiche les événements à l'ESEO";
        activity.persistentIdentifier = @"com.eseomega.ESEOmega.events";
    }
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSDateComponents *comps = [NSDateComponents new];
    [comps setDay:4];
    [comps setMonth:02];
    [comps setYear:2016];
    NSDate *bm = [[NSCalendar currentCalendar] dateFromComponents:comps];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"nouveauBoutonEventVu"] &&
        [[NSDate date] compare:bm] == NSOrderedAscending)
    {
        self.tabBarController.viewControllers[1].tabBarItem.badgeValue = nil;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nouveauBoutonEventVu"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nouveau !"
                                                                       message:@"Commandez votre place à la Blue Moon depuis votre iPhone/iPad, grâce au nouveau bouton de commande en haut de l'écran !"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (nullable NSString *) texteDetail:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *event = events[indexPath.section][indexPath.row];
    NSString *detailString = @"";
    
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:JSON_DATE_FORMAT];
    NSDate *date = [df dateFromString:event[@"fulldate"]];
    NSString *dateTxt = [NSDateFormatter localizedStringFromDate:date
                                                       dateStyle:NSDateFormatterNoStyle
                                                       timeStyle:NSDateFormatterShortStyle];
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    
    if (dc.hour != 0 || dc.minute != 2)
        detailString = [@"À : " stringByAppendingString:dateTxt];
    if (event[@"fullenddate"] != nil && ![event[@"fullenddate"] isEqualToString:@""])
    {
        NSDate *dateFin = [df dateFromString:event[@"fullenddate"]];
        NSDateComponents *dcFin = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:dateFin];
        NSDateComponents *dcDiff = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond fromDate:date toDate:dateFin options:0];
        BOOL sameDay = (dc.day == dcFin.day && dc.month == dcFin.month && dc.year == dcFin.year) || dcDiff.second < 36000;
        NSString *dateFinTxt = [NSDateFormatter localizedStringFromDate:dateFin
                                                              dateStyle:(!sameDay) ? NSDateFormatterFullStyle : NSDateFormatterNoStyle
                                                              timeStyle:(dcFin.hour != 0 || dcFin.minute != 2) ? NSDateFormatterShortStyle : NSDateFormatterNoStyle];
        if (![dateFinTxt isEqualToString:@""] && ![dateFinTxt isEqualToString:dateTxt])
        {
            dateFinTxt = [dateFinTxt stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@" %d", (int)dcFin.year]
                                                               withString:@""];
            dateFinTxt = [dateFinTxt stringByReplacingOccurrencesOfString:[df monthSymbols][dcFin.month - 1]
                                                               withString:[df shortMonthSymbols][dcFin.month - 1]];
            if (![detailString isEqualToString:@""])
                detailString = [detailString stringByAppendingString:[NSString stringWithFormat:@"  ·  Fin : %@", dateFinTxt]];
            else
                detailString = [@"Fin : " stringByAppendingString:dateFinTxt];
        }
    }
    /*if (![event[@"lieu"] isEqualToString:@""])
    {
        if (detailString != nil && ![detailString isEqualToString:@""])
            detailString = [detailString stringByAppendingString:[NSString stringWithFormat:@"  ·  Lieu : %@", event[@"lieu"]]];
        else
            detailString = [@"Lieu : " stringByAppendingString:event[@"lieu"]];
    }
    */if (event[@"from"] != nil && ![event[@"from"] isEqualToString:@""])
    {
        if (![detailString isEqualToString:@""])
            detailString = [detailString stringByAppendingString:[NSString stringWithFormat:@"\nPar : %@", event[@"from"]]];
        else
            detailString = [@"Par : " stringByAppendingString:event[@"from"]];
    }/*
    if (![event[@"detail"] isEqualToString:@""])
    {
        NSString *detail = [event[@"detail"] stringByReplacingOccurrencesOfString:@"\\n"
                                                                       withString:@"\n"];
        if (detailString != nil && ![detailString isEqualToString:@""])
            detailString = [detailString stringByAppendingString:[NSString stringWithFormat:@"\n%@", detail]];
        else
            detailString = detail;
    }*/
    
    return detailString;
}

- (void) recupEvents:(BOOL)forcer
{
    if (!forcer && ![[Data sharedData] shouldUpdateJSON:@"events"])
    {
        [self.refreshControl endRefreshing];
        return;
    }
    
    [[Data sharedData] updateJSON:@"events"];
}

- (void) loadEvents
{
    NSEnumerator *eventsBruts = [[[Data sharedData] events][@"events"] reverseObjectEnumerator];
    
    NSMutableArray *evenementsMonths = [NSMutableArray new];
    NSMutableArray *evenements = [NSMutableArray new];
    for (NSDictionary *event in eventsBruts)
    {
        NSDateFormatter *df = [NSDateFormatter new];
        [df setDateFormat:JSON_DATE_FORMAT];
        NSDate *date = [df dateFromString:event[@"fulldate"]];
        
        if (date != nil) {
            NSDateComponents *dc = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth | NSCalendarUnitYear)
                                                                   fromDate:date];
            NSString *header = [NSString stringWithFormat:@"%@ %d", [[df monthSymbols][dc.month - 1] capitalizedString], (int)dc.year];
            
            if ([evenementsMonths containsObject:header])
                [evenements[[evenementsMonths indexOfObject:header]] addObject:event];
            else
            {
                [evenementsMonths addObject:header];
                NSMutableArray *eventsMois = [[NSMutableArray alloc] initWithObjects:event, nil];
                [evenements addObject:eventsMois];
            }
        }
    }
    events = [NSArray arrayWithArray:evenements];
    eventsMonths = [NSArray arrayWithArray:evenementsMonths];
    
    if ([eventsMonths count])
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

- (IBAction) refresh:(UIRefreshControl *)sender
{
    [self recupEvents:NO];
}

- (void) scrollerMoisActuel
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:JSON_DATE_FORMAT];
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitDay)
                                                           fromDate:[NSDate date]];
    NSString *header = [NSString stringWithFormat:@"%@ %d", [[df monthSymbols][dc.month - 1] capitalizedString], (int)dc.year];
    if (eventsMonths == nil || [eventsMonths count] < 1)
        return;
    NSUInteger pos = [eventsMonths indexOfObject:header];
    if (pos == NSNotFound)
    {
        [self.tableView setContentOffset:CGPointMake(0, -self.tableView.contentInset.top)
                                animated:YES];
        return;
    }
    
    NSInteger posR = 0;
    NSUInteger c = [events[pos] count];
    for ( ; posR < c ; ++posR)
    {
        NSDictionary *event = events[pos][posR];
        NSDateComponents *dcEvent = [[NSCalendar currentCalendar] components:(NSCalendarUnitWeekday | NSCalendarUnitDay |
                                                                              NSCalendarUnitHour | NSCalendarUnitMinute)
                                                                    fromDate:[df dateFromString:event[@"fullenddate"]]];
        if (dcEvent.day < dc.day)
            break;
    }
    if ([UIScreen mainScreen].bounds.size.width > 320)
        posR -= 2;
    if (posR >= c)
        posR = c - 1;
    if (posR < 0)
        posR = 0;
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:posR inSection:pos]
                          atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [eventsMonths count];
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [events[section] count];
}

- (nullable NSString *) tableView:(nonnull UITableView *)tableView
          titleForHeaderInSection:(NSInteger)section
{
    return eventsMonths[section];
}

- (CGFloat)   tableView:(nonnull UITableView *)tableView
heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *cellText = [self texteDetail:indexPath];
    UIFont *cellFont = [UIFont systemFontOfSize:11];
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:cellText
                                                                         attributes:@{ NSFontAttributeName: cellFont }];
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(tableView.bounds.size.width - 100, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    return MAX(65, rect.size.height + 30);
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell" forIndexPath:indexPath];
    
    NSDictionary *event = events[indexPath.section][indexPath.row];
    
    // Création du badge du jour
    UIColor *color;
    if (event[@"color"] == nil)
        color = [UIColor colorWithRed:1 green:45/255. blue:85/255. alpha:1];   // fraise écrasée
    else
        color = [UIColor colorWithRed:[event[@"color"][0] floatValue]/255.
                                green:[event[@"color"][1] floatValue]/255.
                                 blue:[event[@"color"][2] floatValue]/255.
                                alpha:1];
    
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:JSON_DATE_FORMAT];
    NSDate *dateFin = [df dateFromString:event[@"fullenddate"]];
    if ([dateFin compare:[NSDate date]] == NSOrderedAscending)
        color = [UIColor colorWithRed:145/255. green:164/255. blue:173/255. alpha:1];
    
    CGRect imgFrame = CGRectMake(0, 0, 50, 50);
    UIGraphicsBeginImageContextWithOptions(imgFrame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:imgFrame cornerRadius:7];
    [roundedRect fillWithBlendMode:kCGBlendModeNormal alpha:1];
    
    NSDate *date = [df dateFromString:event[@"fulldate"]];
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:(NSCalendarUnitWeekday | NSCalendarUnitDay |
                                                                     NSCalendarUnitHour | NSCalendarUnitMinute)
                                                           fromDate:date];
    NSString *text = [df weekdaySymbols][dc.weekday - 1];
    NSString *text2 = [NSString stringWithFormat:@"%d", (int)dc.day];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentCenter;
    
    // Jour semaine
    CGRect rectTxt1 = imgFrame;
    rectTxt1.origin.x -= 1;
    rectTxt1.size.width += 2;
    rectTxt1.origin.y += 3;
    [text drawInRect:rectTxt1 withAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:9], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName: style}];
    
    // Numéro jour
    CGRect rectTxt2 = imgFrame;
    rectTxt2.origin.y += imgFrame.size.height / 3.7;
    [text2 drawInRect:rectTxt2 withAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:28], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName: style}];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [[cell imageView] setImage:newImage];
    
    // Texte
    [cell.textLabel setText:event[@"title"]];
    cell.textLabel.textColor = [UIColor blackColor];
    [cell.detailTextLabel setText:[self texteDetail:indexPath]];
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    
    if ([dateFin compare:[NSDate date]] == NSOrderedAscending)
    {
        cell.textLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    }
    
    [cell setSelectionStyle:(event[@"url"] == nil || [event[@"url"] isEqualToString:@""]) ? UITableViewCellSelectionStyleNone
                                                                                          : UITableViewCellSelectionStyleDefault];
    
    /* Register for */
    if ((event[@"signup"]  != nil && [event[@"signup"] boolValue]) ||
        (event[@"tickets"] != nil && [event[@"tickets"] count] > 0))
    {
        NSString *imageName = nil;
        UITapGestureRecognizer *tap = nil;
        if (event[@"signup"] != nil && [event[@"signup"] boolValue])
        {
            imageName = @"signup";
            tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(quickSignUp:)];
        }
        else if (event[@"tickets"] != nil && [event[@"tickets"] count] > 0)
        {
            imageName = @"ticket";
            tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commanderEvent:)];
        }
        
        if (imageName != nil && tap != nil)
        {
            UIImageView *imgView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            [imgView addGestureRecognizer:tap];
            [cell setAccessoryView:imgView];
            BOOL active = [dateFin compare:[NSDate date]] != NSOrderedAscending;
            [imgView setUserInteractionEnabled:active];
            [imgView setTintColor:(active) ? self.tableView.tintColor : [UIColor lightGrayColor]];
        }
    }
    else
        [cell setAccessoryView:nil];
    
    return cell;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    CustomIOSAlertView *alert = [self popUp:indexPath];
    [alert setButtonTitles:[self boutonsPopUp:indexPath]];
    [alert setUseMotionEffects:YES];
    [alert show];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) quickSignUp:(UITapGestureRecognizer *)tgr
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[tgr locationInView:self.tableView]];
    if (indexPath == nil)
        return;
    
    NSDictionary *event = events[indexPath.section][indexPath.row];
    
    /* Ask validation */
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Voulez-vous vous inscrire pour cet événement ?"
                                                                   message:[event[@"title"] stringByAppendingString:@"\n\nVotre nom, mail et № de téléphone seront communiqués au BDE"]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirmer"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [Data sharedData].tempPhone = nil;
        [self signUp:[event[@"id"] intValue]];
    }];
    [alert addAction:confirmAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                              style:UIAlertActionStyleCancel handler:nil]];
    [alert setPreferredAction:confirmAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) signUp:(int)eventID
{
    for (NSArray *months in events)
    {
        for (NSDictionary *event in months)
        {
            if ([event[@"id"] intValue] == eventID)
            {
                NSDateFormatter *df = [NSDateFormatter new];
                [df setDateFormat:JSON_DATE_FORMAT];
                NSDate *dateFin = [df dateFromString:event[@"fullenddate"]];
                if ([dateFin compare:[NSDate date]] == NSOrderedAscending)
                {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Impossible de s'inscrire"
                                                                                   message:@"L'événement est terminé"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                              style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                    return;
                }
                break;
            }
        }
    }
    
    if (!DataStore.isUserLogged)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous devez vous connecter pour vous inscrire à un événement"
                                                                       message:@"Utilisez votre profil ESEO pour vous connecter dans l'application."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    
    if ([JNKeychain loadValueForKey:@"phone"] == nil)
    {
        NSString *message = @"Celui-ci ne sera utilisé que pour vous recontacter plus facilement";
        if ([Data sharedData].tempPhone != nil)
            message = [message stringByAppendingString:@"\n\nRéessayez, numéro incorrect."];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Veuillez nous communiquer votre numéro de téléphone"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField)
         {
             textField.placeholder  = @"0601234242";
             textField.keyboardType = UIKeyboardTypePhonePad;
             textField.delegate     = self;
             textField.text         = [Data sharedData].tempPhone;
         }];
        UIAlertAction *subscribeAction = [UIAlertAction actionWithTitle:@"S'inscrire"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action)
                                          {
                                              [self sendSignUp:eventID];
                                          }];
        [alert addAction:subscribeAction];
        [alert addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert setPreferredAction:subscribeAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
        [self sendSignUp:eventID];
}

- (BOOL)            textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
            replacementString:(NSString *)string
{
    NSString  *proposedNewString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString  *result = [proposedNewString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [Data sharedData].tempPhone = result;
    return YES;
}

- (void) sendSignUp:(int)eventID
{
    if (!DataStore.isUserLogged)
        return;
    
    if ([JNKeychain loadValueForKey:@"phone"] == nil)
    {
        NSString *num = [Data sharedData].tempPhone;
        if ([num rangeOfString:@"^((\\+|00)33\\s?|0)[679](\\s?\\d{2}){4}$" options:NSRegularExpressionSearch].location != NSNotFound)
        {
            [Data sharedData].tempPhone = nil;
            [JNKeychain saveValue:num forKey:@"phone"];
        }
        else
        {
            [self signUp:eventID];
            return;
        }
    }
    
    /* Loading (auto-dismissing) indication */
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Réservation en cours"
                                                                   message:@"Veuillez patienter…"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    double delayInSeconds = 30.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    /* Prepare GET & POST */
    NSString *mail = [JNKeychain loadValueForKey:@"mail"];
    if (mail == nil)
    {
        NSString *prenom = @"";
        NSString *nom = @"";
        
        /* Lowercased and without accented letters */
        NSMutableString *username = [[[JNKeychain loadValueForKey:@"uname"] lowercaseString] mutableCopy];
        CFStringTransform((__bridge CFMutableStringRef)username, NULL, kCFStringTransformStripCombiningMarks, NO);
        
        /* Separate first & last names */
        NSUInteger space = [username rangeOfString:@" " options:NSBackwardsSearch].location;
        if (space == NSNotFound || space + 2 > username.length) {
            prenom = username;
        } else {
            prenom = [username substringToIndex:space];
            nom    = [username substringFromIndex:space + 1];
        }
        
        /* No composed names, ahhh Frenchies */
        prenom = [prenom stringByReplacingOccurrencesOfString:@" " withString:@""];
        prenom = [prenom stringByReplacingOccurrencesOfString:@"-" withString:@""];
        prenom = [prenom stringByReplacingOccurrencesOfString:@"'" withString:@""];
        nom    = [nom    stringByReplacingOccurrencesOfString:@" " withString:@""];
        nom    = [nom    stringByReplacingOccurrencesOfString:@"-" withString:@""];
        nom    = [nom    stringByReplacingOccurrencesOfString:@"'" withString:@""];
        
        mail = [NSString stringWithFormat:@"%@.%@@reseau.eseo.fr", prenom, nom];
    }
    NSURL    *url  = [NSURL URLWithString:[NSString stringWithFormat:URL_EVN_SIGN, eventID]];
    NSString *body = [NSString stringWithFormat:@"name=%@&email=%@&tel=%@",
                      [Data encoderPourURL:[JNKeychain loadValueForKey:@"uname"]],
                      [Data encoderPourURL:mail],
                      [Data encoderPourURL:[JNKeychain loadValueForKey:@"phone"]]];
    
    /* Send */
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request
                                                       completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [alert dismissViewControllerAnimated:YES completion:^{
                                              
                                              NSString *titre = @"Erreur";
                                              NSString *message = @"Impossible d'envoyer la requête d'inscription.";
                                              
                                              if (error == nil && data != nil)
                                              {
                                                  NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                                       options:kNilOptions
                                                                                                         error:nil];
                                                  
                                                  if (JSON[@"signedup"] != nil)
                                                  {
                                                      if ([JSON[@"signedup"] boolValue])
                                                      {
                                                          titre = @"Inscription acceptée !";
                                                          message = @"Merci, nous vous recontacterons";
                                                      }
                                                      else
                                                      {
                                                          titre = @"Inscription refusée";
                                                          message = @"L'événement doit être plein, sinon contactez le BDE";
                                                      }
                                                  }
                                                  else
                                                  {
                                                      titre = @"Impossible de réaliser l'inscription";
                                                      message = @"Erreur inconnue.";
                                                      if (JSON[@"info"] != nil && ![JSON[@"info"] isEqualToString:@""])
                                                          message = JSON[@"info"];
                                                  }
                                              }
                                              
                                              UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:titre
                                                                                                              message:message
                                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                                              [alert2 addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                         style:UIAlertActionStyleCancel
                                                                                       handler:nil]];
                                              [self presentViewController:alert2 animated:YES completion:Nil];
                                          }];
                                      }];
    [dataTask resume];
}

#pragma mark - 3D Touch

- (UIViewController *) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
               viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *index = [self.tableView indexPathForRowAtPoint:location];
    if (index != nil)
    {
        previewingContext.sourceRect = [self.tableView rectForRowAtIndexPath:index];
        CustomIOSAlertView *alert = [self popUp:index];
        boutons3DPop = [self boutonsPopUp:index];
        EventAlertViewController *vc = [EventAlertViewController new];
        NSMutableArray *previewItems = [NSMutableArray array];
        for (NSString *titre in boutons3DPop)
            if (![titre isEqualToString:DEFAULT_BTN])
                [previewItems addObject:[UIPreviewAction actionWithTitle:titre
                                                                   style:UIPreviewActionStyleDefault
                                                                 handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                     NSString *URL = events[index.section][index.row][@"url"];
                                                                     if (![URL isEqualToString:@""])
                                                                         [[Data sharedData] openURL:URL currentVC:self];
                                                                 }]];
        [vc set3DBoutons:[NSArray arrayWithArray:previewItems]];
        [alert.containerView setBackgroundColor:[UIColor whiteColor]];
        CGFloat min = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        CGFloat dec = (self.view.bounds.size.width < 350) ? 20 : 50;
        [vc setPreferredContentSize:CGSizeMake(min - dec, min - 100)];
        [vc setView:alert.containerView];
        return vc;
    }
    return nil;
}

- (void) previewingContext:(id<UIViewControllerPreviewing>)previewingContext
      commitViewController:(UIViewController *)viewControllerToCommit
{
    UIView *view = [viewControllerToCommit view];
    CGFloat min = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    CGFloat dec = (self.view.bounds.size.width < 350) ? 20 : 50;
    [view setFrame:CGRectMake(0, 0, min - dec, min - 100)];
    [view setBackgroundColor:[UIColor clearColor]];
    CustomIOSAlertView *alert = [[CustomIOSAlertView alloc] init];
    [alert setContainerView:view];
    [alert setButtonTitles:boutons3DPop];
    [alert setUseMotionEffects:YES];
    [alert show];
}

#pragma mark - Handoff

- (void) updateUserActivityState:(NSUserActivity *)activity
{
    [super updateUserActivityState:activity];
}

#pragma mark - CustomIOSAlertView

- (nullable CustomIOSAlertView *) popUp:(NSIndexPath *)index
{
    NSDictionary *event = events[index.section][index.row];
    return [EventsTVC popUp:event
                 inDelegate:self];
}

+ (nullable CustomIOSAlertView *) popUp:(NSDictionary *)event
                             inDelegate:(UIViewController<CustomIOSAlertViewDelegate> *)delegate
{
    if (event == nil)
        return nil;
    
    CGFloat min = MIN(delegate.view.bounds.size.width, delegate.view.bounds.size.height);
    CGFloat dec = (delegate.view.bounds.size.width < 350) ? 20 : 50;
    
    EventAlertView *view = [[NSBundle mainBundle] loadNibNamed:@"EventAlertView" owner:self options:nil][0];
    [view setFrame:CGRectMake(0, 0, min - dec, min - 100)];
    view.clipsToBounds = YES;
    view.layer.cornerRadius = 7;
    
    view.title.text  = event[@"title"];
    if (event[@"color"] == nil)
        view.backTitle.backgroundColor = [UIColor colorWithRed:1 green:45/255. blue:85/255. alpha:1];   // fraise écrasée
    else
        view.backTitle.backgroundColor = [UIColor colorWithRed:[event[@"color"][0] floatValue]/255.
                                                         green:[event[@"color"][1] floatValue]/255.
                                                          blue:[event[@"color"][2] floatValue]/255.
                                                         alpha:1];
    
    /* Description label, allow HTML */
    NSString *detail = [event[@"text"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    detail = [detail stringByReplacingOccurrencesOfString:@" €" withString:@" €"];  // no-breaking space
    detail = [detail stringByReplacingOccurrencesOfString:@" %" withString:@" %"];  // no-breaking space
    if (detail == nil)
        nil;
    detail = [[NSString stringWithFormat:@"<style>body{font-family: '%@'; font-size:%fpx; line-height: 90%%;}</style>",
               view.detail.font.fontName, view.detail.font.pointSize]
              stringByAppendingString:detail];
    // Remove trailing HTML useless tags
    while ([detail hasSuffix:@"<br>"] || [detail hasSuffix:@"<br/>"] || [detail hasSuffix:@"<br />"]) {
        detail = [detail substringToIndex:[detail rangeOfString:@"<br" options:NSBackwardsSearch].location];
    }
    NSAttributedString *as = [[NSAttributedString alloc] initWithData:[detail dataUsingEncoding:NSUnicodeStringEncoding]
                                                              options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                   documentAttributes:nil error:nil];
    view.detail.attributedText = as;
    
    if ([UIScreen mainScreen].bounds.size.width < 350)
    {
        [view.title setFont:[UIFont systemFontOfSize:15]];
        [view.detail setFont:[UIFont systemFontOfSize:13]];
        [view.lieu setFont:[UIFont systemFontOfSize:13]];
        [view.lieuLabel setFont:[UIFont systemFontOfSize:13]];
        [view.club setFont:[UIFont systemFontOfSize:13]];
        [view.clubLabel setFont:[UIFont systemFontOfSize:13]];
        [view.date setFont:[UIFont systemFontOfSize:13]];
        [view.dateLabel setFont:[UIFont systemFontOfSize:13]];
        [view.dateFin setFont:[UIFont systemFontOfSize:13]];
        [view.dateFinLabel setFont:[UIFont systemFontOfSize:13]];
    }
    
    if (event[@"place"] == nil || [event[@"place"] isEqualToString:@""])
    {
        [view.lieu removeFromSuperview];
        [view.lieuLabel removeFromSuperview];
    }
    else
        view.lieu.text   = event[@"place"];
    
    if (event[@"from"] == nil || [event[@"from"] isEqualToString:@""])
    {
        [view.club removeFromSuperview];
        [view.clubLabel removeFromSuperview];
    }
    else
        view.club.text   = event[@"from"];
    
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:JSON_DATE_FORMAT];
    NSDate *date = [df dateFromString:event[@"fulldate"]];
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    NSString *dateTxt = [NSDateFormatter localizedStringFromDate:date
                                                       dateStyle:NSDateFormatterFullStyle
                                                       timeStyle:(dc.hour != 0 || dc.minute != 2) ? NSDateFormatterShortStyle : NSDateFormatterNoStyle];
    view.date.text = dateTxt;
    if (event[@"fullenddate"] != nil && ![event[@"fullenddate"] isEqualToString:@""])
    {
        NSDate *dateFin = [df dateFromString:event[@"fullenddate"]];
        NSDateComponents *dcFin = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:dateFin];
        NSDateComponents *dcDiff = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond fromDate:date toDate:dateFin options:0];
        BOOL sameDay = (dc.day == dcFin.day && dc.month == dcFin.month && dc.year == dcFin.year) || dcDiff.second < 36000;
        NSString *dateFinTxt = [NSDateFormatter localizedStringFromDate:dateFin
                                                              dateStyle:(sameDay) ? NSDateFormatterNoStyle : NSDateFormatterFullStyle
                                                              timeStyle:(dcFin.hour != 0 || dcFin.minute != 2) ? NSDateFormatterShortStyle : NSDateFormatterNoStyle];
        if (![dateFinTxt isEqualToString:@""] && ![dateFinTxt isEqualToString:dateTxt])
            view.dateFin.text = dateFinTxt;
        else
        {
            [view.dateFin removeFromSuperview];
            [view.dateFinLabel removeFromSuperview];
        }
    }
    view.identifier = [event[@"id"] intValue];
    view.URL = event[@"url"];
    
    
    CustomIOSAlertView *alert = [CustomIOSAlertView new];
    [alert setButtonTitles:nil];
    [alert setUseMotionEffects:NO];
    [alert setDelegate:delegate];
    [alert setContainerView:view];

    return alert;
}

- (nullable NSArray *) boutonsPopUp:(NSIndexPath *)index
{
    NSDictionary *event = events[index.section][index.row];
    return [EventsTVC boutonsPopUp:event];
}

+ (nullable NSArray *) boutonsPopUp:(NSDictionary *)event
{
    NSMutableArray *boutons = [NSMutableArray arrayWithObject:DEFAULT_BTN];
    if (event[@"url"] != nil && ![event[@"url"] isEqualToString:@""])
    {
        if ([event[@"url"] rangeOfString:@"facebook.com"].location != NSNotFound ||
            [event[@"url"] rangeOfString:@"fb.me"].location != NSNotFound)
        {
            if ([UIScreen mainScreen].bounds.size.width > 320)
                [boutons addObject:@"Voir sur Facebook"];
            else
                [boutons addObject:@"Voir Facebook"];
        }
        else
            [boutons addObject:@"Plus d'infos"];
    }
    if (event[@"tickets"] != nil && [event[@"tickets"] count])
    {
        if ([boutons indexOfObject:@"Voir sur Facebook"] != NSNotFound)
            [boutons replaceObjectAtIndex:[boutons indexOfObject:@"Voir sur Facebook"] withObject:@"Facebook"];
        else if ([boutons indexOfObject:@"Voir Facebook"] != NSNotFound)
            [boutons replaceObjectAtIndex:[boutons indexOfObject:@"Voir Facebook"] withObject:@"Facebook"];
        [boutons addObject:BUY_BTN];
    }
    if (event[@"signup"] != nil && [event[@"signup"] boolValue])
    {
        if ([boutons indexOfObject:@"Voir sur Facebook"] != NSNotFound)
            [boutons replaceObjectAtIndex:[boutons indexOfObject:@"Voir sur Facebook"] withObject:@"Facebook"];
        else if ([boutons indexOfObject:@"Voir Facebook"] != NSNotFound)
            [boutons replaceObjectAtIndex:[boutons indexOfObject:@"Voir Facebook"] withObject:@"Facebook"];
        [boutons addObject:SUBSCRIBE_BTN];
    }
    return [boutons copy];
}

- (IBAction) commanderEvent:(id)sender
{
    if (!DataStore.isUserLogged)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous devez vous connecter pour commander une place"
                                                                       message:@"Pour commander pour un événement, connectez-vous à votre profil ESEO dans l'application."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [[Data sharedData] updateJSON:@"eventsCmds"];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Events" bundle:nil];
    UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"Events"];
    [self presentViewController:vc animated:YES completion:nil];
}


- (void) showEvent:(NSNotification *)notif
{
    /* Get previous customIOS7dialogButtonTouchUpInside:clickedButtonAtIndex: data */
    CustomIOSAlertView *alertView = (CustomIOSAlertView *)notif.userInfo[@"alertView"];
    NSInteger buttonIndex = [notif.userInfo[@"buttonIndex"] integerValue];
    if (alertView != nil)
    {
        /* Find the event in the list to scroll to // and yeah GOTOs are bad */
        NSInteger section = 0,
                  row     = 0;
        for (NSArray *month in events) {
            for (NSDictionary *event in month) {
                if ([event[@"id"] intValue] == ((EventAlertView *)alertView.containerView).identifier)
                    goto JUMP;
                row++;
            }
            section++;
        }
    JUMP:
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
        /* Deliver the action according to the previous tap */
        [self customIOS7dialogButtonTouchUpInside:alertView
                             clickedButtonAtIndex:buttonIndex];
    }
}

- (void) customIOS7dialogButtonTouchUpInside:(CustomIOSAlertView *)alertView
                        clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [alertView close];
    if ([[alertView buttonTitles][buttonIndex] isEqualToString:BUY_BTN])
        [self commanderEvent:nil];
    else if ([[alertView buttonTitles][buttonIndex] isEqualToString:SUBSCRIBE_BTN])
    {
        /* Ask validation */
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Voulez-vous vous inscrire pour cet événement ?"
                                                                       message:[((EventAlertView *)alertView.containerView).title.text stringByAppendingString:@"\n\nVotre nom, mail et № de téléphone seront communiqués au BDE"]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *validateAction = [UIAlertAction actionWithTitle:@"Confirmer"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
            [Data sharedData].tempPhone = nil;
            int eventID = ((EventAlertView *)alertView.containerView).identifier;
            [self signUp:eventID];
        }];
        [alert addAction:validateAction];
        [alert addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [alert setPreferredAction:validateAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (![[alertView buttonTitles][buttonIndex] isEqualToString:DEFAULT_BTN])
    {
        NSString *URL = ((EventAlertView *)alertView.containerView).URL;
        if (![URL isEqualToString:@""])
            [[Data sharedData] openURL:URL currentVC:self];
    }
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"eventsVide"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Aucun événement";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Les événements seront bientôt de retour,\nle BDE y travaille.";
    
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
    return [UIColor groupTableViewBackgroundColor];
}

@end
