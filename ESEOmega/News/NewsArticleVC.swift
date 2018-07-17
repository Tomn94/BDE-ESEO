//
//  NewsArticleVC.swift
//  ESEOmega
//
//  Created by Tomn on 10/09/2017.
//  Copyright © 2017 Tomn. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

fileprivate extension Selector {
    static let shareArticle = #selector(NewsArticleVC.shareArticle)
}


class NewsArticleVC: UIViewController {
    
    private static let wrapper = "<html><head><meta name='viewport' content='initial-scale=1.0' /><style>body { font-family: -apple-system, 'Helvetica Neue', sans-serif; margin: 0; padding: 0; color: #757575; text-align: left; } a { color: #FFA200; }  img { max-width: 98%%; } .header { background: url('%@'); background-size: cover; background-position: center center; height: 142px; width: 100%%; position: relative; } .titre { color: white; font-size: 20px; text-shadow: 0px 0px 5px black; position: absolute; bottom: -11px; padding: 0px 8px; } .content { padding: 0; margin: 0; padding-top: 8px; width: 100%%; }</style></head><body><div class='header'><p class='titre'>%@<br/><span style='font-size: 12px;'>%@</span></p></div><div class='content'><div style='padding: 0 10px 10px 10px; overflow: scroll;'>%@</div></div></body></html>"
    
    private let handoffArticleKey = "article"
    
    let webView: WKWebView = {
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        return WKWebView(frame: .zero, configuration: config)
    }()
    
    var article: NewsArticle?
    
    @IBOutlet weak var userButton: UIBarButtonItem!
    
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        guard article?.getURL() != nil else { return [] }
        
        return [UIPreviewAction(title: "Partager…",
                               style: .default) { _, _ in
            self.shareArticle()
        }]
    }
        

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.frame = view.frame
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        view = webView
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        
        if let encodedData = try? JSONEncoder().encode(article) {
            activity.addUserInfoEntries(from: [handoffArticleKey : encodedData])
        }
        super.updateUserActivityState(activity)
    }
    
    
    // MARK: - Action
    
    func load(article: NewsArticle) {
        
        if self.article != nil &&
           self.article!.ID == article.ID {
            return
        }
        self.article = article
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        var date = dateFormatter.string(from: article.date)
        
        if view.bounds.width < 350 {
            date = date.replacingOccurrences(of: "/20", with: "/")
        }
        title = date.replacingOccurrences(of: ", ", with: " ")
        
        let html = String(format: NewsArticleVC.wrapper,
                          article.img ?? "",
                          article.title,
                          article.clubName,
                          article.content)
        webView.loadHTMLString(html, baseURL: nil)
        
        /* Handoff */
        let activity = NSUserActivity(activityType: ActivityType.article.type)
        activity.title = article.title
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true
        activity.isEligibleForPublicIndexing = true
        self.userActivity = activity
        
        if let url = article.getURL() {
            
            activity.webpageURL = url
            
            let shareItem = UIBarButtonItem(barButtonSystemItem: .action, target: self,
                                            action: .shareArticle)
            navigationItem.rightBarButtonItems = [userButton, shareItem]
        }
        
        self.userActivity?.becomeCurrent()
    }
    
    /// Handoff
    @objc func continueReading(userInfo: [String : Any]) {
        
        guard let data = userInfo[handoffArticleKey] as? Foundation.Data,
              let article = try? JSONDecoder().decode(NewsArticle.self,
                                                      from: data)
            else { return }
        
        load(article: article)
    }
    
    /// Called from Bar Button Item or 3D Touch action
    @objc func shareArticle() {
        
        guard let url = article?.getURL(),
              let shareItem = navigationItem.rightBarButtonItems?.last
            else { return }
            
        let safari = TUSafariActivity()
        let shareMenu = UIActivityViewController(activityItems: [url],
                                                 applicationActivities: [safari])
        shareMenu.popoverPresentationController?.barButtonItem = shareItem
        
        UIApplication.shared.windows.first?.rootViewController?.present(shareMenu, animated: true)
    }

}


// MARK: - Web View Navigation Delegate
extension NewsArticleVC: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        
        guard (error as NSError).code != -999 else { return }
        
        let alert = UIAlertController(title: "Erreur",
                                      message: "Impossible de charger l'article",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard navigationAction.navigationType == .linkActivated else {
            decisionHandler(.allow)
            return
        }
            
        Data.shared().openURL(navigationAction.request.url?.absoluteString,
                              currentVC: self)
        decisionHandler(.cancel)
    }
    
}


// MARK: - Web View UI Delegate
@available(iOS 10.0, *)
extension NewsArticleVC: WKUIDelegate {
    
    func webView(_ webView: WKWebView,
                 shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        
        return true
    }
    
    func webView(_ webView: WKWebView,
                 previewingViewControllerForElement elementInfo: WKPreviewElementInfo,
                 defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        
        guard let previewURL = elementInfo.linkURL
            else { return nil }
        
        let safari = SFSafariViewController(url: previewURL)
        
        safari.preferredBarTintColor     = UINavigationBar.appearance().barTintColor
        safari.preferredControlTintColor = UINavigationBar.appearance().tintColor
        
        return safari
    }
    
    func webView(_ webView: WKWebView,
                 commitPreviewingViewController previewingViewController: UIViewController) {
        
        present(previewingViewController, animated: true)
    }
    
}
