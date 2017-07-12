//
//  CommandesDetailVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 28/07/2015.
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

#import "CommandesDetailVC.h"

@implementation CommandesDetailVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    loaded = NO;
    
    [self showCmd];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(majTimerRecup)
                                                 name:NSProcessInfoPowerStateDidChangeNotification object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self loadCmd];
    [self majTimerRecup];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [upd invalidate];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void) majTimerRecup
{
    [upd invalidate];
    
    if ([[NSProcessInfo processInfo] isLowPowerModeEnabled])
        return;
    
    upd = [NSTimer scheduledTimerWithTimeInterval:21
                                           target:self
                                         selector:@selector(loadCmd)
                                         userInfo:nil
                                          repeats:YES];
    [upd setTolerance:21];
}

- (void) loadCmd
{
    if (![Data estConnecte])
        return;
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:URL_1CMD];
    
    NSString *username = [Data encoderPourURL:[JNKeychain loadValueForKey:@"login"]];
    NSString *password = [Data encoderPourURL:[JNKeychain loadValueForKey:@"passw"]];
    NSString *idc      = [NSString stringWithFormat:@"%ld", (long)[_infos[@"idcmd"] integerValue]];
    NSString *body     = [NSString stringWithFormat:@"idcmd=%@&username=%@&password=%@&hash=%@",
                          idc, username, password,
                          [Data encoderPourURL:[Data hashed_string:[[[@"base64(json_encode(#MACRO))" stringByAppendingString:idc] stringByAppendingString:username] stringByAppendingString:password]]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
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
                                              if ([JSON[@"status"] intValue] == 1)
                                              {
                                                  // Mise à jour du statut + image
                                                  NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:_infos];
                                                  for (NSString *key in JSON[@"data"])
                                                      [temp setObject:JSON[@"data"][key] forKey:key];/*
                                                  [temp setObject:JSON[@"data"][@"status"] forKey:@"status"];
                                                  [temp setObject:JSON[@"data"][@"imgurl"] forKey:@"imgurl"];*/
                                                  _infos = [NSDictionary dictionaryWithDictionary:temp];
                                                  
                                                  [self showCmd];
                                              }
                                              else
                                              {
                                                  alert = [UIAlertController alertControllerWithTitle:@"Détails de la commande indisponibles"
                                                                                              message:@"Impossible de vous connecter avec ce nom d'utilisateur/mot de passe.\n\nSi vous avez changé de mot de passe récemment, merci de bien vouloir vous déconnecter puis reconnecter."
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                                                  UIAlertAction *profileAction = [UIAlertAction actionWithTitle:@"Voir profil" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                      TabBarController *tab = (TabBarController *)([UIApplication sharedApplication].delegate.window.rootViewController);
                                                      [tab ecranConnex];
                                                  }];
                                                  [alert addAction:profileAction];
                                                  [alert setPreferredAction:profileAction];
                                              }
                                          }
                                          else
                                              alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                                          message:@"Impossible de récupérer la commande"
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

- (void) showCmd
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    [numberFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"fr_FR"]];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSString *titre = @"";
    UIColor *color, *colorLighter;
    
    switch ([_infos[@"status"] intValue])
    {
        case NotPaid:
            titre = @"Commande impayée";
            color = [UIColor colorWithRed:1 green:45/255. blue:85/255. alpha:1];
            break;
            
        case Ready:
            titre = @"Commande prête";
            color = [UIColor colorWithRed:0.549 green:0.824 blue:0 alpha:1];
            break;
            
        case Preparing:
            titre = @"Commande en préparation";
            color = [UIColor colorWithRed:0 green:122/255. blue:1 alpha:1];
            break;
            
        case Done:
        default:
            titre = @"Commande terminée";
            color = [UIColor darkGrayColor];
            break;
    }
    
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a])
        colorLighter  = [UIColor colorWithRed:MIN(r + 0.2, 1.0) green:MIN(g + 0.2, 1.0) blue:MIN(b + 0.2, 1.0) alpha:a];
    
    self.title = titre;
    
    _prix.textColor = color;
    _numCmdHeader.textColor = color;
    _numCmdLabelBack.backgroundColor = color;
    _numCmdBack.backgroundColor = colorLighter;
    
    if (_infos[@"imgurl"] != nil && ![_infos[@"imgurl"] isEqualToString:@""])
    {
        [_bandeau sd_setImageWithURL:[NSURL URLWithString:[URI_CAFET stringByAppendingString:_infos[@"imgurl"]]]
                    placeholderImage:[UIImage imageNamed:@"placeholder"]
                           completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
         {
             if (!loaded)
             {
                 CATransition *animation = [CATransition animation];
                 [animation setDelegate:self];
                 [animation setDuration:0.42f];
                 [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
                 [animation setType:kCATransitionMoveIn];
                 [animation setSubtype:kCATransitionFromBottom];
                 [_bandeau.layer addAnimation:animation forKey:NULL];
                 loaded = YES;
             }
         }];
    }
    
    _titreLabel.text = [NSString stringWithFormat:@"Votre commande du %@",
                        [[NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:_infos[@"datetime"]]
                                                        dateStyle:NSDateFormatterFullStyle
                                                        timeStyle:NSDateFormatterNoStyle]
                         stringByReplacingOccurrencesOfString:@" "
                         withString:@" "]]; // Non-Breaking Space
    NSString *stringPrix = [numberFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:[_infos[@"price"] stringValue]]];
    if ([_infos[@"status"] intValue] == NotPaid)
        stringPrix = [stringPrix stringByAppendingString:@" ⚠️"];
    _prix.attributedText = [[NSAttributedString alloc] initWithString:stringPrix
                                                           attributes:@{ NSTextEffectAttributeName: NSTextEffectLetterpressStyle }];
    NSString *detailText = @"";
    if (_infos[@"resume"] && ![_infos[@"resume"] isEqualToString:@""])
        detailText = [@"– " stringByAppendingString:[_infos[@"resume"] stringByReplacingOccurrencesOfString:@"<br>"
                                                                                                 withString:@"\n– "]];
    else
        detailText = @"Chargement en cours…";
    _detailLabel.text = detailText;
    if (_infos[@"instructions"] && ![_infos[@"instructions"] isEqualToString:@""])
    {
        NSString *beforeDetail = detailText;
        detailText = [[detailText stringByAppendingString:@"\n\nCommentaire :\n"] stringByAppendingString:_infos[@"instructions"]];
        
        
        NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:detailText
                                                                               attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]}];
        [as setAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}
                    range:NSMakeRange(beforeDetail.length + 2, 13)];
        
        CATransition *animation = [CATransition animation];
        [animation setDelegate:self];
        [animation setDuration:0.42f];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [animation setType:@"cube"];
        [animation setSubtype:kCATransitionFromBottom];
        [_detailLabel.layer addAnimation:animation forKey:NULL];
        _detailLabel.attributedText = as;
    }
    _numCmdLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %03d", _infos[@"strcmd"], [_infos[@"modcmd"] intValue]]
                                                                  attributes:@{ NSTextEffectAttributeName: NSTextEffectLetterpressStyle }];
    
    if (_infos[@"paidbefore"] != nil && [_infos[@"paidbefore"] intValue] == 1)
    {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Payée"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(payCmd)];
        item.enabled = NO;
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    else if (_infos[@"lydia_enabled"] != nil && [_infos[@"lydia_enabled"] boolValue] && [_infos[@"status"] intValue] != Done && [_infos[@"price"] doubleValue] >= 0.5 && [_infos[@"price"] doubleValue] <= 250.0)
    {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Payer"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(payCmd)];
        [self.navigationItem setRightBarButtonItem:item animated:YES];
    }
    else
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
}

- (void) payCmd
{
    if ([_infos[@"paidbefore"] intValue] == 1 || [_infos[@"price"] doubleValue] < 0.5 || [_infos[@"price"] doubleValue] > 250.0)
        return;
    if (![Data estConnecte] && _infos[@"idcmd"] != nil && _infos[@"idlydia"] != nil)
        return;
    
    if ([_infos[@"idlydia"] integerValue] != -1)
        [[Data sharedData] checkLydia:@{ @"id": [_infos[@"idcmd"] stringValue], @"cat": @"CAFET" }];
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Voulez-vous payer votre commande dès maintenant avec Lydia ?"
                                                                       message:@"Plus besoin de se déplacer pour payer !"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *payNowAction = [UIAlertAction actionWithTitle:@"Payer immédiatement 💳"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
        {
            if ([Data estConnecte])
                [[Data sharedData] startLydia:[_infos[@"idcmd"] integerValue]
                                      forType:@"CAFET"];
            else
            {
                [alert dismissViewControllerAnimated:YES completion:^{
                    UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"Vous devez être connecté pour payer"
                                                                                    message:@"Connectez-vous grâce à votre compte Campus ESEO."
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                    [alert2 addAction:[UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil]];
                    [self presentViewController:alert2 animated:YES completion:nil];
                }];
            }
        }];
        
        [alert addAction:payNowAction];
        [alert addAction:[UIAlertAction actionWithTitle:@"Payer plus tard au comptoir 💰"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [alert setPreferredAction:payNowAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
