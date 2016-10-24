//
//  UserTVC.m
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

#import "UserTVC.h"

@implementation UserTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    attempt = ([[Data sharedData] tooManyConnect] != nil) ? -1 : 0;
    lastTry = ([[Data sharedData] tooManyConnect] != nil) ? [[[Data sharedData] tooManyConnect] timeIntervalSinceReferenceDate]
                                                          : [NSDate timeIntervalSinceReferenceDate];
    _idField.delegate = self;
    _mdpField.delegate = self;
    _mdpField.secureTextEntry = YES;
    _connexionCell.textLabel.enabled = NO;
    _connexionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    _decoBtn = [[UIBarButtonItem alloc] initWithTitle:@"Déconnexion"
                                                style:UIBarButtonItemStylePlain
                                               target:self
                                               action:@selector(deconnexion:)];
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    decalOrientDebut = (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) ? -32 : 0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillAppear:)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self chargerUI];
    [self configureBannerWithImage:[UIImage imageNamed:@"batiment"]
                        blurRadius:0
                     blurTintColor:[UIColor clearColor]
                  saturationFactor:1
                         maxHeight:157];
    [self reloadEmpty];
}

#pragma mark Table View Delegate

- (NSInteger) numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    if ([Data estConnecte])
        return 0;
    return 2;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    if ([Data estConnecte])
        return 0;
    else if (section == 1)
        return 1;
    return 2;
}

- (void)      tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1 && indexPath.row == 0)
        [self connexion];
}

#pragma mark Text Field Delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if ([_idField isFirstResponder])
        [_mdpField becomeFirstResponder];
    else
        [self connexion];
    
    return NO;
}

- (BOOL)            textField:(nonnull UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
            replacementString:(nonnull NSString *)string
{
    NSString  *proposedNewString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
    NSString  *result = [proposedNewString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSUInteger length = [result length];
    
    BOOL prev1 = ![ _idField.text isEqualToString:@""];
    BOOL prev2 = ![_mdpField.text isEqualToString:@""];
    BOOL prev  = prev1 && prev2;
    if (textField.tag)
        prev2  = length > 0;
    else
        prev1  = length > 0;
    
    BOOL nouv = prev1 && prev2;
    if (prev != nouv)
    {
        [_connexionCell.textLabel setEnabled:nouv];
        [_connexionCell setSelectionStyle:(nouv) ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone];
    }
    
    if (textField.tag)
        return YES;
    
    return length <= 15;
}
/*
#pragma mark Web View Delegate

- (void) webViewDidStartLoad:(nonnull UIWebView *)webView
{
    if (mode == 1)
        _nbrIFrameLoad++;
}
-(void)heh{

    CGRect frame = [UIScreen mainScreen].bounds;
    frame.size.height /= 2.;
    UIWebView *webView2 = [[UIWebView alloc] initWithFrame:frame];
    webView2.tag = 1;
    [self.view addSubview:webView2];
    [webView2 setDelegate:self];
    
    NSURL *url = [NSURL URLWithString: @"https://portail.eseo.fr/OpDotNet/Noyau/Bandeau.aspx?hideMenu=true"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [webView2 loadRequest:request];

}
- (void) webViewDidFinishLoad:(nonnull UIWebView *)webView
{
//    NSLog(@"%@", source);
    
    if (mode > 1 && webView.tag == 1){
        NSString *source = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('html')[0].outerHTML"];
        NSArray *result = [source componentsSeparatedByString:@"<span id=\"ctl00_BandeauBienvenue1_lblBonjour\">Bonjour&nbsp;"];
        NSLog(@"%@", result);
        if ([result count] > 1)
        {
            result = [result[1] componentsSeparatedByString:@"</span>"];
            if ([result count] > 0)
                source = result[0];
            else
                source = @"Inconnu";
        }
        else
            source = @"Inconnu";
        
        NSLog(@"%@", source);
        
        return;
    }
    else if (mode == 1)
    {
        _nbrIFrameLoad--;
//        if (okok== YES)
//        {
            mode = 2;
        
        
        [self performSelector:@selector(heh) withObject:nil afterDelay:5];
        
        //        NSString *javaScript = @"window.addEventListener(\"load\", function() {    }, false);";
//            [webView stringByEvaluatingJavaScriptFromString:javaScript];
//            NSLog(@"%d", [[webView stringByEvaluatingJavaScriptFromString:@"document.readyState"] isEqualToString:@"complete"]);
        
        
//                NSURL *url = [NSURL URLWithString: @""];https://portail.eseo.fr/OpDotNet/Noyau/Bandeau.aspx?hideMenu=true
//                NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
////                [webView loadRequest:request];
        
//            return;
//        }
        
        return;
    }

    mode = 1;
    
    NSURL *url = [NSURL URLWithString: @"https://portail.eseo.fr/+webvpn+/index.html"];
    NSString *body = [NSString stringWithFormat:@"tgroup=&next=&tgcookieset=&Login=Connexion&username=%@&password=%@&group_list=Student_ssl", [self encoderPourURL:_idField.text], [self encoderPourURL:_mdpField.text]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [webView loadRequest:request];
}

- (void)     webView:(nonnull UIWebView *)webView
didFailLoadWithError:(nullable NSError *)error
{
    if (mode == 1)
        _nbrIFrameLoad--;
    if (error.code == -999)
        return;
    
    BOOL ok = ![ _idField.text isEqualToString:@""] && ![_mdpField.text isEqualToString:@""];
    [_connexionCell.textLabel setEnabled:ok];
    [_connexionCell setSelectionStyle:(ok) ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone];
    [_spin stopAnimating];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur de connexion"
                                                                   message:@"Impossible de répondre à votre requête.\nPatientez puis réessayez, sinon contactez-nous."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action)
                      { [alert dismissViewControllerAnimated:YES completion:nil]; }]];
    [self presentViewController:alert animated:YES completion:nil];
}*/

#pragma mark Actions

- (void) chargerUI
{
    NSArray *ph = @[@"lannistertyr", @"snowjohn", @"starkarya", @"whitewalter", @"pinkmanjesse", @"swansonron", @"nadirabed", @"mccormickkenny", @"foxmulder", @"goodmansaul", @"rothasher", @"archersterling"];
    [_idField setPlaceholder:ph[arc4random_uniform((int)[ph count])]];
    
    UIBarButtonItem *bouton = nil;
    if ([Data estConnecte])
        bouton = _decoBtn;
    else
        bouton = _spinBtn;
    [self.navigationItem setLeftBarButtonItems:@[bouton] animated:YES];
}

- (IBAction) fermer:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) connexion
{
    [_idField  resignFirstResponder];
    [_mdpField resignFirstResponder];
    if ([_idField.text isEqualToString:@""] || [_mdpField.text isEqualToString:@""])
        return;
    
    // Éviter le brute force et la surcharge
    BOOL bug = NO;
    if (attempt == -1 && [NSDate timeIntervalSinceReferenceDate] - lastTry <= 300)
        bug = YES;
    else
    {
        ++attempt;
        [[Data sharedData] setTooManyConnect:nil];
    }
    if (attempt > NBR_MAX_TENTATIVESCONSEC)
    {
        lastTry = [NSDate timeIntervalSinceReferenceDate];
        attempt = -1;
        [[Data sharedData] setTooManyConnect:[NSDate date]];
        bug = YES;
    }
    if (bug || [[Data sharedData] tooManyConnect] != nil)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Doucement"
                                                                       message:@"Veuillez attendre 5 minutes, vous avez réalisé trop de tentatives à la suite."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Mince !" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    [_connexionCell.textLabel setEnabled:NO];
    [_connexionCell setUserInteractionEnabled:NO];
    [_connexionCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    NSString *login = [[_idField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    
    
    /* CONNEXION AU CAMPUS */
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    // "Chiffrement" du mot de passe
    NSString *password           = _mdpField.text;
    NSString *pass1              = [[password dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    NSMutableString *passwordDec = [NSMutableString string];
    for (NSInteger i = 0 ; i < password.length ; i++)
    {
        unichar ch = [password characterAtIndex:i];
        [passwordDec appendFormat:@"%c", (char)(ch + 1)];
    }
    NSString *pass2 = [[passwordDec dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    NSMutableString *passFinal = [NSMutableString string];
    for (NSInteger i = 0 ; i < pass2.length ; i++)
        [passFinal appendFormat:@"%c%c", [pass1 characterAtIndex:i], [pass2 characterAtIndex:i]];
    NSString *finPass = ([passFinal length] > 2) ? [passFinal substringFromIndex:[passFinal length] - 2] : @"";
    if (![finPass isEqualToString:@"=="])
        [passFinal appendString:@"=="];
    
    NSString *lePassFinal = [Data hashed_string:[@"Oups, erreur de connexion" stringByAppendingString:password]];
    
    // Envoi des informations au serveur de commande
    NSString *toHash = [[login stringByAppendingString:passFinal] stringByAppendingString:@"selfRetain_$_0x128D4_objc"];
    NSURL    *url    = [NSURL URLWithString:URL_CONNECT];
    NSString *body   = [NSString stringWithFormat:@"username=%@&password=%@&hash=%@",
                        [Data encoderPourURL:login],
                        [Data encoderPourURL:passFinal],
                        [Data encoderPourURL:[Data hashed_string:toHash]]];
    NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] initWithURL:url];
    [request2 setHTTPMethod:@"POST"];
    [request2 setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request2
                                                       completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          [[Data sharedData] updLoadingActivity:NO];
                                          NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                               options:kNilOptions
                                                                                                 error:nil];
                                          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur inconnue"
                                                                                                         message:@"Impossible de valider votre connexion sur nos serveurs. Si le problème persiste, contactez-nous."
                                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                                          BOOL connecte = [JSON[@"status"] intValue] == 1;
                                          if (connecte)
                                          {
                                              NSString *nom   = [JSON[@"data"][@"username"] componentsSeparatedByString:@" "][0];
                                              NSString *title = [NSString stringWithFormat:@"Bienvenue %@ !", nom];
                                              if ([JSON[@"data"][@"info"] containsString:@"existe"])
                                                  title = [NSString stringWithFormat:@"Vous êtes de retour, %@ !", nom];
                                              
                                              alert = [UIAlertController alertControllerWithTitle:title
                                                                                          message:@"Vous êtes connecté, vous bénéficiez désormais de l'accès à la cafétéria.\nPour être notifié lorsque votre repas est prêt, veuillez accepter les notifications !"
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                              
                                              [Data connecter:login pass:lePassFinal nom:JSON[@"data"][@"username"]];
                                              [[NSNotificationCenter defaultCenter] postNotificationName:@"connecte" object:nil];
                                          }
                                          else if ([JSON[@"status"] intValue] == -2)
                                              alert = [UIAlertController alertControllerWithTitle:@"Oups…"
                                                                                          message:@"Mauvaise combinaison identifiant/mot de passe.\nVeuillez vérifier vos informations, puis réessayer."
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                          
                                          [_spin stopAnimating];
                                          [_connexionCell.textLabel setEnabled:YES];
                                          [_connexionCell setUserInteractionEnabled:YES];
                                          [_connexionCell setSelectionStyle:UITableViewCellSelectionStyleDefault];
                                          
                                          [alert addAction:[UIAlertAction actionWithTitle:(connecte) ? (([[Data sharedData] pushToken] != nil) ? @"Parfait" : @"Parfait, j'y penserai !") : @"OK"
                                                                                    style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                              if (connecte)
                                              {
                                                  [Data registeriOSPush:(AppDelegate *)[[UIApplication sharedApplication] delegate]];
                                                  
                                                  if ([[Data sharedData] pushToken] != nil && [JNKeychain loadValueForKey:@"login"] != nil)
                                                      [Data sendPushToken];
                                                  
                                                  [self fermer:nil];
                                              }
                                          }]];
                                          [self presentViewController:alert animated:YES completion:nil];
                                      }];
    [[Data sharedData] updLoadingActivity:YES];
    [_spin startAnimating];
    [dataTask resume];
}

- (IBAction) deconnexion:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Voulez-vous vraiment vous déconnecter ?"
                                                                   message:@"Vos éventuelles commandes en cours à la cafétéria restent dues."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Oui" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                      {
                          NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                          NSString *documentsDirectory = paths[0];
                          NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"imageProfil.png"];
                          NSData *myData = [[NSData alloc] initWithContentsOfFile:appFile];
                          if (myData != nil)
                              [self removePhoto];
                          
                          [Data deconnecter];
                          
                          [self chargerUI];
                          [self.tableView reloadData];
                          
                          [[NSNotificationCenter defaultCenter] postNotificationName:@"connecte" object:nil];
                      }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) choosePhoto
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"imageProfil.png"];
    NSData *myData = [[NSData alloc] initWithContentsOfFile:appFile];
    if (myData != nil)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Changer l'image de profil"
                                                                       message:@""
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Supprimer la photo"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * action) {
                                                    [self removePhoto];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Choisir une photo"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    [self showPhotos];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Annuler"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
        [self showPhotos];
}

- (void) removePhoto
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"imageProfil.png"];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (!success) {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Impossible de supprimer l'image" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
    }
    
    [self reloadEmpty];
}

- (void) showPhotos
{
    if (iPAD)
    {/*
        ImagePickerController *pop = [ImagePickerController new];
        pop.popoverPresentationController.sourceView = pop.view;
        pop.modalPresentationStyle = UIModalPresentationPopover;
        pop.popoverPresentationController.sourceRect = [self.tableView.emptyDataSetView.imageView convertRect:self.tableView.emptyDataSetView.imageView.bounds toView:[UIApplication sharedApplication].windows[0]];
        pop.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        pop.popoverPresentationController.delegate = self;
        pop.delegate = self;
        [self presentViewController:pop animated:YES completion:nil];*/

        UIImagePickerController *pop = [UIImagePickerController new];
        pop.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        pop.delegate = self;
        UIPopoverController *popOver = [[UIPopoverController alloc] initWithContentViewController:pop];
        [popOver presentPopoverFromRect:[self.tableView.emptyDataSetView.imageView convertRect:self.tableView.emptyDataSetView.imageView.bounds toView:self.navigationController.view]
                                 inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        UIImagePickerController *pop = [UIImagePickerController new];
        pop.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        pop.delegate = self;
        [self presentViewController:pop animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        }];
    }
}

- (void) retirerTel
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Voulez-vous oublier le numéro de téléphone ?"
                                                                   message:@"Votre numéro de téléphone portable est utilisé par Lydia afin de lier vos commandes à votre compte. Il n'est pas stocké sur nos serveurs.\nUn nouveau numéro vous sera demandé au prochain achat cafet/event via Lydia.\n\nCependant lorsque vous vous inscrivez à un événement (sans utiliser Lydia), ce numéro est communiqué au BDE."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Supprimer" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [JNKeychain deleteValueForKey:@"phone"];
                                                [self reloadEmpty];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Pop over delegate

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

#pragma mark Image picker delegate

- (void) imagePickerController:(UIImagePickerController *)picker
 didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"imageProfil.png"];
    image = [Data imageByScalingAndCroppingForSize:image
                                                to:CGSizeMake(IMG_SIZE, IMG_SIZE)
                                            retina:NO];
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:savedImagePath atomically:NO];
    
    [self reloadEmpty];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }];
}

- (void) navigationController:(UINavigationController *)navigationController
       willShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

#pragma mark - DZNEmptyDataSet

- (void) reloadEmpty
{
    [self.tableView reloadEmptyDataSet];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(choosePhoto)];
    [self.tableView.emptyDataSetView.imageView setUserInteractionEnabled:YES];
    [self.tableView.emptyDataSetView.imageView addGestureRecognizer:tap];
    
    self.tableView.emptyDataSetView.imageView.layer.cornerRadius = IMG_SIZE / 2.;
    self.tableView.emptyDataSetView.imageView.clipsToBounds = YES;
    self.tableView.emptyDataSetView.imageView.layer.borderWidth = 4;
    self.tableView.emptyDataSetView.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retirerTel)];
    [self.tableView.emptyDataSetView.detailLabel setUserInteractionEnabled:YES];
    [self.tableView.emptyDataSetView.detailLabel addGestureRecognizer:tap2];
}

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    if (!iPAD && (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]) || [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height))
        return nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"imageProfil.png"];
    NSData *myData = [[NSData alloc] initWithContentsOfFile:appFile];
    if (myData != nil)
        return [UIImage imageWithData:myData];
    
    if ([UIScreen mainScreen].bounds.size.height < 500)
        return [Data imageByScalingAndCroppingForSize:[UIImage imageNamed:@"defaultUser"]
                                                   to:CGSizeMake(IMG_SIZE, IMG_SIZE)
                                               retina:NO];
    return [UIImage imageNamed:@"defaultUser"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = [NSString stringWithFormat:@"Bonjour\n%@", [JNKeychain loadValueForKey:@"uname"]];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Vous avez accès à toutes les fonctionnalités, dont la commande à la cafétéria/événements et les notifications.";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                  NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                  NSParagraphStyleAttributeName: paragraph,
                                  NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone) };
    
    if ([JNKeychain loadValueForKey:@"phone"])
    {
        text = [text stringByAppendingString:[NSString stringWithFormat:@"\n\nTéléphone associé aux commandes Lydia :\n%@ ",
                                              [JNKeychain loadValueForKey:@"phone"]]];

        NSMutableAttributedString *mas = [NSMutableAttributedString new];
        [mas appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:attributes]];
        [mas appendAttributedString:[[NSAttributedString alloc] initWithString:@"Supprimer"
                                                                    attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:12.0],
                                                                                  NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                                                  NSBackgroundColorAttributeName: [UIColor clearColor] }]];
        return [[NSAttributedString alloc] initWithAttributedString:mas];
    }
    else
        text = [text stringByAppendingString:@"\n\nAucun téléphone associé aux commandes Lydia."];
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGPoint) offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    if ([UIScreen mainScreen].bounds.size.height <= 320 && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
        return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2. + 180 + decalOrientDebut);
    return CGPointMake(0, -self.tableView.tableHeaderView.frame.size.height / 2. + 150 + decalOrientDebut);
}

@end


@implementation ImagePickerController

- (instancetype) init
{
    if (self = [super init])
    {
        self.popoverPresentationController.sourceView = self.view;
    }
    return self;
}
@end





/* CONNEXION AU CAMPUS */
/*NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
 NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
 delegate:nil
 delegateQueue:[NSOperationQueue mainQueue]];
 NSURL *url = [NSURL URLWithString:@"https://campus.eseo.fr/login/index.php"];
 NSString *body = [NSString stringWithFormat:@"username=%@&password=%@",
 [Data encoderPourURL:login], [Data encoderPourURL:_mdpField.text]];
 NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
 [request setHTTPMethod:@"POST"];
 [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
 
 // Requête de connexion
 NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request
 completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
 {
 [[Data sharedData] updLoadingActivity:NO];
 [_spin stopAnimating];
 UIAlertController *alert = nil;
 BOOL erreur = NO;
 
 if (error == nil) // Si requête acceptée
 {
 NSString *nom = nil, *sesskey = nil;
 NSString *source = [[NSString alloc] initWithData:data
 encoding:NSUTF8StringEncoding];
 
 // Récupération des infos et donc vérification si on est connecté
 NSArray *part0 = [source componentsSeparatedByString:@"Consulter le profil\">"];
 if ([part0 count] < 2)
 erreur = YES;
 else
 {
 NSArray *part1 = [part0[1] componentsSeparatedByString:@"</a>"];
 if ([part1 count] < 3)
 erreur = YES;
 else
 {
 nom = part1[0];
 NSArray *part2 = [part1[1] componentsSeparatedByString:@"sesskey="];
 if ([part2 count] < 2)
 erreur = YES;
 else
 sesskey = [part2[1] stringByReplacingOccurrencesOfString:@"\">Déconnexion" withString:@""];
 }
 }
 if (erreur)
 alert = [UIAlertController alertControllerWithTitle:@"Identifiant ou mot de passe incorrect"
 message:@"Impossible de vous identifier sur le serveur. Si le problème persiste, contactez-nous."
 preferredStyle:UIAlertControllerStyleAlert];
 else
 {
 [[Data sharedData] updLoadingActivity:YES];
 [_spin startAnimating];
 
 // Envoie des informations au serveur de commande
 NSURL *url2 = [NSURL URLWithString:@"http://217.199.187.59/francoisle.fr/lacommande/apps/finaliserConnex.php"];
 NSString *body = [NSString stringWithFormat:@"username=%@&fullname=%@&hash=%@",
 [Data encoderPourURL:login], [Data encoderPourURL:nom], [Data hashed_string:[[@"ri3nN3Vo1b0NePurée" stringByAppendingString:login] stringByAppendingString:nom]]];
 Envoyer [[Data sharedData] pushToken]
 NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] initWithURL:url2];
 [request2 setHTTPMethod:@"POST"];
 [request2 setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
 NSURLSessionDataTask *dataTask2 = [defaultSession dataTaskWithRequest:request2 completionHandler:^(NSData *data2, NSURLResponse *r, NSError *error2)
 {
 UIAlertController *alert2 = nil;
 NSString *source2 = [[NSString alloc] initWithData:data2
 encoding:NSUTF8StringEncoding];
 
 BOOL erreur2 = error2 != nil || ![source2 isEqualToString:@"42"];
 if (erreur2)
 alert2 = [UIAlertController alertControllerWithTitle:@"Impossible de s'identifier sur le serveur"
 message:@"Impossible de vous enregistrer sur le serveur de commande. Si le problème persiste, contactez-nous."
 preferredStyle:UIAlertControllerStyleAlert];
 else
 {
 alert2 = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Bonjour %@ !", [nom componentsSeparatedByString:@" "][0]]
 message:@"Vous êtes connecté, vous bénéficiez désormais de toutes les fonctionnalités."
 preferredStyle:UIAlertControllerStyleAlert];
 
 [defaults setValue:login forKey:@"userId"];
 [defaults setValue:nom   forKey:@"userName"];
 [defaults synchronize];
 
 // Requête de déconnexion pour une éventuelle reconnexion future
 NSURLSessionDataTask *dataTaskDeco = [defaultSession dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://campus.eseo.fr/login/logout.php?sesskey=%@", sesskey]] completionHandler:^(NSData *data2, NSURLResponse *r2, NSError *error2)
 {
 [[Data sharedData] updLoadingActivity:NO];
 }];
 [dataTaskDeco resume];
 
 [[NSNotificationCenter defaultCenter] postNotificationName:@"connecte" object:nil];
 }
 
 [_spin stopAnimating];
 [alert2 addAction:[UIAlertAction actionWithTitle:(!erreur2) ? @"Parfait !" : @"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
 if (!erreur2)
 [self fermer:nil];
 }]];
 [self presentViewController:alert2 animated:YES completion:nil];
 }];
 [dataTask2 resume];
 }
 }
 else  // Si requête refusée
 {
 erreur = YES;
 alert = [UIAlertController alertControllerWithTitle:@"Erreur de connexion"
 message:@"Impossible se connecter au serveur.\nPatientez puis réessayez, sinon contactez-nous."
 preferredStyle:UIAlertControllerStyleAlert];
 }
 
 if (alert != nil)
 {
 [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
 [self presentViewController:alert animated:YES completion:nil];
 }
 
 [_connexionCell.textLabel setEnabled:YES];
 [_connexionCell setUserInteractionEnabled:YES];
 [_connexionCell setSelectionStyle:UITableViewCellSelectionStyleDefault];
 }];
 [dataTask resume];
 [[Data sharedData] updLoadingActivity:YES];
 [_spin startAnimating];*/

/*
 mode = 0;
 
 UIWebView *webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
 [self setView:webView];
 [webView setDelegate:self];
 
 NSURL *url = [NSURL URLWithString: @"https://portail.eseo.fr/"];
 NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
 [webView loadRequest:request];*/
