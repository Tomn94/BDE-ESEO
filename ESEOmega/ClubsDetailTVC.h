//
//  ClubsDetailNVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
@import MessageUI;
#import "Data.h"
#import "JTSImageInfo.h"
#import "JTSImageViewController.h"
#import "ClubsSelectionDelegate.h"
#import "JAQBlurryTableViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "SDWebImage/SDWebImageDownloader.h"

@interface ClubsDetailTVC : JAQBlurryTableViewController <ClubsSelectionDelegate, UIToolbarDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) NSDictionary *infos;

- (void) loadPic;
- (void) loadClub;
- (void) rotatePic;
- (void) tapHeaderClub;
- (void) site;
- (void) facebook;
- (void) twitter;
- (void) youtube;
- (void) snapchat;
- (void) instagram;
- (void) linkedin;
- (void) mail;
- (void) tel;

@end
