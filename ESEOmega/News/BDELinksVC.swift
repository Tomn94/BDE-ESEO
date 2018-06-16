//
//  BDELinksVC.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 16/06/2018.
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

class BDELinksVC: UITableViewController {
    
    static let portailURL = "https://portail.bdeeseo.fr"
    
    private let reuseIdentifier = "eseomegaLinkCell"
    
    
    /// Table view data
    var bde: Club?
    var shortcuts = [(type: KeyPath<ClubContactInfo, String?>, title: String, data: String, img: UIImage)]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Table view setup
        tableView.emptyDataSetSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        loadFromCache()
        fetchRemote()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        if shortcuts.isEmpty {
            preferredContentSize = CGSize(width: 230, height: 230)
        } else {
            preferredContentSize = CGSize(width: 200,
                                          height: tableView.contentSize.height)
        }
    }
    
}


// MARK: - API Viewer
extension BDELinksVC: APIViewer {
    
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
            
            guard let result = try? JSONDecoder().decode(ClubsResult.self, from: data),
                  result.success
                else { return }
            
            self.loadData(result.clubs)
            APIArchiver.save(data: result.clubs, for: .clubsCache)
        })
    }
    
    func loadData(_ data: [Club]) {
        
        // Get data
        bde       = nil
        shortcuts = []
        guard let bdeAngers = data.filter({ $0.isBDE && $0.isNotParisNorDijon }).first else {
            reloadData()
            return
        }
        bde = bdeAngers
        let contacts = bdeAngers.contacts
        
        // Set up links
        if let web   = contacts.web, URL(string: web) != nil,
           let index = ClubContactInfo.contactModes.index(of: \ClubContactInfo.web) {
            shortcuts.append((type:  \ClubContactInfo.web,
                              title: "Site BDE", data: web,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        shortcuts.append((type:  \ClubContactInfo.web,
                          title: "Portail vie asso.", data: BDELinksVC.portailURL,
                          img:   #imageLiteral(resourceName: "web")))
        if let mail  = contacts.mail, !mail.isEmpty,
           let index = ClubContactInfo.contactModes.index(of: \ClubContactInfo.mail) {
            shortcuts.append((type:  \ClubContactInfo.mail,
                              title: "Nous contacter",
                              data:  mail,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        if let facebook = contacts.fb, URL(string: facebook) != nil,
           let index    = ClubContactInfo.contactModes.index(of: \ClubContactInfo.fb) {
            shortcuts.append((type:  \ClubContactInfo.fb,
                              title: ClubContactInfo.contactTitles[index],
                              data:  facebook,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        if let instagram = contacts.instagram, !instagram.isEmpty,
           let index     = ClubContactInfo.contactModes.index(of: \ClubContactInfo.instagram) {
            shortcuts.append((type:  \ClubContactInfo.instagram,
                              title: ClubContactInfo.contactTitles[index],
                              data:  instagram,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        if let snap  = contacts.snap, !snap.isEmpty,
           let index = ClubContactInfo.contactModes.index(of: \ClubContactInfo.snap) {
            shortcuts.append((type:  \ClubContactInfo.snap,
                              title: ClubContactInfo.contactTitles[index],
                              data:  snap,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        if let twitter = contacts.twitter, !twitter.isEmpty,
           let index   = ClubContactInfo.contactModes.index(of: \ClubContactInfo.twitter) {
            shortcuts.append((type:  \ClubContactInfo.twitter,
                              title: ClubContactInfo.contactTitles[index],
                              data:  twitter,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        if let youtube = contacts.youtube, URL(string: youtube) != nil,
           let index   = ClubContactInfo.contactModes.index(of: \ClubContactInfo.youtube) {
            shortcuts.append((type:  \ClubContactInfo.youtube,
                              title: ClubContactInfo.contactTitles[index],
                              data:  youtube,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        if let linkedIn = contacts.linkedIn, URL(string: linkedIn) != nil,
           let index = ClubContactInfo.contactModes.index(of: \ClubContactInfo.linkedIn) {
            shortcuts.append((type:  \ClubContactInfo.linkedIn,
                              title: ClubContactInfo.contactTitles[index],
                              data:  linkedIn,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        if let tel = contacts.tel, !tel.isEmpty,
           let index = ClubContactInfo.contactModes.index(of: \ClubContactInfo.tel) {
            shortcuts.append((type:  \ClubContactInfo.tel,
                              title: ClubContactInfo.contactTitles[index],
                              data:  tel,
                              img:   ClubContactInfo.contactImgs[index]))
        }
        
        reloadData()
    }
    
    func reloadData() {
        
        DispatchQueue.main.async {
            if self.shortcuts.isEmpty {
                self.tableView.backgroundColor = .groupTableViewBackground
                self.tableView.tableFooterView = UIView()
                self.tableView.alwaysBounceVertical = false
            } else {
                self.tableView.backgroundColor = .white
                self.tableView.tableFooterView = nil
                self.tableView.alwaysBounceVertical = true
            }
            self.tableView.reloadData()
        }
    }
    
}


// MARK: - Table View Data Source
extension BDELinksVC {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return shortcuts.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        cell.textLabel?.text  = shortcuts[indexPath.row].title
        cell.imageView?.image = shortcuts[indexPath.row].img
        cell.textLabel?.font  = UIFont.preferredFont(forTextStyle: .body)
        if #available(iOS 10.0, *) {
            cell.textLabel?.adjustsFontForContentSizeCategory = true
        }
        
        return cell
    }

}


// MARK: - Table View Delegate
extension BDELinksVC {
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        if let presentingVC = self.presentingViewController {
            dismiss(animated: true) {
                    self.bde?.contacts.handle(self.shortcuts[indexPath.row].type,
                                              in: presentingVC)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}


// MARK: - VC Previewing Delegate
extension BDELinksVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location)
            else { return nil }
        
        let contactMode = shortcuts[indexPath.row]
        guard contactMode.type != \ClubContactInfo.tel,
              contactMode.type != \ClubContactInfo.mail
            else { return nil }
        
        var url = URL(string: contactMode.data.trimmingCharacters(in: .whitespaces))
        
        if contactMode.type == \ClubContactInfo.instagram, url == nil {
            url = URL(string: "https://instagram.com/" + contactMode.data + "/")
        }
        if contactMode.type == \ClubContactInfo.twitter, url == nil {
            url = URL(string: "https://twitter.com/" + contactMode.data)
        }
        if contactMode.type == \ClubContactInfo.snap, url == nil {
            url = URL(string: "https://www.snapchat.com/add/" + contactMode.data)
        }
        guard let website = url else { return nil }
        
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        
        let safari = SFSafariViewController(url: website)
        if #available(iOS 10, *) {
            safari.preferredBarTintColor     = UINavigationBar.appearance().barTintColor;
            safari.preferredControlTintColor = UINavigationBar.appearance().tintColor;
        }
        
        return safari
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
        present(viewControllerToCommit, animated: true)
    }
    
}


// MARK: - Empty Data Set Data Source
extension BDELinksVC: DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "autreVide")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return NSAttributedString(string: "Aucun lien BDE",
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline).bold(),
                                               .foregroundColor : UIColor.darkGray])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let text = "Vérifiez votre connexion et rafraîchissez l'onglet Clubs."
        
        return NSAttributedString(string: text,
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .footnote),
                                               .foregroundColor : UIColor.lightGray])
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        
        return .groupTableViewBackground
    }
    
}


// MARK: - Mail Compose VC Delegate
extension BDELinksVC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
        dismiss(animated: true)
    }
    
}

