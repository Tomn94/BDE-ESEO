//
//  SponsorsTVCTableViewController.swift
//  BDE-ESEO
//
//  Created by Benjamin Gondange on 10/09/2018.
//  Copyright © 2018 Benjamin Gondange

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
import SafariServices

class SponsorsTVC: UITableViewController {
    private let reuseIdentifier     = "sponsorsCell"
    
    var sponsors = [Sponsor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadFromCache()
        fetchRemote()
        
        if #available(iOS 10.0, *) {
            self.tableView.prefetchDataSource = self;
        }
        
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 131;
        self.refreshControl?.tintColor = UINavigationBar.appearance().tintColor
        
        /* Refresh control */
        reloadRefreshControl()
        
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapability.available) {
            self.registerForPreviewing(with: self, sourceView: self.tableView)
        }
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        self.refreshControl?.endRefreshing()
        
        let activity = NSUserActivity(activityType: "com.eseomega.ESEOmega.sponsors")
        activity.title = "Liste des partenaires"
        activity.webpageURL = URL(string: URL_ACT_SPON)
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true
        activity.isEligibleForPublicIndexing = true
        self.userActivity = activity
        self.userActivity?.becomeCurrent()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reloadRefreshControl() {
        
        let refreshText = "Charger les sponsors récents…"
        var refreshColor: UIColor = .white
        
        if #available(iOS 11.0, *) {
        } else {
            refreshColor = UINavigationBar.appearance().barTintColor ?? .blue
        }
        
        refreshControl?.tintColor = refreshColor
        refreshControl?.attributedTitle = NSAttributedString(string: refreshText,
                                                             attributes: [.foregroundColor : refreshColor])
    }
    @IBAction func refresh(_ sender: Any) {
        self.fetchRemote()
    }
    
}

extension SponsorsTVC: APIViewer {
    typealias T = [Sponsor]
    
    func loadFromCache() {
        let decoder = JSONDecoder()
        guard let data   = APIArchiver.getCache(for: .sponsors),
            let result = try? decoder.decode([Sponsor].self, from: data) else {
                reloadData()
                return
        }
        
        self.loadData(result)
    }
    
    func fetchRemote() {
        
        API.request(.sponsors, get: [:],
                    completed: { data in
                        
                        DispatchQueue.main.async {
                            self.refreshControl?.endRefreshing()
                        }
                        
                        let decoder = JSONDecoder()
                        
                        guard let result = try? decoder.decode(SponsorsResult.self, from: data),
                            result.success
                            else { return }
                        self.loadData(result.sponsors)
                        APIArchiver.save(data: result.sponsors, for: .sponsors)
                        
        }, failure: { _, _ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    func loadData(_ data: [Sponsor]) {
        
        let atLaunch = sponsors.isEmpty
        /* Add new articles.
         Replace the same old articles with fresh content. */
        if atLaunch {
            sponsors = data
        }
        
        self.reloadData()
    }
    func reloadData() {
        
        DispatchQueue.main.async {
            if self.sponsors.isEmpty {
                self.tableView.backgroundColor = .groupTableViewBackground
                self.tableView.tableFooterView = UITableViewHeaderFooterView()
            } else {
                self.tableView.backgroundColor = .white
                self.tableView.tableFooterView = nil
            }
            self.tableView.reloadData()
        }
    }
   
}

extension SponsorsTVC {
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        return sponsors.isEmpty ? 0 : (sponsors.count + 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row != sponsors.count else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! SponsorsCell
        
        let sponsor = sponsors[indexPath.row]
        
        cell.nomLabel?.text = sponsor.name
        cell.descLabel?.text = sponsor.description
        
        var contact = ""
        if (sponsor.url != nil && sponsor.url != "") {
            guard var url = sponsor.url else { return UITableViewCell() }
            NSLog(url)
            url = url.trimmingCharacters(in: CharacterSet.whitespaces)
            if (url.hasSuffix("/")) {
                let index = url.index(url.startIndex, offsetBy: url.count - 1)
                url = String(url.prefix(upTo: index))
            }
            contact = url.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "www.", with: "").replacingOccurrences(of: "http://", with: "")
            
        }
        
        if (contact != "" && sponsor.address != nil && sponsor.address != "") {
            contact = contact + "\n"
        }
        
        guard let add = sponsor.address else { return UITableViewCell() }
        contact = contact + add
        
        cell.contactLabel?.text = contact
        
        if let image = sponsor.image {
            cell.logoView?.sd_setImage(with: URL(string: image), placeholderImage: UIImage(named: "placeholder"))
        } else {
            cell.logoView?.image = UIImage(named: "placeholder")
        }
        cell.logoView?.layer.cornerRadius = 4
        cell.logoView?.clipsToBounds = true
        
        cell.setAvantages(avt: sponsor.perks)
        
        return cell
    }
}

// MARK: - Table View Data Source Prefetching
extension SponsorsTVC: UITableViewDataSourcePrefetching {
    
    /// Prepares data (news image) at specified index paths
    ///
    /// - Parameters:
    ///   - tableView: This table view
    ///   - indexPaths: Position of the cells to preload
    func tableView(_ tableView: UITableView,
                   prefetchRowsAt indexPaths: [IndexPath]) {
        
        let thumbnailURLs: [URL] = indexPaths.compactMap { indexPath in
            
            guard indexPath.row != sponsors.count,
                let articleImg = sponsors[indexPath.row].image
                else { return nil }
            
            return URL(string: articleImg)
        }
        SDWebImagePrefetcher.shared().prefetchURLs(thumbnailURLs)
    }
    
}
// MARK: - Table view controller Delegate
extension SponsorsTVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = URL(string: sponsors[indexPath.row].url ?? "") else {
            self.tableView.deselectRow(at: indexPath, animated: true)
            return
            
        }

        let svc = SFSafariViewController(url: url)
        self.present(svc, animated: true, completion: nil)
        
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SponsorsTVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // TODO: - Preview delegate
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
    }
    
}

// MARK: - Empty Data Set Data Source
extension SponsorsTVC: DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "newsVide")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return NSAttributedString(string: "Aucun sponsor",
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


