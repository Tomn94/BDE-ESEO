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
    NSString *html = [NSString stringWithFormat:@"<html><head><meta name='viewport' content='initial-scale=1.0' /><style>body { font-family: -apple-system, 'Helvetica Neue', sans-serif; margin: 0; padding: 0; color: #757575; text-align: left; } a { color: #FFA200; }  img { max-width: 98%%; } .header { background: url('%@'); background-size: cover; background-position: center center; height: 142px; width: 100%%; position: relative; } .titre { color: white; font-size: 20px; text-shadow: 0px 0px 5px black; position: absolute; bottom: -11px; padding: 0px 8px; } .content { padding: 0; margin: 0; padding-top: 8px; width: 100%%; }</style></head><body><div class='header'><p class='titre'>%@<br/><span style='font-size: 12px;'>%@</span></p></div><div class='content'><div style='padding: 0 10px 10px 10px; overflow: scroll;'>%@</div></div></body></html>",
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

#pragma mark - Web View UI Delegate
/* Commit 3D-Touch Pop gesture in-app instead of opening Safari */

- (BOOL)     webView:(WKWebView *)webView
shouldPreviewElement:(WKPreviewElementInfo *)elementInfo
{
    return YES;
}

- (UIViewController *)     webView:(WKWebView *)webView
previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo
                    defaultActions:(NSArray<id<WKPreviewActionItem>> *)previewActions
{
    if (![SFSafariViewController class])
    {
        return nil;  // iOS 8 - Peek = default view controller, Pop = back to Safari
    }
    
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:elementInfo.linkURL
                                                         entersReaderIfAvailable:NO];
    if ([SFSafariViewController instancesRespondToSelector:@selector(preferredBarTintColor)])
    {
        safari.preferredBarTintColor = [UINavigationBar appearance].barTintColor;
        safari.preferredControlTintColor = [UINavigationBar appearance].tintColor;
    }
    return safari;
}

- (void)               webView:(WKWebView *)webView
commitPreviewingViewController:(UIViewController *)previewingViewController
{
    [self presentViewController:previewingViewController
                       animated:YES completion:nil];
}

@end
