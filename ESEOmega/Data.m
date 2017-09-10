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
//        NSUserDefaults *defaults  = [NSUserDefaults standardUserDefaults];
        
        static dispatch_once_t pred;        // Lock
        dispatch_once(&pred, ^{             // This code is called at most once per app
            instance = [[Data allocWithZone:NULL] init];
        });
        
        // Préférences par défaut
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults registerDefaults:@{ @"GPenabled": @NO}];
        [defaults synchronize];
        
        EGOCache *ec        = [EGOCache globalCache];
        instance.news       = (![ec hasCacheForKey:@"news"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"news"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.events     = (![ec hasCacheForKey:@"events"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"events"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.eventsCmds = (![ec hasCacheForKey:@"eventsCmds"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"eventsCmds"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.clubs      = (![ec hasCacheForKey:@"clubs"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"clubs"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.cmds       = (![ec hasCacheForKey:@"cmds"] || ![Data estConnecte]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"cmds"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.service    = nil;
        instance.menus      = (![ec hasCacheForKey:@"menus"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"menus"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.sponsors   = (![ec hasCacheForKey:@"sponsors"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"sponsors"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.salles     = (![ec hasCacheForKey:@"rooms"]) ? nil
                                                             : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"rooms"]
                                                                                               options:kNilOptions
                                                                                                 error:nil];
        instance.ingenews   = (![ec hasCacheForKey:@"ingenews"]) ? nil
                                                                 : [NSJSONSerialization JSONObjectWithData:[ec dataForKey:@"ingenews"]
                                                                                                   options:kNilOptions
                                                                                                     error:nil];
        NSNumber *time      = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
        instance.lastCheck  = [NSMutableDictionary dictionaryWithDictionary:@{ @"news":      time,
                                                                               @"events":    time,
                                                                               @"eventsCmds":time,
                                                                               @"clubs":     time,
                                                                               @"cmds":      time,
                                                                               @"menus":     time,
                                                                               @"sponsors":  time,
                                                                               @"rooms":     time,
                                                                               @"ingenews":  time }];
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

+ (BOOL) isiPad {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

#pragma mark - Update Data

- (BOOL) shouldUpdateJSON:(NSString *)JSONname
{
    NSTimeInterval max = ([JSONname isEqualToString:@"cmds"]) ? 10 : 30;
    /*if (!([NSDate timeIntervalSinceReferenceDate] - [_lastCheck[JSONname] doubleValue] > max))
        NSLog(@"Refusé. Mis à jour il y a peu.");*/
    return ([NSDate timeIntervalSinceReferenceDate] - [_lastCheck[JSONname] doubleValue] > max);
}

- (void) updateJSON:(NSString *)JSONname
{
    [self updateJSON:JSONname options:0];
}

/**
 Fetch data from API

 @param JSONname API module identifier
 @param options Used for news to fetch old articles (offset)
 */
- (void) updateJSON:(NSString *)JSONname
            options:(NSInteger)options
{
    /* Set URL */
    int randCache = (int)arc4random_uniform(9999);
    NSURL *url;
    if ([JSONname isEqualToString:@"news"])
    {
        CGSize sz = [UIScreen mainScreen].bounds.size;
        CGFloat l = sz.height;
        if (sz.width > sz.height)
            l = sz.width;
        int nbrNews = (int)MIN(20, l / 44);
        url = [NSURL URLWithString:[NSString stringWithFormat:URL_NEWS, nbrNews, (int)options * nbrNews, randCache]];
    }
    else if ([JSONname isEqualToString:@"cmds"])
        url = [NSURL URLWithString:[NSString stringWithFormat:URL_CMDS, randCache]];
    else if ([JSONname isEqualToString:@"eventsCmds"])
        url = [NSURL URLWithString:[NSString stringWithFormat:URL_EVENT_CM, randCache]];
    else if ([JSONname isEqualToString:@"service"])
        url = [NSURL URLWithString:[NSString stringWithFormat:URL_SERVICE, randCache]];
//    else if ([JSONname isEqualToString:@"ingenews"])
//        url = [NSURL URLWithString:[NSString stringWithFormat:URL_INGENEWS, randCache]];
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:URL_JSONS, JSONname, randCache]];
    
    /* Set REQUEST */
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    /* Set POST CONTENT */
    if ([JSONname isEqualToString:@"cmds"])
    {
        if (!DataStore.isUserLogged)
        {
            _cmds = nil;
            [[EGOCache globalCache] removeCacheForKey:@"cmds"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cmdsSent" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cmds" object:nil];
            return;
        }
        
        NSString *login  = @"nil";//[JNKeychain loadValueForKey:@"login"];
        NSString *pass   = @"nil";//[JNKeychain loadValueForKey:@"passw"];
        NSString *toHash = [[@"Connexion au serveur ..." stringByAppendingString:login] stringByAppendingString:pass];
        NSString *body   = [NSString stringWithFormat:@"client=%@&password=%@&hash=%@",
                            [Data encoderPourURL:login],
                            [Data encoderPourURL:pass],
                            [Data encoderPourURL:[Data hashed_string:toHash]]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else if ([JSONname isEqualToString:@"eventsCmds"])
    {
        if (!DataStore.isUserLogged)
        {
            _cmds = nil;
            [[EGOCache globalCache] removeCacheForKey:@"eventsCmds"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"eventsCmdsSent" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"eventsCmds" object:nil];
            return;
        }
        
        NSString *login  = [JNKeychain loadValueForKey:@"login"];
        NSString *pass   = [JNKeychain loadValueForKey:@"passw"];
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
                                                  if ([JSONname isEqualToString:@"news"])
                                                      key = @"articles";
                                                  else if ([JSONname isEqualToString:@"eventsCmds"])
                                                      key = @"tickets";
                                                  else if ([JSONname isEqualToString:@"cmds"])
                                                      key = @"history";
                                                  else if ([JSONname isEqualToString:@"rooms"])
                                                      key = @"rooms";
                                                  else if ([JSONname isEqualToString:@"ingenews"])
                                                      key = @"fichiers";
                                                  
                                                  JSON = [NSDictionary dictionaryWithObject:baseJSON
                                                                                     forKey:key];
                                                  data = [NSJSONSerialization dataWithJSONObject:JSON
                                                                                         options:kNilOptions
                                                                                           error:nil];
                                              }
                                              
                                              if (JSON[@"status"] != nil && [JSON[@"status"] intValue] == 1)
                                                  JSON = JSON[@"data"];
                                              
                                              /* Cache data */
                                              if (JSON != nil && JSON.count && options == 0 && ![JSONname isEqualToString:@"service"])
                                                  [[EGOCache globalCache] setData:data
                                                                           forKey:JSONname
                                                              withTimeoutInterval:90 * 86400];
                                          }
                                          /* Get cache if nothing from network */
                                          else if ([[EGOCache globalCache] hasCacheForKey:JSONname] && options == 0)
                                              JSON = [NSJSONSerialization JSONObjectWithData:[[EGOCache globalCache] dataForKey:JSONname]
                                                                                     options:kNilOptions
                                                                                       error:nil];

                                          /* Set data in memory */
                                          if (JSON != nil)
                                          {
                                              if ([JSONname isEqualToString:@"news"])
                                                  [self traiterNewNews:JSON start:options];
                                              else if ([JSONname isEqualToString:@"events"])
                                                  _events = JSON;
                                              else if ([JSONname isEqualToString:@"eventsCmds"])
                                                  _eventsCmds = JSON;
                                              else if ([JSONname isEqualToString:@"clubs"])
                                                  _clubs = JSON;
                                              else if ([JSONname isEqualToString:@"cmds"])
                                                  _cmds = JSON;
                                              else if ([JSONname isEqualToString:@"service"])
                                                  _service = JSON;
                                              else if ([JSONname isEqualToString:@"menus"])
                                                  _menus = JSON;
                                              else if ([JSONname isEqualToString:@"sponsors"])
                                                  _sponsors = JSON;
                                              else if ([JSONname isEqualToString:@"rooms"])
                                                  _salles = JSON;
                                              else if ([JSONname isEqualToString:@"ingenews"])
                                                  _ingenews = JSON;
                                              
                                              // LastCheck
                                              if (options == 0)
                                                  [_lastCheck setValue:@([NSDate timeIntervalSinceReferenceDate]) forKey:JSONname];
                                              
                                              // Informer la vue
                                              if (![JSONname isEqualToString:@"news"])
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:JSONname object:nil];
                                          }
                                          
                                          [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@Sent", JSONname] object:nil];
                                          if ([JSONname isEqualToString:@"news"] && options != 0)
                                              [[NSNotificationCenter defaultCenter] postNotificationName:@"moreNewsSent" object:nil];
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

- (void) traiterNewNews:(NSDictionary *)JSON
                  start:(NSInteger)index
{
    if (_news == nil || [_news[@"articles"] count] < 1)
        _news = JSON;
    else
    {
        NSArray *oldNews = _news[@"articles"];
        NSArray *newNews =  JSON[@"articles"];
        NSMutableArray *toAddNews = [NSMutableArray array];
        NSMutableIndexSet *toUpdNewsIndexes = [NSMutableIndexSet indexSet];
        NSMutableArray    *toUpdNewsData  = [NSMutableArray array];
        for (NSDictionary *newArticle in newNews)
        {
            BOOL pasDedans = YES;
            NSUInteger index = 0;
            for (NSDictionary *oldArticle in oldNews)
            {
                if ([newArticle[@"id"] integerValue] == [oldArticle[@"id"] integerValue])
                {
                    pasDedans = NO;
                    break;
                }
                index++;
            }
            if (pasDedans)
                [toAddNews addObject:newArticle];
            else
            {
                [toUpdNewsIndexes addIndex:index];
                [toUpdNewsData addObject:newArticle];
            }
        }
        
        NSMutableArray *m_oldNews = [NSMutableArray arrayWithArray:oldNews];
        [m_oldNews replaceObjectsAtIndexes:toUpdNewsIndexes withObjects:toUpdNewsData];
        
        NSMutableArray *turfuNews = [NSMutableArray array];
        if (index == 0)
            [turfuNews addObjectsFromArray:toAddNews];
        [turfuNews addObjectsFromArray:m_oldNews];
        if (index != 0)
            [turfuNews addObjectsFromArray:toAddNews];

        _news = @{ @"articles": [NSArray arrayWithArray:turfuNews] };
    }
    
    if (index > 0)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"moreNewsOK" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"news" object:nil];
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

- (void) startLydia:(NSInteger)idCmd
            forType:(NSString *)catOrder
{
    if ([JNKeychain loadValueForKey:@"phone"] == nil)
    {
        NSString *message = @"Votre numéro de téléphone portable est utilisé par Lydia afin de lier la commande à votre compte. Il n'est pas stocké sur nos serveurs.";
        if (self.tempPhone != nil)
            message = [message stringByAppendingString:@"\n\nRéessayez, numéro incorrect."];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Paiement par Lydia"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField)
         {
             textField.placeholder  = @"0601234242";
             textField.keyboardType = UIKeyboardTypePhonePad;
             textField.delegate     = self;
             textField.text         = self.tempPhone;
         }];
        UIAlertAction *payAction = [UIAlertAction actionWithTitle:@"Payer maintenant"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action)
                                    {
                                        [self sendLydia:[NSString stringWithFormat:@"%ld", (long)idCmd]
                                                forType:catOrder];
                                    }];
        [alert addAction:payAction];
        [alert addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert setPreferredAction:payAction];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert
                                                                                           animated:YES completion:nil];
    }
    else
        [self sendLydia:[NSString stringWithFormat:@"%ld", (long)idCmd]
                forType:catOrder];
}

- (BOOL)            textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
            replacementString:(NSString *)string
{
    NSString  *proposedNewString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString  *result = [proposedNewString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.tempPhone = result;
    return YES;
}

- (void) sendLydia:(NSString *)idCmd
           forType:(NSString *)catOrder
{
    if ([JNKeychain loadValueForKey:@"phone"] == nil)
    {
        NSString *num = self.tempPhone;
        if ([num rangeOfString:@"^((\\+|00)33\\s?|0)[679](\\s?\\d{2}){4}$" options:NSRegularExpressionSearch].location != NSNotFound)
        {
            self.tempPhone = nil;
            [JNKeychain saveValue:num forKey:@"phone"];
        }
        else
        {
            [self startLydia:[idCmd intValue]
                     forType:catOrder];  // Redemande le numéro de téléphone
            return;
        }
    }
    
    if (DataStore.isUserLogged)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Demande de paiement Lydia"
                                                                       message:@"Veuillez patienter…"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert
                                                                                           animated:YES completion:nil];
        
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                       delegate:nil
                                                                                  delegateQueue:[NSOperationQueue mainQueue]];
        
        NSString *tel      = [[[JNKeychain loadValueForKey:@"phone"] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
        NSURL    *url      = [NSURL URLWithString:URL_CMD_LY_1];
        NSString *login    = [JNKeychain loadValueForKey:@"login"];
        NSString *pass     = [JNKeychain loadValueForKey:@"passw"];
        NSString *body     = [NSString stringWithFormat:@"username=%@&password=%@&idcmd=%@&phone=%@&cat_order=%@&hash=%@&os=IOS",
                              [Data encoderPourURL:login], [Data encoderPourURL:pass], [Data encoderPourURL:idCmd],
                              [Data encoderPourURL:tel],
                              [Data encoderPourURL:catOrder],
                              [Data encoderPourURL:[Data hashed_string:[[[[[login stringByAppendingString:pass] stringByAppendingString:tel] stringByAppendingString:idCmd] stringByAppendingString:catOrder] stringByAppendingString:@"Paiement effectué !"]]]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request
                                                           completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                          {
                                              [alert dismissViewControllerAnimated:YES completion:^{
                                                  if (error == nil && data != nil)
                                                  {
                                                      NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                                           options:kNilOptions
                                                                                                             error:nil];
                                                      [self openLydia:JSON];
                                                  }
                                                  else
                                                  {
                                                      UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"Erreur" message:@"Impossible d'envoyer la requête de paiement." preferredStyle:UIAlertControllerStyleAlert];
                                                      [alert2 addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                                 style:UIAlertActionStyleCancel
                                                                                               handler:nil]];
                                                      [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert2 animated:YES completion:Nil];
                                                  }
                                              }];
                                          }];
        [dataTask resume];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous n'êtes pas connecté"
                                                                       message:@"Impossible de passer une commande."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert
                                                                                           animated:YES completion:nil];
    }
}

- (void) openLydia:(NSDictionary *)JSON
{
    if (JSON != nil && [JSON[@"status"] intValue] == 1 &&
        JSON[@"data"][@"lydia_intent"] && ![JSON[@"data"][@"lydia_intent"] isEqualToString:@""] &&
        JSON[@"data"][@"lydia_url"]    && ![JSON[@"data"][@"lydia_url"]    isEqualToString:@""])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Redirection vers le paiement en cours…"
                                                                       message:@"L'app/site Lydia devrait s'ouvrir…"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert
                                                                                           animated:YES completion:nil];
        self.alertRedir = alert;
        
        NSURL *appLydia = [NSURL URLWithString:JSON[@"data"][@"lydia_intent"]];
        if ([[UIApplication sharedApplication] canOpenURL:appLydia])
            [[UIApplication sharedApplication] openURL:appLydia];
        else
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:JSON[@"data"][@"lydia_url"]]];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }
    else
    {
        NSString *cause = @"Demande de paiement annulée.\nRaison inconnue 😿";
        if ([JSON[@"status"] intValue] == 1)
            cause = @"Demande de paiement annulée.\nImpossible d'ouvrir l'app ou le site Lydia.";
        else if (![JSON[@"cause"] isEqualToString:@""] && JSON[@"cause"] != nil)
            cause = [@"Demande de paiement annulée.\nRaison :\n" stringByAppendingString:JSON[@"cause"]];
    
        switch ([JSON[@"status"] intValue])
        {
            case -2:
                [JNKeychain deleteValueForKey:@"phone"];
                break;
                
            case -4:
                cause = [cause stringByAppendingString:@"\nSi votre mot de passe a été changé récemment, essayez de déconnecter votre compte de l'application puis de le reconnecter."];
                break;
        }
        if ([JSON[@"status"] intValue] <= -8000)
            cause = [cause stringByAppendingString:[NSString stringWithFormat:@"\nCode : %d", [JSON[@"status"] intValue]]];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                       message:cause
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert
                                                                                           animated:YES completion:nil];
    }
}

- (void) checkLydia:(NSDictionary *)data
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"État du paiement Lydia"
                                                                   message:@"Vérification en cours…"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    NSURL    *url      = [NSURL URLWithString:URL_CMD_LY_2];
    NSString *login    = [JNKeychain loadValueForKey:@"login"];
    NSString *pass     = [JNKeychain loadValueForKey:@"passw"];
    NSString *body     = [NSString stringWithFormat:@"username=%@&password=%@&idcmd=%@&cat_order=%@&hash=%@",
                          [Data encoderPourURL:login], [Data encoderPourURL:pass], [Data encoderPourURL:data[@"id"]],
                          [Data encoderPourURL:data[@"cat"]],
                          [Data encoderPourURL:[Data hashed_string:[[[[login stringByAppendingString:pass] stringByAppendingString:data[@"id"]] stringByAppendingString:data[@"cat"]] stringByAppendingString:@"Paiement refusé par votre banque"]]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request
                                                       completionHandler:^(NSData *data2, NSURLResponse *r, NSError *error)
                                      {
                                          [alert dismissViewControllerAnimated:YES completion:^{
                                              NSString *message = @"Erreur inconnue… ¯\\_(ツ)_/¯\nParlez-en à un membre du BDE";
                                              if (error == nil && data2 != nil)
                                              {
                                                  NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data2
                                                                                                       options:kNilOptions
                                                                                                         error:nil];
                                                  if ([JSON[@"status"] intValue] == 1)
                                                  {
                                                      message = JSON[@"data"][@"info"];
                                                      
                                                      if ([data[@"cat"] isEqualToString:@"EVENT"] &&
                                                          [JSON[@"data"][@"status"] integerValue] == 2)
                                                          [self sendMail:data
                                                                    inVC:[UIApplication sharedApplication].delegate.window.rootViewController];
                                                  }
                                                  else if (JSON[@"cause"] != nil)
                                                      message = JSON[@"cause"];
                                                  else
                                                      message = @"Erreur inconnue : impossible de vérifier le paiement.\nParlez-en à un membre du BDE";
                                              }
                                              else
                                                  message = @"Erreur : impossible de vérifier le paiement, vous n'êtes pas connecté à Internet.\nParlez-en à un membre du BDE";
                                              
                                              UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"État du paiement Lydia" message:message preferredStyle:UIAlertControllerStyleAlert];
                                              [alert2 addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                         style:UIAlertActionStyleCancel
                                                                                       handler:nil]];
                                              [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert2 animated:YES completion:Nil];
                                          }];
                                      }];
    [dataTask resume];
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
    [vc presentViewController:safari animated:YES completion:nil];
}

- (void) twitter:(NSString *)username
       currentVC:(UIViewController *)vc
{
    NSURL *twitter = [NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", username]];
    if ([[UIApplication sharedApplication] canOpenURL:twitter])
        [[UIApplication sharedApplication] openURL:twitter];
    else
        [self openURL:[NSString stringWithFormat:@"https://twitter.com/%@", username] currentVC:vc];
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

