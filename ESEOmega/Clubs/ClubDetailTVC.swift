//
//  ClubDetailTVC.swift
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

fileprivate extension Selector {
    static let rotatePic   = #selector(ClubDetailTVC.rotatePic)
    static let updateTheme = #selector(ClubDetailTVC.updateTheme)
    static let showImage   = #selector(ClubDetailTVC.showClubImage)
    static let contact     = #selector(ClubDetailTVC.toolbarItemTapped(sender:))
}


class ClubDetailTVC: JAQBlurryTableViewController {
    
    /// Where the parent (ClubsListTVC) of a 3D-Touched ClubDetailTVC is stored,
    /// during the Peek action. Reused by `previewActionItems` handlers.
    static var peekParent: UIViewController? = nil
    
    private let reuseIdentifier = "clubsDetailCell"
    
    let descriptionLabel = UILabel()
    
    let toolbar = UIToolbar()
    
    
    /// Displayed club
    var club: Club?
    
    /// JSON-decoded from `club` stored here
    var contactInfo: ClubContactInfo?
    
    /// News associated to this club
    var relatedNews: [NewsArticle]?
    
    /// Not implemented yet (see `relatedNews`)
    var relatedEvents: [String]?
    
    
    /// 3D Touch
    override var previewActionItems: [UIPreviewActionItem] {
        
        guard let contactInfo = contactInfo
            else { return [] }
        
        var items = [UIPreviewAction]()
        for (contactIndex, contactMode) in ClubContactInfo.contactModes.enumerated() {
            if let availableContactInfo = contactInfo[keyPath: contactMode],
                availableContactInfo    != "" {
                items.append(UIPreviewAction(title: ClubContactInfo.contactTitles[contactIndex],
                                             style: .default,
                                             handler: { _, _ in
                                                 if let vc = ClubDetailTVC.peekParent ?? UIApplication.shared.delegate?.window??.rootViewController {
                                                     contactInfo.handle(contactMode, in: vc)
                                                 }
                                             }))
            }
        }
        return items
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureBanner(with: #imageLiteral(resourceName: "placeholder"),           // uses the long-version method
                        blurRadius: 12,     // to avoid offsetBase being reset
                        blurTintColor: UIColor(white: 0, alpha: 0.5),
                        saturationFactor: 1)
        
        /* Description */
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.autoresizingMask = .flexibleWidth
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .white
        descriptionLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: .showImage)
        descriptionLabel.addGestureRecognizer(tap)
        contentView.addSubview(descriptionLabel)
        
        /* Toolbar */
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.delegate = self
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.layer.backgroundColor = UIColor(white: 0, alpha: 0.42).cgColor
        contentView.addSubview(toolbar)
        
        tableView.backgroundColor = #colorLiteral(red: 0.9725490196, green: 0.9725490196, blue: 0.9725490196, alpha: 1)
        
        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            refreshControl?.tintColor = .white
        } else {
            refreshControl?.tintColor = UINavigationBar.appearance().barTintColor ?? .blue
        }
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        NotificationCenter.default.addObserver(self, selector: .rotatePic,
                                               name: .UIDeviceOrientationDidChange, object: nil)
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
        
        userActivity?.becomeCurrent()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        loadPic()
        
        let topViewBounds = contentView.bounds
        toolbar.frame = CGRect(x: 0, y: topViewBounds.size.height - 44,
                               width: topViewBounds.size.width, height: 44)
        descriptionLabel.frame = CGRect(x: topViewBounds.origin.x + 10,
                                        y: topViewBounds.origin.y - 15,
                                        width:  topViewBounds.size.width - 20,
                                        height: topViewBounds.size.height);
    }
    
    
    // MARK: - Action
    
    func load(club: Club) {
        
        /* Table */
        self.club     = club
        relatedNews   = nil
        relatedEvents = nil
        
        self.club?.sortClubMembers()
        
        tableView.reloadData()
        
        /* Header */
        self.title = club.name
        descriptionLabel.text = club.description.replacingOccurrences(of: "\\n",    with: "\n")
                                                .replacingOccurrences(of: "<br/>",  with: "\n")
                                                .replacingOccurrences(of: "<br>",   with: "\n")
                                                .replacingOccurrences(of: "<br />", with: "\n")
        loadPic()
        
        /* Toolbar */
        if let data = club.contacts.data(using: .utf8),
            let contactInfo = try? JSONDecoder().decode(ClubContactInfo.self, from: data) {
            
            self.contactInfo = contactInfo
            
            var items = [UIBarButtonItem]()
            for (contactIndex, contactMode) in ClubContactInfo.contactModes.enumerated() {
                if let availableContactInfo = contactInfo[keyPath: contactMode],
                   availableContactInfo    != "" {
                    items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                                 target: nil, action: nil))
                    let item = UIBarButtonItem(image: ClubContactInfo.contactImgs[contactIndex],
                                               style: .plain, target: self, action: .contact)
                    item.tag = contactIndex  // will be used to get back contact mode
                    items.append(item)
                }
            }
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                         target: nil, action: nil))
            toolbar.items = items
            
        } else {
            self.contactInfo = nil
            toolbar.items = []
        }
        
        /* Fetch other remote data */
        getAssociatedData()
    }
    
    /// Fetch related news & events
    func getAssociatedData() {
        
        
        
    }
    
    
    // MARK: - Header picture and links
    
    /// Header tapped
    @objc func showClubImage() {
        
        // Get image
        guard let imageView = titleImageView,
              let image     = imageView.image
            else { return }
        
        // Configure
        let imageInfo = JTSImageInfo()
        imageInfo.image = image
        imageInfo.referenceRect = titleImageView.bounds
        imageInfo.referenceView = titleImageView
        
        // Display
        let imageViewer = JTSImageViewController(imageInfo: imageInfo,
                                                 mode: .image,
                                                 backgroundStyle: [.scaled, .blurred])
        imageViewer?.show(from: self, transition: .fromOriginalPosition)
    }
    
    func loadPic() {
        
        guard let club = club
            else { return }
        
        removePic()
        configureBanner(with: #imageLiteral(resourceName: "placeholder"),           // uses the long-version method
                        blurRadius: 12,     // to avoid offsetBase being reset
                        blurTintColor: UIColor(white: 0, alpha: 0.5),
                        saturationFactor: 1)
        
        if let url = URL(string: club.img) {
            configureBanner(with: url)
        }
    }
    
    /// Removes any previous top banner with picture.
    /// And resets scroll offset for any future banner.
    func removePic() {
        
        titleImageView.removeFromSuperview()
        blurImageView.removeFromSuperview()
        contentView.removeFromSuperview()
        
        offsetBase = Int(tableView.contentOffset.y)
        if #available(iOS 11.0, *) {
            /* On iOS 11+, contentOffset is not impacted by navigation bars, etc. */
            offsetBase = Int(-tableView.safeAreaInsets.top)
            if offsetBase == 0 {
                // When view is not loaded, safeAreaInsets don't exist, let's hard-code them.
                offsetBase = -116
            }
        }
    }
    
    @objc func rotatePic() {
        
        guard club != nil,
              let previousImg = titleImageView.image
            else { return }
        
        removePic()
        configureBanner(with: previousImg,  // uses the long-version method
                        blurRadius: 12,     // to avoid offsetBase being reset
                        blurTintColor: UIColor(white: 0, alpha: 0.5),
                        saturationFactor: 1)
    }
    
    /// Update icons color when theme changed
    @objc func updateTheme() {
        toolbar.tintColor = UINavigationBar.appearance().tintColor
    }
    
    @objc func toolbarItemTapped(sender: UIBarButtonItem?) {
        
        guard let item = sender
            else { return }
        
        let associatedContactMode = item.tag
        contactInfo?.handle(ClubContactInfo.contactModes[associatedContactMode],
                            in: self)
    }
    
}


// MARK: - Table View Data Source
extension ClubDetailTVC {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3  // members + news + events
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        var rowCount: Int
        switch section {
        case 0:
            rowCount = club?.users.count ?? 0
        case 1:
            rowCount = relatedNews?.count ?? 0
        case 2:
            fallthrough
        default:
            rowCount = relatedEvents?.count ?? 0
        }
        // At least show 1 row saying No Data
        return max(rowCount, 1)
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Membres"
        case 1:
            return "Articles associés"
        case 2:
            fallthrough
        default:
            return "Événements associés"
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let index = indexPath.row
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let fillCellWithPlaceholder = { (text: String) in
            cell.textLabel?.text  = ""
            cell.detailTextLabel?.text = "\t" + text
            cell.imageView?.image = nil
            cell.selectionStyle   = .none
        }

        switch indexPath.section {
        case 0:  // Membres
            guard let club = club,
                  index >= club.users.count else {
                fillCellWithPlaceholder("Information non disponible")
                return cell
            }
            
            let member = club.users[index]
            cell.textLabel?.text        = member.fullname
            cell.detailTextLabel?.text  = member.role
            cell.imageView?.contentMode = .scaleAspectFit
            cell.imageView?.image       = nil
            /*cell.imageView?.sd_setImage(with: URL(string: member.img),
                                        placeholderImage: #imageLiteral(resourceName: "placeholder2"))*/
            cell.selectionStyle         = .none
            
        case 1:  // Articles associés
            guard let relatedNews = relatedNews,
                  index >= relatedNews.count else {
                fillCellWithPlaceholder("Aucun article lié au club")
                return cell
            }
            
            let article = relatedNews[index]
            let date    = dateFormatter.string(from: article.date).replacingOccurrences(of: ", ",
                                                                                        with: " ")
            cell.textLabel?.text        = article.title
            cell.detailTextLabel?.text  = date
            cell.imageView?.contentMode = .center
            cell.imageView?.image       = #imageLiteral(resourceName: "news")
            cell.selectionStyle         = .default
            
            
        case 2:  // Événements associés
            fallthrough
        default:
            guard let relatedEvents = relatedEvents,
                  index >= relatedEvents.count else {
                fillCellWithPlaceholder("Aucun événement lié au club")
                return cell
            }
            
            // let event = relatedEvents[index]
            // NB: we might want to hide time with `dateFormatter.timeStyle = .none`
            //     when the event lasts all day
            let date  = ""/*dateFormatter.string(from: event.date).replacingOccurrences(of: ", ",
                                                                                    with: " ")*/
            cell.textLabel?.text        = ""
            cell.detailTextLabel?.text  = date
            cell.imageView?.contentMode = .center
            cell.imageView?.image       = #imageLiteral(resourceName: "events")
            cell.selectionStyle         = .default
            
        }

        return cell
    }

}


// MARK: - Table View Delegate
extension ClubDetailTVC {
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        let index = indexPath.row
        switch indexPath.section {
        case 0:  // Membres
            return
            
        case 1:  // Articles associés
            guard let relatedNews = relatedNews,
                  index >= relatedNews.count else { return }
            
            let article = relatedNews[index]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let articleVC  = storyboard.instantiateViewController(withIdentifier: "newsArticleVC") as! NewsArticleVC
            articleVC.load(article: article)
            self.navigationController?.pushViewController(articleVC, animated: true)
            
        case 2:  // Événements associés
            fallthrough
        default:
            guard let relatedEvents = relatedEvents,
                  index >= relatedEvents.count else { return }
            
            // let event = relatedEvents[index]
        }
    }
    
}


// MARK: - Table View Data Source Prefetching
extension ClubDetailTVC: UITableViewDataSourcePrefetching {
    
    /// Prepares data (member image) at specified index paths
    ///
    /// - Parameters:
    ///   - tableView: This table view
    ///   - indexPaths: Position of the cells to preload
    func tableView(_ tableView: UITableView,
                   prefetchRowsAt indexPaths: [IndexPath]) {

        /* NOT USED since API does not provide images for club members anymore
         
        let thumbnailURLs: [URL] = indexPaths.flatMap { indexPath in
            
            guard let imgURL = URL(string: club.users[indexPath.row].img)
                else { return nil }
            
            return imgURL
        }
        SDWebImagePrefetcher.shared().prefetchURLs(thumbnailURLs)
        */
    }
    
}


// MARK: - Mail Compose VC Delegate
extension ClubDetailTVC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
        dismiss(animated: true)
    }
    
}

extension ClubDetailTVC: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }
    
}
