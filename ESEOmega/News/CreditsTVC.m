//
//  CreditsTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 29/07/2015.
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

#import "CreditsTVC.h"

@implementation CreditsTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Crédits";
    self.tableView.emptyDataSetSource      = self;
    self.tableView.emptyDataSetDelegate    = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Fermer"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(fermer)];;
    
    UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ron"]];
    [img setFrame:CGRectMake(0, -100, [UIScreen mainScreen].bounds.size.width, 113)];
    [img setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [img setContentMode:UIViewContentModeScaleAspectFit];
    [self.tableView addSubview:img];
    /*
    if (([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height && [UIScreen mainScreen].bounds.size.height > 320) || ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height && [UIScreen mainScreen].bounds.size.width > 320))
    {
        UILabel *label = [UILabel new];
        label.frame = CGRectMake(0, self.view.bounds.size.height - 135, [UIScreen mainScreen].bounds.size.width, 100);
        label.text = @"DZNEmptyDataSet · JAQBlurryTableViewController · EGOCache\n"
                      "icons8.com · dribbble.com · SDWebImage ·  CCBottomRefreshControl";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor lightGrayColor];
        label.font = [UIFont systemFontOfSize:11];
        label.numberOfLines = 0;
        [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
        [self.tableView addSubview:label];
    }*/
}

- (void) fermer
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

#pragma mark - DZNEmptyDataSet

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"credits"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    return [[NSAttributedString alloc] initWithString:@" "];
}

- (NSAttributedString *) descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"© Thomas NAUDET pour ESEOmega\nCollection Été 2015 - Hiver 2016\nHiver 2016 - 2017 pour ESEOasis\nUne question, un problème ? ↓";

    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    CGFloat fontSize = 14.0;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    NSDictionary *boldDic = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize] };
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    [mas setAttributes:boldDic range:NSMakeRange(2, 13)];
    [mas setAttributes:boldDic range:NSMakeRange(95, 29)];
    
    return mas;
}

- (CGPoint) offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return (([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height && [UIScreen mainScreen].bounds.size.height > 320) || ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height && [UIScreen mainScreen].bounds.size.width > 320)) ? CGPointMake(0, -16) : CGPointZero;
}

- (NSAttributedString *) buttonTitleForEmptyDataSet:(UIScrollView *)scrollView
                                           forState:(UIControlState)state
{
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0],
                                 NSForegroundColorAttributeName: [UINavigationBar appearance].barTintColor};
    
    return [[NSAttributedString alloc] initWithString:@"Contacter"
                                           attributes:attributes];
}

- (void) emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    [[Data sharedData] mail:[[@"tom" stringByAppendingString:@"n72@gm"] stringByAppendingString:@"ail.com"]
                  currentVC:self];
}

#pragma mark - Mail Compose View Controller delegate

- (void) mailComposeController:(MFMailComposeViewController*)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
