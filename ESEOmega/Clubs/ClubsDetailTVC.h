//
//  ClubsDetailNVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
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
@import MessageUI;
#import "Data.h"
#import "JTSImageInfo.h"
#import "JTSImageViewController.h"
#import "ClubsSelectionDelegate.h"
#import "JAQBlurryTableViewController.h"
#import "../SDWebImage/UIImageView+WebCache.h"
#import "../SDWebImage/SDWebImageDownloader.h"

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
