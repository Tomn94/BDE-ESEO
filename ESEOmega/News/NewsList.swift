//
//  NewsList.swift
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

protocol NewsSelectionDelegate {
    
    func present(article: NewsArticle)
    
}


class NewsList: UITableViewController {
    
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
    
    weak var delegate: (UIViewController & NewsSelectionDelegate)?
    
    private var isLoadingMoreNews = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = true
        tableView.contentInset = UIEdgeInsets(top: -0.5, left: 0, bottom: 0, right: 0)
        let toolbar = LinksToolbar()
        toolbar.viewController = self
        tableView.tableHeaderView = toolbar
        
        /* Load local data and ask for updates */
        loadFromCache()
        fetchRemote()
        
        /* Delegates */
        if let detailNVC = splitViewController?.viewControllers.last as? UINavigationController,
           let detailVC = detailNVC.viewControllers.first as? UIViewController & NewsSelectionDelegate {
            delegate = detailVC
        }
        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
        
        /* Refresh control */
        let refreshText = "Charger les articles récents…"
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            refreshControl?.tintColor = .white
            refreshControl?.attributedTitle = NSAttributedString(string: refreshText,
                                                                 attributes: [.foregroundColor : UIColor.white])
        } else {
            let refreshColor = UINavigationBar.appearance().barTintColor ?? .blue
            refreshControl?.tintColor = refreshColor
            refreshControl?.attributedTitle = NSAttributedString(string: refreshText,
                                                                 attributes: [.foregroundColor : refreshColor])
        }
        
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
        
        self.userActivity?.becomeCurrent()
    }
    
    
    // MARK: - Actions
    
    @IBAction func refresh() {
        
        fetchRemote()
    }
    
    func loadMoreArticles() {
        
        isLoadingMoreNews = true
        
        var generator: AnyObject? = nil
        if #available(iOS 10.0, *) {
            generator = UIImpactFeedbackGenerator(style: .light)
            (generator as! UIImpactFeedbackGenerator).prepare()
        }
        
        API.request(.news, get: ["page" :      String(currentPage + 1),
                                 "maxInPage" : String(newsPerPage)],
                    completed: { data in
                        
            self.isLoadingMoreNews = false
            self.tableView.reloadRows(at: [IndexPath(row: self.news.count, section: 0)],
                                 with: .automatic)
        
            guard let result = try? JSONDecoder().decode(NewsResult.self, from: data),
                result.success
                else { return }
            
            self.loadData(result.news)
                        
            if #available(iOS 10.0, *),
               let generator = generator as? UIImpactFeedbackGenerator {
                generator.impactOccurred()
            }
            
        }, failure: { _, _ in
            self.isLoadingMoreNews = false
            self.tableView.reloadRows(at: [IndexPath(row: self.news.count,
                                                     section: 0)],
                                 with: .automatic)
        })
    }
    
}


// MARK: - API Viewer
extension NewsList: APIViewer {
    
    typealias T = [NewsArticle]
    
    
    func loadFromCache() {
        
        guard let data   = APIArchiver.getCache(for: .news),
              let result = try? JSONDecoder().decode(NewsResult.self, from: data) else {
                reloadData()
                return
        }
        
        self.loadData(result.news)
    }
    
    func fetchRemote() {
        
        API.request(.news, get: ["maxInPage" : String(newsPerPage)],
                    completed: { data in
            
            self.refreshControl?.endRefreshing()
            
            guard let result = try? JSONDecoder().decode(NewsResult.self, from: data),
                  result.success
                else { return }
            
            self.loadData(result.news)
            APIArchiver.save(data: result.news, for: .news)
            
        }, failure: { _, _ in
            self.refreshControl?.endRefreshing()
        })
    }
    
    func loadData(_ data: [NewsArticle]) {
        
        news += data
        
        // TODO: Uniquement au lancement
        if let firstNews = news.first {
            delegate?.present(article: firstNews)
        }
        
        reloadData()
    }
    
    func reloadData() {
        
        if news.isEmpty {
            tableView.backgroundColor = .groupTableViewBackground
            tableView.tableFooterView = UITableViewHeaderFooterView()
        } else {
            tableView.backgroundColor = .white
            tableView.tableFooterView = nil
        }
        tableView.reloadData()
    }
    
}


// MARK: - Table View Controller Data Source
extension NewsList {
    
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
        let titleComps   =   title.components(separatedBy: .whitespacesAndNewlines)
        let previewComps = preview.components(separatedBy: .whitespacesAndNewlines)
        cell.textLabel?.text = titleComps.filter { !$0.isEmpty }.joined(separator: " ")
        var cleanPreview   = previewComps.filter { !$0.isEmpty }.joined(separator: " ")
        
        // Replace HTML entities
        cleanPreview = cleanPreview.replacingOccurrences(of: "&amp;", with: "&")
        cleanPreview = cleanPreview.replacingOccurrences(of: "&lsquo;", with: "‘")
        cleanPreview = cleanPreview.replacingOccurrences(of: "&rsquo;", with: "’")
        for (poopIndex, poopChar) in NewsList.poop.enumerated() {
            cleanPreview = cleanPreview.replacingOccurrences(of: poopChar,
                              with: String(format: "%C", 160 + poopIndex))
        }
        cell.detailTextLabel?.text = cleanPreview
        
        cell.imageView?.contentMode = .scaleAspectFill
        if let imgURL = article.img {
            
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
extension NewsList: UITableViewDataSourcePrefetching {
    
    /// Prepares data (news image) at specified index paths
    ///
    /// - Parameters:
    ///   - tableView: This table view
    ///   - indexPaths: Position of the cells to preload
    func tableView(_ tableView: UITableView,
                   prefetchRowsAt indexPaths: [IndexPath]) {
        
        let thumbnailURLs: [URL] = indexPaths.flatMap { indexPath in
            
            guard indexPath.row != news.count else { return nil }
            
            return news[indexPath.row].img
        }
        SDWebImagePrefetcher.shared().prefetchURLs(thumbnailURLs)
    }
    
}


// MARK: - Table View Controller Delegate
extension NewsList {
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.row != news.count else {
            
            loadMoreArticles()
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        delegate?.present(article: news[indexPath.row])
    }
    
}


// MARK: - VC Previewing Delegate
extension NewsList: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location),
              indexPath.row != news.count
            else { return nil }
        
        let storyboard  = UIStoryboard(name: "Main", bundle: nil)
        let destination = storyboard.instantiateViewController(withIdentifier: "newsDetailVC") as! (UIViewController & NewsSelectionDelegate)
        
        destination.present(article: news[indexPath.row])
        
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
        splitViewController?.showDetailViewController(viewControllerToCommit, sender: nil)
    }
    
}


// MARK: - Mail Compose VC Delegate
extension NewsList: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
        dismiss(animated: true)
    }
    
}


// MARK: - Empty Data Set Data Source
extension NewsList: DZNEmptyDataSetSource {
    
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
