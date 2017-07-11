//
//  NewsDetailContentVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 23/07/2015.
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

#import "NewsDetailVC.h"

@implementation NewsDetailVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    previousID = -1;
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame
                                      configuration:config];
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    self.webView.allowsBackForwardNavigationGestures = YES;
    if ([SFSafariViewController class])
        self.webView.allowsLinkPreview = YES;
    self.view = self.webView;
    
    self.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
    self.navigationItem.leftItemsSupplementBackButton = YES;
}

- (void) selectedNews:(nonnull NSDictionary *)infos
{
    _infos = infos;
    [self loadArticle];
    [[Data sharedData] setT_currentTopVC:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadArticle];
}

#pragma mark - 3D Touch

- (NSArray<id<UIPreviewActionItem>> *) previewActionItems
{
    /* Add a share action if there's a link */
    NSString *link = _infos[@"link"];
    if (link == nil)    // ESEOasis has no website link in the JSON data, so let's make one
        link = [NSString stringWithFormat:URL_NEWS_LNK, [_infos[@"id"] intValue]];
    NSURL *shareURL = [NSURL URLWithString:link];
    if (shareURL == nil)
        return [NSArray array];
    
    UIPreviewAction *item = [UIPreviewAction actionWithTitle:@"Partager…"
                                                       style:UIPreviewActionStyleDefault
                                                     handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) { [self share]; }];
    return @[item];
}

#pragma mark - Actions

- (void) loadArticle
{
    if (previousID == [_infos[@"id"] integerValue])
        return;
    previousID = [_infos[@"id"] integerValue];
    
    self.navigationItem.rightBarButtonItem = _userButton;
    
    if (_infos[@"fulldate"] == nil)
    {
        //        self.title = @"Aucune news. Vérifiez votre connexion.";
        return;
    }
    
    /* ESEOasis has no website link in the JSON data, so let's make one */
    NSString *link = _infos[@"link"];
    if (link == nil)
        link = [NSString stringWithFormat:URL_NEWS_LNK, [_infos[@"id"] intValue]];
    NSURL *shareURL = [NSURL URLWithString:link];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.S'Z'"];
    NSString *date = [NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:_infos[@"fulldate"]]
                                                    dateStyle:NSDateFormatterShortStyle
                                                    timeStyle:NSDateFormatterShortStyle];
    if ([UIScreen mainScreen].bounds.size.width < 350)
        date = [date stringByReplacingOccurrencesOfString:@"/20" withString:@"/"];
    self.title = date;
                      _infos[@"img"], _infos[@"title"], _infos[@"author"], _infos[@"content"]];
    [_webView loadHTMLString:html baseURL:nil];
    
    // Handoff
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.article"];
    activity.title = _infos[@"title"];
    activity.userInfo = _infos;
    if (shareURL != nil)
        activity.webpageURL = [NSURL URLWithString:_infos[@"link"]];
    if ([SFSafariViewController class])
    {
        activity.eligibleForSearch = YES;
        activity.eligibleForHandoff = YES;
        activity.eligibleForPublicIndexing = YES;
    }
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
    
    /* Share button */
    if (shareURL != nil) {
        UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                   target:self action:@selector(share)];
        NSArray *items = @[_userButton, shareItem];
        self.navigationItem.rightBarButtonItems = items;
    }
}

- (void) share
{
    NSString *link = _infos[@"link"];
    if (link == nil)    // ESEOasis has no website link in the JSON data, so let's make one
        link = [NSString stringWithFormat:URL_NEWS_LNK, [_infos[@"id"] intValue]];
    
    NSURL *url = [NSURL URLWithString:link];
    if (url != nil)
    {
        TUSafariActivity *safari = [[TUSafariActivity alloc] init];
        UIActivityViewController *menuPartage = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                                  applicationActivities:@[safari]];
        if ([menuPartage respondsToSelector:@selector(popoverPresentationController)])
            menuPartage.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems[1];
        if ([[Data sharedData] t_currentTopVC] != nil)
            [[[Data sharedData] t_currentTopVC] presentViewController:menuPartage animated:YES completion:nil];
        else
            [self presentViewController:menuPartage animated:YES completion:nil];
    }
}

#pragma mark - Handoff

- (void) updateUserActivityState:(NSUserActivity *)activity
{
    [activity addUserInfoEntriesFromDictionary:_infos];
    [super updateUserActivityState:activity];
}

#pragma mark - Web View Navigation Delegate

- (void)  webView:(WKWebView *)webView
didFailNavigation:(WKNavigation *)navigation
        withError:(NSError *)error
{
    if (error.code == -999)
        return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur"
                                                                   message:@"Impossible de charger l'article"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)                webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated)
    {
        [[Data sharedData] openURL:navigationAction.request.URL.absoluteString
                         currentVC:self];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

    return YES;
}

@end
