//
//  ClubsListTVC.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 02/06/2018.
//  Copyright © 2018 Thomas Naudet

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

class ClubsListTVC: UITableViewController {
    
    private let reuseIdentifier = "clubsMasterCell"
    
    var clubs = [Club]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Load local data and ask for updates */
        loadFromCache()
        fetchRemote()
        
        self.tableView.backgroundColor = .groupTableViewBackground
        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        var refreshColor: UIColor = .white
        if #available(iOS 11.0, *) {
        } else {
            refreshColor = UINavigationBar.appearance().barTintColor ?? .blue
        }
        refreshControl?.tintColor = refreshColor
        
        /* Handoff */
        let info = ActivityType.clubs
        let activity = NSUserActivity(activityType: info.type)
        activity.title = info.title
        activity.webpageURL = info.url
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true
        activity.isEligibleForPublicIndexing = true
        if #available(iOS 12, *) {
            activity.isEligibleForPrediction = true
            activity.suggestedInvocationPhrase = "Affiche les clubs de l'ESEO"
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(info.type)
        }
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
    
    func selectCurrentClub() {
        
        guard let split = splitViewController,
              !split.isCollapsed,
              let detailNVC   = split.viewControllers.last as? UINavigationController,
              let detail      = detailNVC.viewControllers.first as? ClubDetailTVC,
              let currentClub = detail.club,
              let row         = clubs.index(of: currentClub)
            else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            self.tableView.selectRow(at: IndexPath(row: row, section: 0),
                                     animated: true, scrollPosition: .none)
        }
    }
    
    @IBAction func refresh() {
        
        fetchRemote()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard segue.identifier == "clubSelectionSegue",
              let detailNVC = segue.destination as? UINavigationController,
              let detail    = detailNVC.viewControllers.first as? ClubDetailTVC,
              let selection = tableView.indexPathForSelectedRow
            else { return }
        
        detail.load(club: clubs[selection.row])
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String,
                                     sender: Any?) -> Bool {
        
        if identifier == "clubSelectionSegue" {
            
            guard let detailNVC = splitViewController?.viewControllers.last as? UINavigationController,
                  let detail    = detailNVC.viewControllers.first as? ClubDetailTVC,
                  let currentID = detail.club?.ID,
                  let selection = tableView.indexPathForSelectedRow
                else { return true }
            
            // Don't allow reselect, because screen flashes
            return currentID != clubs[selection.row].ID
        }
        return true
    }
    
}


// MARK: - API Viewer
extension ClubsListTVC: APIViewer {
    
    typealias T = [Club]
    
    
    func loadFromCache() {
        
        guard let data   = APIArchiver.getCache(for: .clubsCache),
              let result = try? JSONDecoder().decode([Club].self, from: data) else {
                reloadData()
                return
        }
        
        self.loadData(result)
    }
    
    func fetchRemote() {
        
        API.request(.clubs, get: ["maxInPage" : String(1000), "display" : String(1)],
                    completed: { data in
            
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
            
            guard let result = try? JSONDecoder().decode(ClubsResult.self, from: data),
                  result.success
                else { return }
            
            self.loadData(result.clubs)
            APIArchiver.save(data: result.clubs, for: .clubsCache)
            
        }, failure: { _, _ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    func loadData(_ data: [Club]) {
        
        let atLaunch = clubs.isEmpty
        // Sort by name
        clubs = data.sorted {
            if $0.isBDE {
                if !$1.isBDE {
                    // All BDE are on top of the list
                    return true
                }
                if !$0.isNotParisNorDijon && !$1.isNotParisNorDijon {
                    // Show Paris on top of Dijon
                    return $0.isFromParis
                }
                // Show Angers on top of Paris
                return $0.isNotParisNorDijon
            }
            // Otherwise alphabetically
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        
        DispatchQueue.main.async {
            
            if atLaunch,
               !(self.splitViewController?.isCollapsed ?? true),
               let firstClub = self.clubs.first {
                
                let storyboard  = UIStoryboard(name: "Main", bundle: nil)
                let destination = storyboard.instantiateViewController(withIdentifier: "clubsDetailTVC") as! ClubDetailTVC
                
                destination.load(club: firstClub)
                let navVC = UINavigationController(rootViewController: destination)
                self.splitViewController?.showDetailViewController(navVC, sender: nil)
                
                self.selectCurrentClub()
            }
            
        }
        
        self.reloadData()
    }
    
    func reloadData() {
        
        DispatchQueue.main.async {
            if self.clubs.isEmpty {
                self.tableView.tableFooterView = UITableViewHeaderFooterView()
            } else {
                self.tableView.tableFooterView = nil
            }
            self.tableView.reloadData()
            self.selectCurrentClub()
        }
    }
    
}


// MARK: - Table View Controller Data Source
extension ClubsListTVC {

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return clubs.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                 for: indexPath) as! ClubsMasterCell

        cell.titreLabel?.layer.shadowRadius   = 4
        cell.titreLabel?.layer.shadowColor    = UIColor.black.cgColor
        cell.titreLabel?.layer.shadowOffset   = CGSize(width: 0, height: 0)
        cell.titreLabel?.layer.shadowOpacity  = 1
        cell.detailLabel?.layer.shadowRadius  = 3
        cell.detailLabel?.layer.shadowColor   = UIColor.black.cgColor;
        cell.detailLabel?.layer.shadowOffset  = CGSize(width: 0, height: 0)
        cell.detailLabel?.layer.shadowOpacity = 1;
        
        let club = clubs[indexPath.row];
        cell.titreLabel?.text  = club.name
        cell.detailLabel?.text = club.subtitle
        
        if let url = URL(string: club.img) {
            cell.imgView?.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "placeholder"))
        } else {
            cell.imgView?.image = #imageLiteral(resourceName: "placeholder")
        }
        
        // Parallax effect
        cell.cell(on: tableView, didScrollOn: view.superview ?? view)

        return cell
    }

}


// MARK: - Table View Data Source Prefetching
extension ClubsListTVC: UITableViewDataSourcePrefetching {
    
    /// Prepares data (club image) at specified index paths
    ///
    /// - Parameters:
    ///   - tableView: This table view
    ///   - indexPaths: Position of the cells to preload
    func tableView(_ tableView: UITableView,
                   prefetchRowsAt indexPaths: [IndexPath]) {
        
        let thumbnailURLs: [URL] = indexPaths.flatMap { indexPath in
            
            guard let imgURL = URL(string: clubs[indexPath.row].img)
                else { return nil }
            
            return imgURL
        }
        SDWebImagePrefetcher.shared().prefetchURLs(thumbnailURLs)
    }
    
}


// MARK: - Scroll View Delegate
extension ClubsListTVC {
    
    /// Update parallax effect
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard !ProcessInfo.processInfo.isLowPowerModeEnabled,
              let visibleCells = tableView.visibleCells as? [ClubsMasterCell]
            else { return }
        
        for cell in visibleCells {
            cell.cell(on: tableView, didScrollOn: view.superview ?? view)
        }
    }
    
}


// MARK: - VC Previewing Delegate
extension ClubsListTVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location)
            else { return nil }
        
        let storyboard  = UIStoryboard(name: "Main", bundle: nil)
        let destination = storyboard.instantiateViewController(withIdentifier: "clubsDetailTVC") as! ClubDetailTVC
        
        destination.load(club: clubs[indexPath.row])
        
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
        splitViewController?.showDetailViewController(viewControllerToCommit, sender: nil)
    }
    
}


// MARK: - Mail Compose VC Delegate (required for 3D Touch action on ClubDetailTVC)
extension ClubsListTVC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
        dismiss(animated: true)
    }
    
}


// MARK: - Empty Data Set Data Source
extension ClubsListTVC: DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "clubsVide")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return NSAttributedString(string: "Aucun club",
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
