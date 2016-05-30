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
    
    self.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
    self.navigationItem.leftItemsSupplementBackButton = true;
    
    self.webView.delegate = self;
    self.webView.allowsInlineMediaPlayback = YES;
    if ([SFSafariViewController class])
    {
        self.webView.allowsLinkPreview = YES;
        self.webView.allowsPictureInPictureMediaPlayback = YES;
    }
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
    if (_infos[@"lien"] == nil || [_infos[@"lien"] isEqualToString:@""] || ![NSURL URLWithString:_infos[@"lien"]])
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
    
    if (_infos[@"date"] == nil)
    {
        //        self.title = @"Aucune news. Vérifiez votre connexion.";
        return;
    }
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *date = [NSDateFormatter localizedStringFromDate:[dateFormatter dateFromString:_infos[@"date"]]
                                                    dateStyle:NSDateFormatterShortStyle
                                                    timeStyle:NSDateFormatterShortStyle];
    if ([UIScreen mainScreen].bounds.size.width < 350)
        date = [date stringByReplacingOccurrencesOfString:@"/20" withString:@"/"];
    self.title = date;
    NSString *html = [NSString stringWithFormat:@"<html><head><style>body { -webkit-text-size-adjust: 100%%; font-family: -apple-system, 'Helvetica Neue', sans-serif; margin: 0; padding: 0; color: #757575; text-align: justify; } a { color: #FFA200; }  img { max-width: 98%%; } .header { background: url('%@'); background-size: cover; background-position: center center; height: 142px; width: 100%%; position: relative; } .titre { color: white; font-size: 20px; text-shadow: 0px 0px 5px black; position: absolute; bottom: -11px; padding: 0px 8px; } .content { padding: 0; margin: 0; margin-top: 8px; width: 100%%; }</style></head><body><div class='header'><p class='titre'>%@<br/><span style='font-size: 12px;'>%@</span></p></div><div class='content'><div style='padding: 0 10px 10px 10px; overflow: scroll;'>%@</div></div></body></html>", _infos[@"img"], _infos[@"titre"], _infos[@"auteur"], _infos[@"content"]];
    [_webView loadHTMLString:html baseURL:nil];
    
    // Handoff
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.article"];
    activity.title = _infos[@"titre"];
    activity.userInfo = _infos;
    if (_infos[@"lien"] != nil && ![_infos[@"lien"] isEqualToString:@""] && [NSURL URLWithString:_infos[@"lien"]])
        activity.webpageURL = [NSURL URLWithString:_infos[@"lien"]];
    if ([SFSafariViewController class])
    {
        activity.eligibleForSearch = YES;
        activity.eligibleForHandoff = YES;
        activity.eligibleForPublicIndexing = YES;
    }
    self.userActivity = activity;
    [self.userActivity becomeCurrent];
    
    if (_infos[@"lien"] == nil || [_infos[@"lien"] isEqualToString:@""] || ![NSURL URLWithString:_infos[@"lien"]])
        return;
    
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self action:@selector(share)];
    NSArray *items = @[_userButton, shareItem];
    self.navigationItem.rightBarButtonItems = items;
}

- (void) share
{
    if (_infos[@"lien"] == nil || [_infos[@"lien"] isEqualToString:@""] || ![NSURL URLWithString:_infos[@"lien"]])
        return;
    
    NSURL *url = [NSURL URLWithString:_infos[@"lien"]];
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

#pragma mark - Handoff

- (void) updateUserActivityState:(NSUserActivity *)activity
{
    [activity addUserInfoEntriesFromDictionary:_infos];
    [super updateUserActivityState:activity];
}

#pragma mark - Web View Delegate

- (void)     webView:(nonnull UIWebView *)webView
didFailLoadWithError:(nullable NSError *)error
{
    if (error.code == -999)
        return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur" message:@"Impossible de charger l'article" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)           webView:(nonnull UIWebView *)webView
shouldStartLoadWithRequest:(nonnull NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [[Data sharedData] openURL:request.URL.absoluteString currentVC:self];
        return NO;
    }
    return YES;
}

@end
