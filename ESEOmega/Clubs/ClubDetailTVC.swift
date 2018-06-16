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

// MARK: - ClubContactInfo UI-related extension
extension ClubContactInfo {
    
    /// Call this to open website/social network/… and do the appropriate action
    ///
    /// - Parameters:
    ///   - contactMode: Selected contact mode
    ///   - viewController: View controller on top of which to present a web/mail/… view controller
    func handle(_ contactMode: KeyPath<ClubContactInfo, String?>,
                in viewController: UIViewController) {
        
        switch contactMode {
        case \ClubContactInfo.web:
            Data.shared().openURL(web, currentVC: viewController)
        case \ClubContactInfo.fb:
            Data.shared().openURL(fb, currentVC: viewController)
        case \ClubContactInfo.twitter:
            // Check if URL, otherwise @username
            if let profileURL = twitter,
               URL(string: profileURL) != nil {
                Data.shared().openURL(profileURL, currentVC: viewController)
            } else {
                Data.shared().twitter(twitter, currentVC: viewController)
            }
        case \ClubContactInfo.youtube:
            Data.shared().openURL(youtube, currentVC: viewController)
        case \ClubContactInfo.snap:
            // Check if URL, otherwise username
            if let profileURL = snap,
               URL(string: profileURL) != nil {
                Data.shared().openURL(profileURL, currentVC: viewController)
            } else {
                Data.shared().snapchat(snap, currentVC: viewController)
            }
        case \ClubContactInfo.instagram:
            // Check if URL, otherwise username
            if let profileURL = instagram,
               URL(string: profileURL) != nil {
                Data.shared().openURL(profileURL, currentVC: viewController)
            } else {
                Data.shared().instagram(instagram, currentVC: viewController)
            }
        case \ClubContactInfo.linkedIn:
            Data.shared().openURL(linkedIn, currentVC: viewController)
        case \ClubContactInfo.mail:
            if let vc = viewController as? UIViewController & MFMailComposeViewControllerDelegate {
                Data.shared().mail(mail, currentVC: vc)
            }
        case \ClubContactInfo.tel:
            Data.shared().tel(tel, currentVC: viewController)
        default:
            return
        }
    }
}


// MARK: - View Controller
fileprivate extension Selector {
    static let rotatePic   = #selector(ClubDetailTVC.rotatePic)
    static let updateTheme = #selector(ClubDetailTVC.updateTheme)
    static let showImage   = #selector(ClubDetailTVC.showClubImage)
    static let contact     = #selector(ClubDetailTVC.toolbarItemTapped(sender:))
}


/// Presents detailed info about a club
/// TODO: Replace JAQBlurryTableViewController that uses a subview in a table view, which is deprecated.
///       It would be better to use a table view header instead.
class ClubDetailTVC: JAQBlurryTableViewController {
    
    /// Where the parent (ClubsListTVC) of a 3D-Touched ClubDetailTVC is stored,
    /// during the Peek action. Reused by `previewActionItems` handlers.
    static var peekParent: UIViewController? = nil
    
    /// Maximum number of related news and events fetched
    static var maxRelatedItems = 30
    
    private let reuseIdentifier = "clubsDetailCell"
    
    /// Club details text
    let descriptionLabel = UILabel()
    
    /// Club contact options
    let toolbar = UIToolbar()
    
    
    /// Displayed club
    var club: Club?
    
    /// News associated to this club
    var relatedNews: [NewsArticle]?
    
    /// Not implemented yet (see `relatedNews`)
    var relatedEvents: [String]?
    
    
    /// 3D Touch
    override var previewActionItems: [UIPreviewActionItem] {
        
        var items = [UIPreviewAction]()
        for (contactIndex, contactMode) in ClubContactInfo.contactModes.enumerated() {
            if let availableContactInfo = club?.contacts[keyPath: contactMode],
                availableContactInfo    != "" {
                items.append(UIPreviewAction(title: ClubContactInfo.contactTitles[contactIndex],
                                             style: .default,
                                             handler: { _, _ in
                                                 if let vc = ClubDetailTVC.peekParent ?? UIApplication.shared.delegate?.window??.rootViewController {
                                                     self.club?.contacts.handle(contactMode, in: vc)
                                                 }
                                             }))
            }
        }
        return items
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Description */
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.autoresizingMask = .flexibleWidth
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .white
        descriptionLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: .showImage)
        descriptionLabel.addGestureRecognizer(tap)
        
        /* Toolbar */
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.delegate = self
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.layer.backgroundColor = UIColor(white: 0, alpha: 0.42).cgColor
        
        tableView.backgroundColor = #colorLiteral(red: 0.9725490196, green: 0.9725490196, blue: 0.9725490196, alpha: 1)
        
        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        NotificationCenter.default.addObserver(self, selector: .rotatePic,
                                               name: .UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: .updateTheme,
                                               name: .themeChanged, object: nil)
        
        /* Handoff */
        let info = ActivityType.clubs
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
        
        loadPic()
        
        userActivity?.becomeCurrent()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let topViewBounds = contentView.bounds
        toolbar.frame = CGRect(x: 0, y: topViewBounds.size.height - 44,
                               width: topViewBounds.size.width, height: 44)
        descriptionLabel.frame = CGRect(x: topViewBounds.origin.x + 10,
                                        y: topViewBounds.origin.y - 15,
                                        width:  topViewBounds.size.width - 20,
                                        height: topViewBounds.size.height)
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
        var items = [UIBarButtonItem]()
        for (contactIndex, contactMode) in ClubContactInfo.contactModes.enumerated() {
            if let availableContactInfo = club.contacts[keyPath: contactMode],
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
        
        /* Fetch other remote data */
        getAssociatedData()
    }
    
    /// Fetch related news & events
    func getAssociatedData() {
        
        guard let clubID = club?.ID
            else { return }
        
        API.request(.news, get: ["club"      : clubID,
                                 "maxInPage" : String(ClubDetailTVC.maxRelatedItems)],
                    completed: { data in
                        
                        let decoder = JSONDecoder()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = NewsArticle.dateFormat
                        decoder.dateDecodingStrategy = .formatted(dateFormatter)
                        
                        guard let result = try? decoder.decode(NewsResult.self, from: data),
                              result.success
                            else { return }
                        
                        self.relatedNews = result.news.filter { $0.displayInApps }.sorted { $0.date > $1.date }
                        DispatchQueue.main.async {
                            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
                            self.rotatePic()  // debug untappable header
                        }
                        
        })
        
        // TODO: Do the same for events
    }
    
    
    // MARK: - Header picture and links
    
    /// Header tapped
    @objc func showClubImage() {
        
        // Get image
        guard club?.img != "",
              let imageView = titleImageView,
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
        
        removePic()
        
        if let club = club,
           let url = URL(string: club.img) {
            configureBanner(with: url)
        } else {
            configureBanner(with: #imageLiteral(resourceName: "placeholder"),           // uses the long-version method
                            blurRadius: 12,     // to avoid offsetBase being reset
                            blurTintColor: UIColor(white: 0, alpha: 0.5),
                            saturationFactor: 1)
        }
        
        setHeaderLayout()
    }
    
    /// Removes any previous top banner with picture.
    /// And resets scroll offset for any future banner.
    func removePic() {
        
        guard titleImageView != nil, blurImageView != nil, contentView != nil // already gone
            else { return }
        
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
        setHeaderLayout()
    }
    
    /// Finish layout setup (reset at each configureBanner)
    func setHeaderLayout() {
        
        descriptionLabel.removeFromSuperview()
        toolbar.removeFromSuperview()
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(toolbar)
        
        titleImageView.isUserInteractionEnabled = true
        blurImageView.isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = true
        
        tableView.setNeedsLayout()
    }
    
    /// Update icons color when theme changed
    @objc func updateTheme() {
        toolbar.tintColor = UINavigationBar.appearance().tintColor
    }
    
    @objc func toolbarItemTapped(sender: UIBarButtonItem?) {
        
        guard let item = sender
            else { return }
        
        let associatedContactMode = item.tag
        club?.contacts.handle(ClubContactInfo.contactModes[associatedContactMode],
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
        
        cell.textLabel?.font       = UIFont.preferredFont(forTextStyle: .body)
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .caption2)
        cell.selectionStyle        = .default

        switch indexPath.section {
        case 0:  // Membres
            guard let club = club,
                  index < club.users.count else {
                fillCellWithPlaceholder("Information non disponible")
                return cell
            }
            
            let member = club.users[index]
            cell.textLabel?.text        = member.fullname
            cell.detailTextLabel?.text  = member.role
            cell.imageView?.contentMode = .scaleAspectFit
            cell.imageView?.image       = #imageLiteral(resourceName: "clubMember")
            /*cell.imageView?.sd_setImage(with: URL(string: member.img),
                                        placeholderImage: #imageLiteral(resourceName: "placeholder2"))*/
            if member.user == club.prez || member.hasResponsibilities,
               let textDescriptor   = cell.textLabel?.font.fontDescriptor.withSymbolicTraits(.traitBold),
               let detailDescriptor = cell.detailTextLabel?.font.fontDescriptor.withSymbolicTraits(.traitBold) {
                cell.textLabel?.font       = UIFont(descriptor: textDescriptor, size: 0)
                cell.detailTextLabel?.font = UIFont(descriptor: detailDescriptor, size: 0)
            }
            
        case 1:  // Articles associés
            guard let relatedNews = relatedNews,
                  index < relatedNews.count else {
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
            
        case 2:  // Événements associés
            fallthrough
        default:
            guard let relatedEvents = relatedEvents,
                  index < relatedEvents.count else {
                fillCellWithPlaceholder("Aucun événement lié au club")
                return cell
            }
            
            // TODO
            // let event = relatedEvents[index]
            // NB: we might want to hide time with `dateFormatter.timeStyle = .none`
            //     when the event lasts all day
            let date  = ""/*dateFormatter.string(from: event.date).replacingOccurrences(of: ", ",
                                                                                    with: " ")*/
            cell.textLabel?.text        = ""
            cell.detailTextLabel?.text  = date
            cell.imageView?.contentMode = .center
            cell.imageView?.image       = #imageLiteral(resourceName: "events")
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
            guard let club = club,
                  index < club.users.count else { return }
            
            let member = club.users[index]
            Data.shared().mail(member.user + "@" + User.mailDomain, currentVC: self)
            
        case 1:  // Articles associés
            guard let relatedNews = relatedNews,
                  index < relatedNews.count else { return }
            
            let article = relatedNews[index]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let articleVC  = storyboard.instantiateViewController(withIdentifier: "newsArticleVC") as! NewsArticleVC
            articleVC.load(article: article)
            self.navigationController?.pushViewController(articleVC, animated: true)
            
        case 2:  // Événements associés
            fallthrough
        default:
            guard let relatedEvents = relatedEvents,
                  index < relatedEvents.count else { return }
            
            // TODO
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
