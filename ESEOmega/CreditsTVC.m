//
//  CreditsTVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 29/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

#import "CreditsTVC.h"

@implementation CreditsTVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Crédits";
    self.tableView.emptyDataSetSource      = self;
    self.tableView.emptyDataSetDelegate    = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(fermer)];;
    
    UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ron"]];
    [img setFrame:CGRectMake(0, -104.5, [UIScreen mainScreen].bounds.size.width, 113)];
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
    NSString *text = @"Thomas Naudet pour ESEOmega\n© Collection Été 2015 - Hiver 2016";

    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGPoint) offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return (([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height && [UIScreen mainScreen].bounds.size.height > 320) || ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height && [UIScreen mainScreen].bounds.size.width > 320)) ? CGPointMake(0, -16) : CGPointZero;
}

@end
