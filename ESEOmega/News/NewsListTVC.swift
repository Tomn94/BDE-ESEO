//
//  NewsListVC.swift
//  ESEOmega
//
//  Created by Tomn on 10/09/2017.
//  Copyright © 2017 Thomas Naudet

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

import UIKit

fileprivate extension Selector {
    static let updateTheme = #selector(LinksToolbar.updateTheme)
}


class NewsListTVC: UITableViewController {
    
    /// List of HTML entities not encoded by server
    private static let poop = ["&nbsp;", "&iexcl;", "&cent;", "&pound;", "&curren;", "&yen;", "&brvbar;",
                               "&sect;", "&uml;", "&copy;", "&ordf;", "&laquo;", "&not;", "&shy;", "&reg;",
                               "&macr;", "&deg;", "&plusmn;", "&sup2;", "&sup3;", "&acute;", "&micro;",
                               "&para;", "&middot;", "&cedil;", "&sup1;", "&ordm;", "&raquo;", "&frac14;",
                               "&frac12;", "&frac34;", "&iquest;", "&Agrave;", "&Aacute;", "&Acirc;",
                               "&Atilde;", "&Auml;", "&Aring;", "&AElig;", "&Ccedil;", "&Egrave;",
                               "&Eacute;", "&Ecirc;", "&Euml;", "&Igrave;", "&Iacute;", "&Icirc;", "&Iuml;",
                               "&ETH;", "&Ntilde;", "&Ograve;", "&Oacute;", "&Ocirc;", "&Otilde;", "&Ouml;",
                               "&times;", "&Oslash;", "&Ugrave;", "&Uacute;", "&Ucirc;", "&Uuml;", "&Yacute;",
                               "&THORN;", "&szlig;", "&agrave;", "&aacute;", "&acirc;", "&atilde;", "&auml;",
                               "&aring;", "&aelig;", "&ccedil;", "&egrave;", "&eacute;", "&ecirc;", "&euml;",
                               "&igrave;", "&iacute;", "&icirc;", "&iuml;", "&eth;", "&ntilde;", "&ograve;",
                               "&oacute;", "&ocirc;", "&otilde;", "&ouml;", "&divide;", "&oslash;", "&ugrave;",
                               "&uacute;", "&ucirc;", "&uuml;", "&yacute;", "&thorn;", "&yuml;"]

    private let reuseIdentifier     = "newsMasterCell"
    private let moreReuseIdentifier = "newsMasterMoreCell"
    
    var news = [NewsArticle]()
    
    var currentPage = 1
    
    var newsPerPage: Int {
        return max(15,
                   Int(tableView.bounds.size.height / tableView.rowHeight))
    }
    
    private var isLoadingMoreNews = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: -0.5, left: 0, bottom: 0, right: 0)
        let toolbar = LinksToolbar()
        toolbar.viewController = self
        tableView.tableHeaderView = toolbar
        
        /* Load local data and ask for updates */
        loadFromCache()
        fetchRemote()
        
        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        /* Refresh control */
        reloadRefreshControl()
        NotificationCenter.default.addObserver(self, selector: .updateTheme,
                                               name: .themeChanged, object: nil)
        
        /* Handoff */
        let info = ActivityType.news
        let activity = NSUserActivity(activityType: info.type)
        activity.title = info.title
        activity.webpageURL = info.url
        activity.isEligibleForSearch = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        self.userActivity = activity
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        if splitViewController?.isCollapsed ?? true,
           let selection = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selection, animated: true)
        }
        
        userActivity?.becomeCurrent()
    }
    
    
    // MARK: - Actions
    
    func selectCurrentArticle() {
        
        guard let split = splitViewController,
              !split.isCollapsed,
              let detailNVC = split.viewControllers.last as? UINavigationController,
              let detail    = detailNVC.viewControllers.first as? NewsArticleVC,
              let currentArticle = detail.article,
              let row       = news.index(of: currentArticle)
            else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            self.tableView.selectRow(at: IndexPath(row: row, section: 0),
                                     animated: true, scrollPosition: .none)
        }
    }
    
    @IBAction func refresh() {
        
        fetchRemote()
    }
    
    func loadMoreArticles() {
        
        guard !isLoadingMoreNews else { return }
        isLoadingMoreNews = true
        if !news.isEmpty {
            tableView.reloadRows(at: [IndexPath(row: news.count, section: 0)],
                                 with: .automatic)
        }
        
        API.request(.news, get: ["page" :      String(currentPage + 1),
                                 "maxInPage" : String(newsPerPage)],
                    completed: { data in
                        
            self.isLoadingMoreNews = false
            DispatchQueue.main.async {
                if !self.news.isEmpty {
                    self.tableView.reloadRows(at: [IndexPath(row: self.news.count, section: 0)],
                                              with: .automatic)
                }
            }
        
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = NewsArticle.dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            guard let result = try? decoder.decode(NewsResult.self, from: data),
                  result.success
                else { return }
            
            self.loadData(result.news)
            self.currentPage += 1
                        
            if #available(iOS 10.0, *) {
                DispatchQueue.main.async {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
            
        }, failure: { _, _ in
            self.isLoadingMoreNews = false
            DispatchQueue.main.async {
                if !self.news.isEmpty {
                    self.tableView.reloadRows(at: [IndexPath(row: self.news.count,
                                                             section: 0)],
                                              with: .automatic)
                }
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard segue.identifier == "newsSelectionSegue",
              let detailNVC = segue.destination as? UINavigationController,
              let detail    = detailNVC.viewControllers.first as? NewsArticleVC,
              let selection = tableView.indexPathForSelectedRow
            else { return }
        
        detail.load(article: news[selection.row])
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String,
                                     sender: Any?) -> Bool {
        
        if identifier == "newsSelectionSegue" {
            
            guard let detailNVC = splitViewController?.viewControllers.last as? UINavigationController,
                  let detail    = detailNVC.viewControllers.first as? NewsArticleVC,
                  let currentID = detail.article?.ID,
                  let selection = tableView.indexPathForSelectedRow
                else { return true }
            
            // Don't allow reselect, because screen flashes
            return currentID != news[selection.row].ID
        }
        return true
    }
    
    func reloadRefreshControl() {
        
        let refreshText = "Charger les articles récents…"
        var refreshColor: UIColor = .white
        
        if #available(iOS 11.0, *) {
        } else {
            refreshColor = UINavigationBar.appearance().barTintColor ?? .blue
        }
        
        refreshControl?.tintColor = refreshColor
        refreshControl?.attributedTitle = NSAttributedString(string: refreshText,
                                                             attributes: [.foregroundColor : refreshColor])
    }
    
    @objc func updateTheme() {
        
        reloadRefreshControl()
        if !news.isEmpty {
            tableView.reloadRows(at: [IndexPath(row: news.count, section: 0)],
                                 with: .automatic)
        }
    }
    
}


// MARK: - API Viewer
extension NewsListTVC: APIViewer {
    
    typealias T = [NewsArticle]
    
    
    func loadFromCache() {
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = NewsArticle.dateFormat
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        guard let data   = APIArchiver.getCache(for: .news),
              let result = try? decoder.decode([NewsArticle].self, from: data) else {
                reloadData()
                return
        }
        
        self.loadData(result)
    }
    
    func fetchRemote() {
        
        API.request(.news, get: ["maxInPage" : String(newsPerPage)],
                    completed: { data in
            
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
            
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = NewsArticle.dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            guard let result = try? decoder.decode(NewsResult.self, from: data),
                  result.success
                else { return }
            
            self.loadData(result.news)
            APIArchiver.save(data: result.news, for: .news)
            
        }, failure: { _, _ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    func loadData(_ data: [NewsArticle]) {
        
        let atLaunch = news.isEmpty
        /* Add new articles.
           Replace the same old articles with fresh content.
           Sort by date. */
        news = (news.filter { oldArticle in
                   !data.contains(oldArticle)
               } + data).sorted { $0.date > $1.date }.filter { $0.displayInApps }
        
        DispatchQueue.main.async {
            
            if atLaunch,
               !(self.splitViewController?.isCollapsed ?? true),
               let firstNews = self.news.first {
                
                let storyboard  = UIStoryboard(name: "Main", bundle: nil)
                let destination = storyboard.instantiateViewController(withIdentifier: "newsArticleVC") as! NewsArticleVC
                
                destination.load(article: firstNews)
                let navVC = UINavigationController(rootViewController: destination)
                self.splitViewController?.showDetailViewController(navVC, sender: nil)
                
                self.selectCurrentArticle()
            }
            
        }
            
        self.reloadData()
    }
    
    func reloadData() {
        
        DispatchQueue.main.async {
            if self.news.isEmpty {
                self.tableView.backgroundColor = .groupTableViewBackground
                self.tableView.tableFooterView = UITableViewHeaderFooterView()
            } else {
                self.tableView.backgroundColor = .white
                self.tableView.tableFooterView = nil
            }
            self.tableView.reloadData()
            self.selectCurrentArticle()
        }
    }
    
}


// MARK: - Table View Controller Data Source
extension NewsListTVC {
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        return news.isEmpty ? 0 : (news.count + 1)
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard indexPath.row != news.count else {
            
            var cell = tableView.dequeueReusableCell(withIdentifier: moreReuseIdentifier) as? NewsListMoreCell
            if cell == nil {
                cell = UITableViewCell(style: .default,
                                       reuseIdentifier: moreReuseIdentifier) as? NewsListMoreCell
            }
            cell?.label.textColor = UINavigationBar.appearance().barTintColor
            if isLoadingMoreNews {
                cell?.refresh.startAnimating()
            } else {
                cell?.refresh.stopAnimating()
            }
            
            return cell!
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                 for: indexPath)
        let article = news[indexPath.row]
        
        /* Let's fix server-side encoding issues */
        let title   = article.title.trimmingCharacters(in: .whitespaces)
        let preview = article.preview.trimmingCharacters(in: .whitespaces)
        
        // Remove double spaces
        let titleComps = title.components(separatedBy: .whitespacesAndNewlines)
        cell.textLabel?.text = titleComps.filter { !$0.isEmpty }.joined(separator: " ")
        
        // Replace HTML entities
        var cleanPreview = preview.replacingOccurrences(of: "&amp;", with: "&")
        cleanPreview = cleanPreview.replacingOccurrences(of: "&lsquo;", with: "‘")
        cleanPreview = cleanPreview.replacingOccurrences(of: "&rsquo;", with: "’")
        for (poopIndex, poopChar) in NewsListTVC.poop.enumerated() {
            cleanPreview = cleanPreview.replacingOccurrences(of: poopChar,
                              with: String(format: "%C", 160 + poopIndex))
        }
        let previewComps = cleanPreview.components(separatedBy: .whitespacesAndNewlines)
        cleanPreview = previewComps.filter { !$0.isEmpty }.joined(separator: " ")
        cell.detailTextLabel?.text = cleanPreview
        
        cell.imageView?.contentMode = .scaleAspectFill
        if let imgString = article.img,
            let imgURL = URL(string: imgString) {
            
            cell.imageView?.sd_setImage(with: imgURL,
                                        placeholderImage: #imageLiteral(resourceName: "placeholder"),
                                        completed: { image, Error, _, _ in
                cell.imageView?.image = Data.scaleAndCropImage(image,
                                                               to: CGSize(width: 90, height: 44),
                                                               retina: true)
            })
        } else {
            cell.imageView?.image = #imageLiteral(resourceName: "placeholder")
        }
        
        return cell
    }
    
}


// MARK: - Table View Data Source Prefetching
extension NewsListTVC: UITableViewDataSourcePrefetching {
    
    /// Prepares data (news image) at specified index paths
    ///
    /// - Parameters:
    ///   - tableView: This table view
    ///   - indexPaths: Position of the cells to preload
    func tableView(_ tableView: UITableView,
                   prefetchRowsAt indexPaths: [IndexPath]) {
        
        let thumbnailURLs: [URL] = indexPaths.flatMap { indexPath in
            
            guard indexPath.row != news.count,
                  let articleImg = news[indexPath.row].img
                else { return nil }
            
            return URL(string: articleImg)
        }
        SDWebImagePrefetcher.shared().prefetchURLs(thumbnailURLs)
    }
    
}


// MARK: - Table View Controller Delegate
extension NewsListTVC {
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == news.count {
            
            loadMoreArticles()
            tableView.deselectRow(at: indexPath, animated: true)
            selectCurrentArticle()
        }
    }
    
}


// MARK: - VC Previewing Delegate
extension NewsListTVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location),
              indexPath.row != news.count
            else { return nil }
        
        let storyboard  = UIStoryboard(name: "Main", bundle: nil)
        let destination = storyboard.instantiateViewController(withIdentifier: "newsArticleVC") as! NewsArticleVC
        
        destination.load(article: news[indexPath.row])
        
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
        splitViewController?.showDetailViewController(viewControllerToCommit, sender: nil)
    }
    
}


// MARK: - Mail Compose VC Delegate
extension NewsListTVC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
        dismiss(animated: true)
    }
    
}


// MARK: - Empty Data Set Data Source
extension NewsListTVC: DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "newsVide")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return NSAttributedString(string: "Aucune news",
                                  attributes: [.foregroundColor : UIColor.darkGray])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let text = "Vérifiez votre connexion et tirez pour rafraîchir."
        
        return NSAttributedString(string: text,
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline),
                                               .foregroundColor : UIColor.lightGray])
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        
        return .groupTableViewBackground
    }
    
}


// MARK: - Bottom Refresh Cell
class NewsListMoreCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var refresh: UIActivityIndicatorView!
    
}
