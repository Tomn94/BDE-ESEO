//
//  Data.h
//  ESEOmega
//
//  Created by Thomas NAUDET on 02/08/2015.
//  Copyright © 2015 Thomas NAUDET. All rights reserved.
//

@import Foundation;
@import UIKit;
@import MessageUI;
@import SafariServices;
@import Security;
#import "EGOCache.h"
#import <CommonCrypto/CommonHMAC.h>
#import "JNKeychain.h"

#define NEW_UPD_TI @"Une nouvelle version de l'app est disponible"
#define NEW_UPD_TE @"Merci de mettre l'application à jour pour commander"
#define NEW_UPD_BT @"Mettre à jour"

#define URL_BDE      @"http://eseomega.fr"
#define URL_BDE_TTLE @"ESEOmega.fr"
#define MAIL_BDE     @"bde@eseomega.fr"
#define USR_INSTA    @"eseomega"
#define USR_SNAP     @"eseomega"
#define USR_TWITTER  @"bde_ESEOmega"
#define URL_FACEBOOK @"https://www.facebook.com/bde.eseo"
#define URL_YOUTUBE  @"https://youtube.com/channel/UCWBwVkzCcGifFu2otLpVK-g"
#define URL_APPSTORE @"https://itunes.apple.com/app/apple-store/id966385182?pt=104224803&ct=updCafet&mt=8"
#define URL_PORTAIL  @"https://portail.eseo.fr"
#define URL_CAMPUS   @"http://campus.eseo.fr"
#define URL_MAIL     @"http://mail.office365.com"
#define URL_ESEO     @"http://www.eseo.fr"
#define URL_PROJETS  @"http://www.projets.eseo.fr"

#define URL_JSONS    @"http://79.170.44.147/eseonews.fr/jsondata/%@_data/%@.json?%d"
#define URL_NEWS     @"http://79.170.44.147/eseonews.fr/getData.php?height=%d&ptr=%d&uzless=%d"
#define URL_CMDS     @"http://217.199.187.59/francoisle.fr/lacommande/api/order/list.php?%d"
#define URL_1CMD     @"http://217.199.187.59/francoisle.fr/lacommande/api/order/resume.php"
#define URL_CMD_NEW  @"http://217.199.187.59/francoisle.fr/lacommande/api/order/prepare.php"
#define URL_CMD_DATA @"http://217.199.187.59/francoisle.fr/lacommande/api/order/items.php"
#define URL_CMD_SEND @"http://217.199.187.59/francoisle.fr/lacommande/api/order/send.php"
#define URL_CMD_LY_1 @"http://217.199.187.59/francoisle.fr/lacommande/api/lydia/ask.php"
#define URL_CMD_LY_2 @"http://217.199.187.59/francoisle.fr/lacommande/api/lydia/check.php"
#define URL_SERVICE  @"http://217.199.187.59/francoisle.fr/lacommande/api/info/service.php?%d"
#define URI_CAFET    @"http://217.199.187.59/francoisle.fr/lacommande/assets/"
#define URL_EVENT_CM @"http://217.199.187.59/francoisle.fr/lacommande/api/event/list.php?%d"
#define URL_EVENT_NE @"http://217.199.187.59/francoisle.fr/lacommande/api/event/prepare.php"
#define URL_EVENT_DT @"http://217.199.187.59/francoisle.fr/lacommande/api/event/items.php"
#define URL_EVENT_SD @"http://217.199.187.59/francoisle.fr/lacommande/api/event/send.php"
#define URL_EVENT_ML @"http://217.199.187.59/francoisle.fr/lacommande/api/event/mail.php"
#define URL_INGENEWS @"http://79.170.44.147/eseonews.fr/jsondata/ingenews_data/ingenews.php?%d"
#define URL_CONNECT  @"http://217.199.187.59/francoisle.fr/lacommande/api/client/connect.php"
#define URL_PUSH     @"http://217.199.187.59/francoisle.fr/lacommande/api/push/register.php"
#define URL_UNPUSH   @"http://217.199.187.59/francoisle.fr/lacommande/api/push/unregister.php"
#define URL_GP       @"http://217.199.187.59/francoisle.fr/lacommande/api/gantier/scores.php"

#define URL_ACTIVITY @"http://eseomega.fr"
#define URL_ACT_NEWS @"http://eseomega.fr/news"
#define URL_ACT_EVNT @"http://eseomega.fr/events"
#define URL_ACT_CLUB @"http://eseomega.fr/clubs"
#define URL_ACT_SPON @"http://eseomega.fr/partenaires"

#define MAX_ORDER_TIME 582

@interface Data : NSObject <SFSafariViewControllerDelegate, UITextFieldDelegate>

+ (Data *) sharedData;

@property (strong, nonatomic) NSDictionary *news;
@property (strong, nonatomic) NSDictionary *events;
@property (strong, nonatomic) NSDictionary *eventsCmds;
@property (strong, nonatomic) NSDictionary *clubs;
@property (strong, nonatomic) NSDictionary *cmds;
@property (strong, nonatomic) NSDictionary *service;
@property (strong, nonatomic) NSDictionary *menus;
@property (strong, nonatomic) NSDictionary *sponsors;
@property (strong, nonatomic) NSDictionary *salles;
@property (strong, nonatomic) NSDictionary *ingenews;
@property (strong, nonatomic) NSMutableDictionary *lastCheck;
@property (nonatomic) NSTimeInterval launchTime;
@property (strong, nonatomic) NSArray *cafetData;
@property (strong, nonatomic) NSMutableArray *cafetPanier;
@property (strong, nonatomic) NSString *cafetToken;
@property (assign, nonatomic) NSTimeInterval cafetDebut;
@property (assign, nonatomic) BOOL cafetCmdEnCours;
@property (strong, nonatomic) NSDate *tooManyConnect;
@property (strong, nonatomic) NSData *pushToken;
@property (strong, nonatomic) UIViewController<MFMailComposeViewControllerDelegate> *t_currentTopVC;
@property (strong, nonatomic) NSString *tempPhone;
@property (strong, nonatomic) UIAlertController *alertRedir;

+ (NSString *) hashed_string:(NSString *)input;
+ (NSString *) encoderPourURL:(NSString *)url;
+ (BOOL) estConnecte;
+ (void) connecter:(NSString *)user
              pass:(NSString *)mdp
               nom:(NSString *)nom;
+ (void) deconnecter;
+ (void) sendPushToken;
+ (void) delPushToken;
+ (UIImage *) imageByScalingAndCroppingForSize:(UIImage *)sourceImage to:(CGSize)targetSize retina:(BOOL)retina;
+ (UIImage *) imageByScalingAndCroppingForSize:(UIImage *)sourceImage to:(CGSize)targetSize retina:(BOOL)retina fit:(BOOL)fit;

- (BOOL) shouldUpdateJSON:(NSString *)JSONname;
- (void) updateJSON:(NSString *)JSONname;
- (void) updateJSON:(NSString *)JSONname
            options:(NSInteger)options;
- (void) updLoadingActivity:(BOOL)visible;
- (void) traiterNewNews:(NSDictionary *)JSON
                  start:(NSInteger)index;

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

@end
