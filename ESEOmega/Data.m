//
//  Data.m
//  ESEOmega
//
//  Created by Thomas NAUDET on 02/08/2015.
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

#import "Data.h"
#import "BDE_ESEO-Swift.h"

@implementation Data

+ (Data *) sharedData {
    static Data *instance = nil;
    if (instance == nil) {
        
        static dispatch_once_t pred;        // Lock
        dispatch_once(&pred, ^{             // This code is called at most once per app
            instance = [[Data allocWithZone:NULL] init];
        });
        
        // Préférences par défaut
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults registerDefaults:@{ @"GPenabled": @NO}];
        [defaults synchronize];
        
        EGOCache *ec        = [EGOCache globalCache];
        instance.events     = (![ec hasCacheForKey:@"events"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"events"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.eventsCmds = (![ec hasCacheForKey:@"eventsCmds"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"eventsCmds"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.sponsors   = (![ec hasCacheForKey:@"sponsors"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"sponsors"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        NSNumber *time      = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
        instance.lastCheck  = [NSMutableDictionary dictionaryWithDictionary:@{ @"events":    time,
                                                                               @"eventsCmds":time,
                                                                               @"sponsors":  time }];
        instance.cafetToken      = @"";
        instance.cafetDebut      = 0;
        instance.cafetCmdEnCours = NO;
        instance.tempPhone       = nil;
        instance.alertRedir      = nil;
        [instance cafetPanierVider];
    }
    return instance;
}

#pragma mark - Global actions

+ (NSString *) hashed_string:(NSString *)input
{
    const char *s = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [NSData dataWithBytes:s length:strlen(s)];
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH]={0};
    CC_SHA256(keyData.bytes, (unsigned int)keyData.length, digest);
    NSData *out=[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    NSString *hash=[out description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    return hash;
}

+ (NSString *) encoderPourURL:(NSString *)url
{
    if (url == nil)
        return url;
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[url UTF8String];
    NSInteger sourceLen = strlen((const char *)source);
    for (NSInteger i = 0; i < sourceLen; ++i)
    {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ')
            [output appendString:@"+"];
        else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                 (thisChar >= 'a' && thisChar <= 'z') ||
                 (thisChar >= 'A' && thisChar <= 'Z') ||
                 (thisChar >= '0' && thisChar <= '9'))
            [output appendFormat:@"%c", thisChar];
        else
            [output appendFormat:@"%%%02X", thisChar];
    }
    return output;
}

+ (void) registeriOSPush:(id<UNUserNotificationCenterDelegate>)delegate
{
    if ([NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}])
    {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = delegate;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (!error)
                                  {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [[UIApplication sharedApplication] registerForRemoteNotifications];
                                      });
                                      
                                      // Notifications Actions
                                      UNNotificationAction *textA = [UNNotificationAction actionWithIdentifier:@"action-text"
                                                                                                         title:@"Afficher"
                                                                                                       options: UNNotificationActionOptionForeground];
                                      UNNotificationAction *newsA = [UNNotificationAction actionWithIdentifier:@"action-news"
                                                                                                         title:@"Afficher les news"
                                                                                                       options: UNNotificationActionOptionForeground];
                                      UNNotificationAction *eventsA = [UNNotificationAction actionWithIdentifier:@"action-events"
                                                                                                           title:@"Afficher les événements"
                                                                                                         options: UNNotificationActionOptionForeground];
                                      UNNotificationAction *clubsA = [UNNotificationAction actionWithIdentifier:@"action-clubs"
                                                                                                          title:@"Afficher les clubs"
                                                                                                        options: UNNotificationActionOptionForeground];
                                      UNNotificationAction *cafetA = [UNNotificationAction actionWithIdentifier:@"action-cafet"
                                                                                                          title:@"Afficher les commandes"
                                                                                                        options: UNNotificationActionOptionForeground];
                                      UNNotificationAction *sponsorsA = [UNNotificationAction actionWithIdentifier:@"action-sponsors"
                                                                                                             title:@"Afficher les bons plans"
                                                                                                           options: UNNotificationActionOptionForeground];
                                      UNNotificationAction *updateA = [UNNotificationAction actionWithIdentifier:@"action-update"
                                                                                                           title:@"Mettre à jour"
                                                                                                         options: UNNotificationActionOptionForeground];
                                      UNNotificationAction *guyA = [UNNotificationAction actionWithIdentifier:@"action-guy"
                                                                                                        title:@"Afficher… 😏🚀"
                                                                                                      options: UNNotificationActionOptionForeground];
                                      UNNotificationAction *userA = [UNNotificationAction actionWithIdentifier:@"action-user"
                                                                                                         title:@"Afficher l'écran de connexion"
                                                                                                       options: UNNotificationActionOptionForeground];
                                      
                                      UNNotificationCategory *text = [UNNotificationCategory categoryWithIdentifier:@"0"
                                                                                                            actions:@[textA]
                                                                                                  intentIdentifiers:@[]
                                                                                                            options: UNNotificationCategoryOptionNone];
                                      UNNotificationCategory *news = [UNNotificationCategory categoryWithIdentifier:@"1"
                                                                                                            actions:@[newsA]
                                                                                                  intentIdentifiers:@[]
                                                                                                            options: UNNotificationCategoryOptionNone];
                                      UNNotificationCategory *events = [UNNotificationCategory categoryWithIdentifier:@"2"
                                                                                                              actions:@[eventsA]
                                                                                                    intentIdentifiers:@[]
                                                                                                              options: UNNotificationCategoryOptionNone];
                                      UNNotificationCategory *clubs = [UNNotificationCategory categoryWithIdentifier:@"3"
                                                                                                             actions:@[clubsA]
                                                                                                   intentIdentifiers:@[]
                                                                                                             options: UNNotificationCategoryOptionNone];
                                      UNNotificationCategory *cafet = [UNNotificationCategory categoryWithIdentifier:@"4"
                                                                                                             actions:@[cafetA]
                                                                                                   intentIdentifiers:@[]
                                                                                                             options: UNNotificationCategoryOptionNone];
                                      UNNotificationCategory *sponsors = [UNNotificationCategory categoryWithIdentifier:@"5"
                                                                                                                actions:@[sponsorsA]
                                                                                                      intentIdentifiers:@[]
                                                                                                                options: UNNotificationCategoryOptionNone];
                                      UNNotificationCategory *update = [UNNotificationCategory categoryWithIdentifier:@"21"
                                                                                                              actions:@[updateA]
                                                                                                    intentIdentifiers:@[]
                                                                                                              options: UNNotificationCategoryOptionNone];
                                      UNNotificationCategory *guy = [UNNotificationCategory categoryWithIdentifier:@"42"
                                                                                                           actions:@[guyA]
                                                                                                 intentIdentifiers:@[]
                                                                                                           options: UNNotificationCategoryOptionNone];
                                      UNNotificationCategory *user = [UNNotificationCategory categoryWithIdentifier:@"99"
                                                                                                            actions:@[userA]
                                                                                                  intentIdentifiers:@[]
                                                                                                            options: UNNotificationCategoryOptionNone];
                                      
                                      
                                      NSSet *categories = [NSSet setWithObjects:text, news, events, clubs, cafet, sponsors, update, guy, user, nil];
                                      [center setNotificationCategories:categories];
                                  }
                              }];
    }
    else
    {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

+ (void) sendPushToken
{
    if (!DataStore.isUserLogged)
        return;
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:URL_PUSH];
    NSString *login  = @"nil";//[JNKeychain loadValueForKey:@"login"];
    NSString *pass   = @"nil";//[JNKeychain loadValueForKey:@"passw"];
    NSString *sToken = [[[NSString stringWithFormat:@"%@", [[Data sharedData] pushToken]]
                        stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *body = [NSString stringWithFormat:@"client=%@&password=%@&token=%@&os=%@&hash=%@",
                      [Data encoderPourURL:login], [Data encoderPourURL:pass], [Data encoderPourURL:sToken], @"IOS", [Data hashed_string:
                      [[[[@"Erreur mémoire cache" stringByAppendingString:login] stringByAppendingString:pass] stringByAppendingString:@"IOS"] stringByAppendingString:sToken]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[EGOCache globalCache] setData:[[Data sharedData] pushToken] forKey:@"deviceTokenPush"];
                                      }];
    [dataTask resume];
}

+ (void) delPushToken
{
    if (!DataStore.isUserLogged)
        return;
    
    [[EGOCache globalCache] removeCacheForKey:@"deviceTokenPush"];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:URL_UNPUSH];
    NSString *login  = @"nil";//[JNKeychain loadValueForKey:@"login"];
    NSString *pass   = @"nil";//[JNKeychain loadValueForKey:@"passw"];
    NSString *sToken = [[[NSString stringWithFormat:@"%@", [[Data sharedData] pushToken]]
                         stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *body = [NSString stringWithFormat:@"client=%@&password=%@&token=%@&os=%@&hash=%@",
                      [Data encoderPourURL:login], [Data encoderPourURL:pass], [Data encoderPourURL:sToken], @"IOS",
                      [Data encoderPourURL:[Data hashed_string:[[[[@"Bonjour %s !" stringByAppendingString:login] stringByAppendingString:pass] stringByAppendingString:@"IOS"] stringByAppendingString:sToken]]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                      }];
    [dataTask resume];
}

+ (UIImage *) scaleAndCropImage:(UIImage *)sourceImage
                         toSize:(CGSize)targetSize
                         retina:(BOOL)retina
{
    
    return [Data scaleAndCropImage:(UIImage *)sourceImage
                            toSize:(CGSize)targetSize
                            retina:(BOOL)retina
                               fit:NO];
}

+ (UIImage *) scaleAndCropImage:(UIImage *)sourceImage
                         toSize:(CGSize)targetSize
                         retina:(BOOL)retina
                            fit:(BOOL)fit
{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (fit)
        {
            if (widthFactor < heightFactor)
                scaleFactor = widthFactor;
            else
                scaleFactor = heightFactor;
        }
        else
        {
            if (widthFactor > heightFactor)
                scaleFactor = widthFactor;
            else
                scaleFactor = heightFactor;
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (fit)
        {
            if (widthFactor < heightFactor)
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            else if (widthFactor > heightFactor)
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
        else
        {
            if (widthFactor > heightFactor)
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            else if (widthFactor < heightFactor)
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    if (retina)
        UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    else
        UIGraphicsBeginImageContext(targetSize); // crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    if (fit)
    {
        [[UIColor whiteColor] set];
        UIRectFill(CGRectMake(0.0, 0.0, targetSize.width, targetSize.height));
    }
    
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - Update Data

- (BOOL) shouldUpdateJSON:(NSString *)JSONname
{
    NSTimeInterval max = 30;
    return ([NSDate timeIntervalSinceReferenceDate] - [_lastCheck[JSONname] doubleValue] > max);
}

/**
 Fetch data from API

 @param JSONname API module identifier
 */
- (void) updateJSON:(NSString *)JSONname
{
    /* Set URL */
    int randCache = (int)arc4random_uniform(9999);
    NSURL *url;
    if ([JSONname isEqualToString:@"eventsCmds"])
        url = [NSURL URLWithString:[NSString stringWithFormat:URL_EVENT_CM, randCache]];
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:URL_JSONS, JSONname, randCache]];
    
    /* Set REQUEST */
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    /* Set POST CONTENT */
    if ([JSONname isEqualToString:@"eventsCmds"])
    {
        if (!DataStore.isUserLogged)
        {
            [[EGOCache globalCache] removeCacheForKey:@"eventsCmds"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"eventsCmdsSent" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"eventsCmds" object:nil];
            return;
        }
        
        NSString *login  = [JNKeychain loadValueForKey:@"login"];
        NSString *pass   = [JNKeychain loadValueForKey:@"passw"];
        if (login == nil || pass == nil) {
            [[EGOCache globalCache] removeCacheForKey:@"eventsCmds"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"eventsCmdsSent" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"eventsCmds" object:nil];
            return;
        }
        NSString *toHash = [[@"Connexion en cours" stringByAppendingString:login] stringByAppendingString:pass];
        NSString *body   = [NSString stringWithFormat:@"client=%@&password=%@&hash=%@",
                            [Data encoderPourURL:login],
                            [Data encoderPourURL:pass],
                            [Data encoderPourURL:[Data hashed_string:toHash]]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    /* SEND */
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request
                                                       completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          NSDictionary *JSON = nil;
                                          /* If we have server data */
                                          if (error == nil && data != nil)
                                          {
                                              id baseJSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                         options:kNilOptions
                                                                                           error:nil];
                                              
                                              JSON = baseJSON;    // ESEOasis API: [content] -> { "key": [content] }
                                              if ([baseJSON isKindOfClass:[NSArray class]]) {
                                                  NSString *key = JSONname;
                                                  if ([JSONname isEqualToString:@"eventsCmds"])
                                                      key = @"tickets";
                                                  
                                                  JSON = [NSDictionary dictionaryWithObject:baseJSON
                                                                                     forKey:key];
                                                  data = [NSJSONSerialization dataWithJSONObject:JSON
                                                                                         options:kNilOptions
                                                                                           error:nil];
                                              }
                                              
                                              if (JSON[@"status"] != nil && [JSON[@"status"] intValue] == 1)
                                                  JSON = JSON[@"data"];
                                              
                                              /* Cache data */
                                              if (JSON != nil && JSON.count)
                                                  [[EGOCache globalCache] setData:data
                                                                           forKey:JSONname
                                                              withTimeoutInterval:90 * 86400];
                                          }
                                          /* Get cache if nothing from network */
                                          else if ([[EGOCache globalCache] hasCacheForKey:JSONname])
                                              JSON = [NSJSONSerialization JSONObjectWithData:[[EGOCache globalCache] dataForKey:JSONname]
                                                                                     options:kNilOptions
                                                                                       error:nil];

                                          /* Set data in memory */
                                          if (JSON != nil)
                                          {
                                              if ([JSONname isEqualToString:@"events"])
                                                  _events = JSON;
                                              else if ([JSONname isEqualToString:@"eventsCmds"])
                                                  _eventsCmds = JSON;
                                              else if ([JSONname isEqualToString:@"sponsors"])
                                                  _sponsors = JSON;
                                              
                                              // LastCheck
                                              [_lastCheck setValue:@([NSDate timeIntervalSinceReferenceDate]) forKey:JSONname];
                                              
                                              // Informer la vue
                                              [[NSNotificationCenter defaultCenter] postNotificationName:JSONname object:nil];
                                          }
                                          
                                          [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@Sent", JSONname] object:nil];
                                          [self updLoadingActivity:NO];
                                      }];
    [dataTask resume];
    [self updLoadingActivity:YES];
}

- (void) updLoadingActivity:(BOOL)visible
{
    static NSInteger loadingCount = 0;
    
    if (visible)
        ++loadingCount;
    else
        --loadingCount;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(loadingCount > 0)];
}

+ (void) checkAvailability
{
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:[NSURL URLWithString:URL_APP_STAT]
                                                   completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          if (error == nil && data != nil) {
                                              NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                                   options:kNilOptions
                                                                                                     error:nil];
                                              if (JSON[@"data"] != nil && [JSON[@"data"] isKindOfClass:[NSDictionary class]]) {
                                                  NSDictionary *d = JSON[@"data"];
                                                  if (d[@"title"] != nil  && ![d[@"title"] isEqualToString:@""] &&
                                                      d[@"message"] != nil  && ![d[@"message"] isEqualToString:@""]) {
                                                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:d[@"title"]
                                                                                                                     message:d[@"message"]
                                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                                      
                                                      NSArray *buttons = d[@"buttons"];
                                                      if (buttons != nil && [buttons isKindOfClass:[NSArray class]])
                                                      {
                                                          for (NSDictionary *button in buttons) {
                                                              UIAlertActionStyle style = UIAlertActionStyleDefault;
                                                              if ([button[@"type"] intValue] == 0)
                                                                  style = UIAlertActionStyleCancel;
                                                              else if ([button[@"type"] intValue] == -1)
                                                                  style = UIAlertActionStyleDestructive;
                                                              [alert addAction:[UIAlertAction actionWithTitle:button[@"title"]
                                                                                                        style:style handler:nil]];
                                                          }
                                                      }
                                                      
                                                      UIViewController *vc = [UIApplication sharedApplication].delegate.window.rootViewController;
                                                      if (vc.presentedViewController != nil)
                                                          [vc.presentedViewController presentViewController:alert animated:YES completion:nil];
                                                      else
                                                          [vc presentViewController:alert animated:YES completion:nil];
                                                  }
                                              }
                                          }
                                      }];
    [[Data sharedData] updLoadingActivity:YES];
    [dataTask resume];

}

#pragma mark - Cafet

- (void) cafetPanierAjouter:(NSDictionary *)elem
{
    [_cafetPanier addObject:elem];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updPanier" object:nil];
}

- (void) cafetPanierSupprimerAt:(NSInteger)index
{
    [_cafetPanier removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updPanier" object:nil];
}

- (void) cafetPanierVider
{
    _cafetPanier = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updPanier" object:nil];
}

#pragma mark - Lydia

- (BOOL)            textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
            replacementString:(NSString *)string
{
    NSString  *proposedNewString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString  *result = [proposedNewString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.tempPhone = result;
    return YES;
}

#pragma mark - Event

- (void) sendMail:(NSDictionary *)data
             inVC:(UIViewController *)vc
{
    if (!DataStore.isUserLogged)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous n'êtes pas connecté"
                                                                       message:@"Impossible de vous envoyer votre place par mail.\nContactez un membre du BDE."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [vc presentViewController:alert animated:YES completion:nil];
        return;
    }
    if ([self.tempPhone isEqualToString:@""])
    {
        self.tempPhone = nil;
        return;
    }
    
    NSString *mailAddress = [JNKeychain loadValueForKey:@"mail"];
    
    /* We already have the mail address with v4.1 new connection service */
    if (mailAddress != nil)
    {
        [self send:mailAddress with:data in:vc];
        return;
    }
    /* Otherwise, we ask the mail address as before */
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Entrez votre mail pour recevoir votre place"
                                                                   message:@"Entrez une adresse valide ci-dessous.\nEn cas de soucis, vous pouvez toujours vous renvoyer un mail en tapant sur la place dans votre historique d'achats (onglet Événements › bouton ticket)."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField)
     {
         textField.placeholder  = @"sterling.archer@reseau.eseo.fr";
         textField.keyboardType = UIKeyboardTypeEmailAddress;
         textField.delegate     = self;
     }];
    UIAlertAction *validateAction = [UIAlertAction actionWithTitle:@"Valider"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action)
                                     {
                                         NSString *mailAddress = self.tempPhone;
                                         [self send:mailAddress with:data in:vc];
                                     }];
    [alert addAction:validateAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    [alert setPreferredAction:validateAction];
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void) send:(NSString *)email
         with:(NSDictionary *)data
           in:(UIViewController *)vc
{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    NSURL    *url      = [NSURL URLWithString:URL_EVENT_ML];
    NSString *login    = [JNKeychain loadValueForKey:@"login"];
    NSString *pass     = [JNKeychain loadValueForKey:@"passw"];
    NSString *mail     = [[email dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    NSString *body     = [NSString stringWithFormat:@"client=%@&password=%@&idcmd=%@&email=%@&hash=%@",
                          [Data encoderPourURL:login], [Data encoderPourURL:pass], [Data encoderPourURL:data[@"id"]],
                          [Data encoderPourURL:mail],
                          [Data encoderPourURL:[Data hashed_string:[[[[@"Email invalide" stringByAppendingString:login] stringByAppendingString:pass] stringByAppendingString:data[@"id"]] stringByAppendingString:mail]]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request
                                                       completionHandler:^(NSData *data2, NSURLResponse *r, NSError *error)
                                      {
                                          NSString *message = @"Erreur inconnue… ¯\\_(ツ)_/¯\nParlez-en à un membre du BDE";
                                          if (error == nil && data2 != nil)
                                          {
                                              NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data2
                                                                                                   options:kNilOptions
                                                                                                     error:nil];
                                              if ([JSON[@"status"] intValue] == 1)
                                                  message = [NSString stringWithFormat:@"Votre place vous a été envoyée à %@ !\n\nEn cas de soucis, vous pouvez toujours vous renvoyer un mail en tapant sur la place dans votre historique d'achats (onglet Événements › bouton ticket).\nVérifiez éventuellement votre dossier spams.", email];
                                              else if (JSON[@"cause"] != nil)
                                                  message = [@"Erreur ¯\\_(ツ)_/¯\nCause :\n" stringByAppendingString:JSON[@"cause"]];
                                              else
                                                  message = @"Erreur inconnue : impossible de vérifier le mail.\nParlez-en à un membre du BDE";
                                          }
                                          else
                                              message = @"Erreur : impossible d'envoyer le mail, vous n'êtes pas connecté à Internet.\nParlez-en à un membre du BDE";
                                          
                                          self.tempPhone = nil;
                                          
                                          UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"Envoi de la place par mail" message:message preferredStyle:UIAlertControllerStyleAlert];
                                          [alert2 addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                     style:UIAlertActionStyleCancel
                                                                                   handler:nil]];
                                          [vc presentViewController:alert2 animated:YES completion:Nil];
                                      }];
    [dataTask resume];
}

#pragma mark - Link actions

- (void) openURL:(NSString *)url
       currentVC:(UIViewController *)vc
{
    [self openURL:url currentVC:vc title:nil];
}

/**
 Common function to Open URL. Configures a customized Safari View Controller.

 @param url Website to visit
 @param vc Parent view controller presenting Safari View Controller
 @param defaultWebsiteTitle Provide a title if you want to support Handoff/Siri Shortcuts, otherwise leave nil
 */
- (void) openURL:(NSString *)url
       currentVC:(UIViewController *)vc
           title:(NSString *)defaultWebsiteTitle
{
    if ([[url substringToIndex:6] isEqualToString:@"mailto"])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        return;
    }
    
    NSURL *cleanURL = [NSURL URLWithString:[url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:cleanURL
                                                         entersReaderIfAvailable:NO];
    if ([SFSafariViewController instancesRespondToSelector:@selector(preferredBarTintColor)])
    {
        safari.preferredBarTintColor = [UINavigationBar appearance].barTintColor;
        safari.preferredControlTintColor = [UINavigationBar appearance].tintColor;
    }
    
    /* Update Handoff/Siri Shortcuts */
    // SFSafariViewController already broadcasts Handoff, but is inhibited by the app's own Handoff suggestions.
    // Currently used for Campus/Portail/Mails ESEO quick links.
    if (defaultWebsiteTitle != nil && ![defaultWebsiteTitle isEqualToString:@""])
    {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        userActivity.title = defaultWebsiteTitle;
        userActivity.webpageURL = cleanURL;
        userActivity.eligibleForSearch = YES;
        userActivity.eligibleForHandoff = YES;
        userActivity.eligibleForPublicIndexing = YES;
        safari.userActivity = userActivity;
        [userActivity becomeCurrent];
    }
    
    [vc presentViewController:safari animated:YES completion:nil];
}

- (void) twitter:(NSString *)username
       currentVC:(UIViewController *)vc
{
    NSString *nickname = [username stringByReplacingOccurrencesOfString:@"@" withString:@""];
    NSURL *twitter = [NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", nickname]];
    if ([[UIApplication sharedApplication] canOpenURL:twitter])
        [[UIApplication sharedApplication] openURL:twitter];
    else
        [self openURL:[NSString stringWithFormat:@"https://twitter.com/%@", nickname] currentVC:vc];
}
/*
- (void) youtube:(NSString *)username
       currentVC:(UIViewController *)vc
{
    NSURL *linkToAppURL = [NSURL URLWithString:[NSString stringWithFormat:@"youtube://user/%@", username]];
    
    if ([[UIApplication sharedApplication] canOpenURL:linkToAppURL])
        [[UIApplication sharedApplication] openURL:linkToAppURL];
    else
        [self openURL:[NSString stringWithFormat:@"https://youtube.com/user/%@", username] currentVC:vc];
}*/

- (void) snapchat:(NSString *)username
        currentVC:(UIViewController *)vc
{
    if (username == nil)
        return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:username
                                                                   message:@"Ajoutez le pseudo ci-dessus sur Snapchat !"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    NSURL *snap = [NSURL URLWithString:[@"snapchat://add/" stringByAppendingString:username]];
    UIAlertAction *snapAction = [UIAlertAction actionWithTitle:@"Ajouter sur Snapchat"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
                                 {
                                     if ([[UIApplication sharedApplication] canOpenURL:snap])
                                         [[UIApplication sharedApplication] openURL:snap];
                                     else
                                         [self openURL:[NSString stringWithFormat:@"https://www.snapchat.com/add/%@", username] currentVC:vc];
                                 }];
    [alert addAction:snapAction];
    [alert setPreferredAction:snapAction];
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void) instagram:(NSString *)username
         currentVC:(UIViewController *)vc
{
    NSURL *instagram = [NSURL URLWithString:[NSString stringWithFormat:@"instagram://user?username=%@", username]];
    if ([[UIApplication sharedApplication] canOpenURL:instagram])
        [[UIApplication sharedApplication] openURL:instagram];
    else
        [self openURL:[NSString stringWithFormat:@"https://instagram.com/%@/", username] currentVC:vc];
}

- (void) mail:(NSString *)dest
    currentVC:(UIViewController <MFMailComposeViewControllerDelegate> *)vc
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *controller = [MFMailComposeViewController new];
        [[controller navigationBar] setTintColor:[UINavigationBar appearance].tintColor];
        [controller setToRecipients:@[dest]];
        [controller setMailComposeDelegate:vc];
        [vc presentViewController:controller animated:YES completion:^{
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
        }];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Impossible d'envoyer un mail"
                                                                       message:@"Vérifiez que vous avez un compte configuré sur cet appareil."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [vc presentViewController:alert animated:YES completion:nil];
    }
}

- (void) tel:(NSString *)num
   currentVC:(UIViewController *)vc
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:num
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    NSURL *tel = [NSURL URLWithString:[@"tel://" stringByAppendingString:num]];
    if ([[UIApplication sharedApplication] canOpenURL:tel])
    {
        UIAlertAction *callAction = [UIAlertAction actionWithTitle:@"Appeler"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:tel];
        }];
        [alert addAction:callAction];
        [alert addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                  style:UIAlertActionStyleCancel handler:nil]];
        [alert setPreferredAction:callAction];
    }
    else
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel handler:nil]];
    [vc presentViewController:alert animated:YES completion:nil];
}

+ (UIImage *) linksToolbarBDEIcon
{
    /* Image size constants */
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(40, 40);
    
    /* Create context */
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef mainViewContentContext = CGBitmapContextCreate(NULL, targetSize.width * scale,
                                                                targetSize.height * scale, 8, 0,
                                                                colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    /* Get image and its mask on disk */
    int themeNumber    = (int)[ThemeManager objc_currentTheme];
    UIImage *image     = [UIImage imageNamed:[NSString stringWithFormat:@"App-Icon-%d",
                                              themeNumber]];
    UIImage *maskImage = [UIImage imageNamed:@"eseo"];
    
    /* Draw image and mask */
    CGRect targetRect = CGRectMake(0, 0, targetSize.width * scale,
                                         targetSize.height * scale);
    CGContextClipToMask(mainViewContentContext, targetRect, maskImage.CGImage);
    CGContextDrawImage (mainViewContentContext, targetRect, image.CGImage);

    /* Get result back */
    CGImageRef newImage = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    
    /* Set masked image to the button */
    UIImage *finalImage = [Data scaleAndCropImage:[UIImage imageWithCGImage:newImage]
                                           toSize:targetSize retina:YES];
    CGImageRelease(newImage);
    
    return [finalImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

@end

