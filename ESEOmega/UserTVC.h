//
//  UserTVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 25/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "JAQBlurryTableViewController.h"
#import "UIScrollView+EmptyDataSet.h"

#define NBR_MAX_TENTATIVESCONSEC 5
#define IMG_SIZE (([UIScreen mainScreen].bounds.size.height < 500) ? 120. : 170.)


@interface ImagePickerController : UIImagePickerController
@end


@interface UserTVC : JAQBlurryTableViewController <UITextFieldDelegate, UIWebViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate>
{
//    int mode;
    NSInteger attempt;
    NSTimeInterval lastTry;
//    BOOL okok;
//    NSUserDefaults *defaults;
    CGFloat decalOrientDebut;
}

@property (assign, atomic) NSInteger nbrIFrameLoad;
@property (weak, nonatomic) IBOutlet UITableViewCell *connexionCell;
@property (weak, nonatomic) IBOutlet UITextField *idField;
@property (weak, nonatomic) IBOutlet UITextField *mdpField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spin;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *spinBtn;
@property (strong, nonatomic) UIBarButtonItem *decoBtn;

- (void) chargerUI;
- (IBAction) fermer:(id)sender;
- (void) connexion;
- (void) deconnexion:(id)sender;
- (void) reloadEmpty;
- (void) choosePhoto;
- (void) removePhoto;
- (void) showPhotos;
- (void) retirerTel;

@end
