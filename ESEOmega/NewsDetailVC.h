//
//  NewsDetailContentVC.h
//  ESEOmega
//
//  Created by Thomas Naudet on 23/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "TUSafariActivity.h"
#import "NewsSelectionDelegate.h"

@interface NewsDetailVC : UIViewController <NewsSelectionDelegate, UIWebViewDelegate>
{
    NSInteger previousID;
}

@property (strong, nonatomic) NSDictionary *infos;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *userButton;

- (void) loadArticle;
- (void) share;

@end
