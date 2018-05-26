//
//  Data.h
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

@import Foundation;
@import UIKit;
@import MessageUI;
@import SafariServices;
@import Security;
@import UserNotifications;
#import "EGOCache.h"
#import <CommonCrypto/CommonHMAC.h>
#import "JNKeychain.h"

#define NEW_UPD_TI @"Une nouvelle version de l'app est disponible"
#define NEW_UPD_TE @"Merci de mettre l'application à jour pour commander"
#define NEW_UPD_BT @"Mettre à jour"

#define URL_APPSTORE @"https://itunes.apple.com/app/apple-store/id966385182?pt=104224803&ct=updCafet&mt=8"

#define URL_JSONS    @"https://api.bdeeseo.fr/%@?%d"
#define URL_NEWS     @"https://api.bdeeseo.fr/news?height=%d&ptr=%d&uzless=%d"
#define URL_NEWS_LNK @"https://bdeeseo.fr/news/%d"
#define URL_NWS_MORE @"https://api.bdeeseo.fr/news/%d?%d"
#define URL_EVN_MORE @"https://api.bdeeseo.fr/events/%d?%d"
#define URL_EVN_SIGN @"https://api.bdeeseo.fr/events/signup/%d"
#define URL_CLB_MORE @"https://api.bdeeseo.fr/clubs/%d?%d"
#define URL_CMDS     @"https://api.bdeeseo.fr/order/list?%d"
#define URL_1CMD     @"https://api.bdeeseo.fr/order/resume"
#define URL_CMD_NEW  @"https://api.bdeeseo.fr/order/prepare"
#define URL_CMD_DATA @"https://api.bdeeseo.fr/order/items"
#define URL_CMD_SEND @"https://api.bdeeseo.fr/order/send"
#define URL_CMD_LY_1 @"https://api.bdeeseo.fr/lydia/ask"
#define URL_CMD_LY_2 @"https://api.bdeeseo.fr/lydia/check"
#define URL_SERVICE  @"https://api.bdeeseo.fr/info/service?%d"
#define URI_CAFET    @"https://portail.bdeeseo.fr/modules/lacommande/assets/"
#define URL_EVENT_CM @"https://api.bdeeseo.fr/event/list?%d"
#define URL_EVENT_NE @"https://api.bdeeseo.fr/event/prepare"
#define URL_EVENT_DT @"https://api.bdeeseo.fr/event/items"
#define URL_EVENT_SD @"https://api.bdeeseo.fr/event/send"
#define URL_EVENT_ML @"https://api.bdeeseo.fr/event/mail"
#define URL_PUSH     @"https://api.bdeeseo.fr/push/register"
#define URL_UNPUSH   @"https://api.bdeeseo.fr/push/unregister"
#define URL_GP       @"https://api.bdeeseo.fr/gantier/scores"
#define URL_GP_STATE @"https://api.bdeeseo.fr/gantier/state"
#define URL_APP_STAT @"https://api.bdeeseo.fr/apps/status"

#define URL_ACTIVITY @"https://bdeeseo.fr"
#define URL_ACT_NEWS @"https://bdeeseo.fr/news"
#define URL_ACT_EVNT @"https://bdeeseo.fr/events"
#define URL_ACT_CLUB @"https://bdeeseo.fr/clubs"
#define URL_ACT_SPON @"https://bdeeseo.fr/sponsors"

#define MAX_ORDER_TIME 582

@interface Data : NSObject <UITextFieldDelegate, UNUserNotificationCenterDelegate>

+ (Data *) sharedData;

@property (strong, nonatomic) NSDictionary *events;
@property (strong, nonatomic) NSDictionary *eventsCmds;
@property (strong, nonatomic) NSDictionary *clubs;
@property (strong, nonatomic) NSDictionary *cmds;
@property (strong, nonatomic) NSDictionary *service;
@property (strong, nonatomic) NSDictionary *menus;
@property (strong, nonatomic) NSDictionary *sponsors;
@property (strong, nonatomic) NSMutableDictionary *lastCheck;
@property (nonatomic) NSTimeInterval launchTime;
@property (strong, nonatomic) NSArray *cafetData;
@property (strong, nonatomic) NSMutableArray *cafetPanier;
@property (strong, nonatomic) NSString *cafetToken;
@property (assign, nonatomic) NSTimeInterval cafetDebut;
@property (assign, nonatomic) BOOL cafetCmdEnCours;
@property (strong, nonatomic) NSData *pushToken;
@property (strong, nonatomic) UIViewController<MFMailComposeViewControllerDelegate> *t_currentTopVC;
@property (strong, nonatomic) NSString *tempPhone;
@property (strong, nonatomic) UIAlertController *alertRedir;

+ (NSString *) hashed_string:(NSString *)input;
+ (NSString *) encoderPourURL:(NSString *)url;
+ (void) registeriOSPush:(id<UNUserNotificationCenterDelegate>)delegate;
+ (void) sendPushToken;
+ (void) delPushToken;
+ (UIImage *) scaleAndCropImage:(UIImage *)sourceImage toSize:(CGSize)targetSize retina:(BOOL)retina;
+ (UIImage *) scaleAndCropImage:(UIImage *)sourceImage toSize:(CGSize)targetSize retina:(BOOL)retina fit:(BOOL)fit;
+ (BOOL) isiPad;
+ (void) checkAvailability;

- (BOOL) shouldUpdateJSON:(NSString *)JSONname;
- (void) updateJSON:(NSString *)JSONname;
- (void) updLoadingActivity:(BOOL)visible;

- (void) cafetPanierAjouter:(NSDictionary *)elem;
- (void) cafetPanierSupprimerAt:(NSInteger)index;
- (void) cafetPanierVider;

- (void) startLydia:(NSInteger)idCmd
            forType:(NSString *)catOrder;
- (void) sendLydia:(NSString *)idCmd
           forType:(NSString *)catOrder;
- (void) openLydia:(NSDictionary *)JSON;
- (void) checkLydia:(NSDictionary *)data;
- (void) sendMail:(NSDictionary *)data
             inVC:(UIViewController *)vc;

- (void) openURL:(NSString *)url
       currentVC:(UIViewController *)vc;
- (void) twitter:(NSString *)username
       currentVC:(UIViewController *)vc;
- (void) snapchat:(NSString *)username
        currentVC:(UIViewController *)vc;
- (void) instagram:(NSString *)username
        currentVC:(UIViewController *)vc;
- (void) mail:(NSString *)dest
    currentVC:(UIViewController <MFMailComposeViewControllerDelegate> *)vc;
- (void) tel:(NSString *)num
    currentVC:(UIViewController *)vc;

+ (UIImage *) linksToolbarBDEIcon;

@end
