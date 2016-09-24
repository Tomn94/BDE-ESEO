//
//  UserTVC.h
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

@import UIKit;
#import "Data.h"
#import "AppDelegate.h"
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
