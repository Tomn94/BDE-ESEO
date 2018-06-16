//
//  LinksToolbar.swift
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
    static let showLink    = #selector(LinksToolbar.showLink(_:))
    static let showBDEMenu = #selector(LinksToolbar.showBDEMenu)
}


class LinksToolbar: UIView {
    
    typealias QuickLink = (image: UIImage, url: String)
    
    @objc static let portalQuickLink = "https://reseaueseo.sharepoint.com"
    @objc static let campusQuickLink = "https://campus-reseaueseo.msappproxy.net"
    static let quickLinks: [QuickLink] = [QuickLink(image: #imageLiteral(resourceName: "eseoMails"),
                                                    url: "https://outlook.office365.com"),
                                          QuickLink(image: #imageLiteral(resourceName: "eseo"),
                                                    url: "https://eseo.fr"),
                                          QuickLink(image: #imageLiteral(resourceName: "eseoPortail"),
                                                    url: LinksToolbar.portalQuickLink),
                                          QuickLink(image: #imageLiteral(resourceName: "eseoCampus"),
                                                    url: LinksToolbar.campusQuickLink),
                                          QuickLink(image: #imageLiteral(resourceName: "dreamspark"),
                                                    url: "https://moncompte.eseo.fr/authentificationMSDNA.aspx?action=signin")]
    
    private let toolbar = UIToolbar()
    
    /// Where the popover comes from
    private var bdeLink: UIBarButtonItem?
    
    private var currentItems = [UIBarButtonItem]()
    
    /// NewsList
    var viewController: UIViewController?
    
    
    private var toolbarItems: [UIBarButtonItem] {
        
        var items = [UIBarButtonItem]()
        
        for link in LinksToolbar.quickLinks {
            items.append(UIBarButtonItem(image: link.image, style: .plain,
                                         target: self, action: .showLink))
        }
        bdeLink = UIBarButtonItem(image: Data.linksToolbarBDEIcon(), style: .plain,
                                  target: self, action: .showBDEMenu)
        items.append(bdeLink!)
        
        return items
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: 64)
        autoresizingMask = .flexibleWidth
        backgroundColor  = UIColor(white: 0.98, alpha: 1)
        
        let border = UIView()
        border.frame = CGRect(x: 0, y: 0, width: frame.width,
                              height: 1 / UIScreen.main.scale)
        border.autoresizingMask = .flexibleWidth
        border.backgroundColor = UIColor(white: 0.8, alpha: 1)
        addSubview(border)
        
        let header = UILabel(frame: CGRect(x: 4, y: 0,
                                           width: frame.width, height: 20))
        header.text = "LIENS RAPIDES"
        header.textColor = UIColor(white: 0.5, alpha: 1)
        header.sizeToFit()
        header.font = UIFont.preferredFont(forTextStyle: .caption2)
        addSubview(header)
        
        toolbar.frame = CGRect(x: 0, y: 16, width: frame.width, height: 48)
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.delegate = self
        toolbar.setBackgroundImage(UIImage(),
                                   forToolbarPosition: .any, barMetrics: .default)
        
        reloadItems()
        
        addSubview(toolbar)
        
        NotificationCenter.default.addObserver(self, selector: .updateTheme,
                                               name: .themeChanged, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadItems() {
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
        currentItems      = toolbarItems
        var items         = [flexibleSpace]
        for linkItem in currentItems {
            items.append(flexibleSpace)
            items.append(linkItem)
        }
        items.append(flexibleSpace)
        toolbar.items = items
    }
    
    @objc func updateTheme() {
        
        reloadItems()
    }
    
    
    // MARK: - Actions
    
    @objc func showLink(_ sender: UIBarButtonItem) {
        
        guard viewController != nil,
              let index = currentItems.index(of: sender),
              index < LinksToolbar.quickLinks.count else {
            return
        }
        
        Data.shared().openURL(LinksToolbar.quickLinks[index].url,
                              currentVC: viewController)
    }
    
    @objc func showBDEMenu() {
        
        let pop = BDELinksVC()
        pop.modalPresentationStyle = .popover
        pop.popoverPresentationController?.delegate = self
        pop.popoverPresentationController?.barButtonItem = bdeLink
        viewController?.present(pop, animated: true)
    }

}


// MARK: - Tool Bar Delegate
extension LinksToolbar: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {        
        return .top
    }
    
}


// MARK: - Popover Presentation Controller Delegate
extension LinksToolbar: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}
