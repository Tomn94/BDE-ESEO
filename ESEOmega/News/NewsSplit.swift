//
//  NewsSplit.swift
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
    static let showCredits = #selector(NewsSplit.showCredits)
}

class NewsSplit: UISplitViewController {
    
    var master: UIViewController?
    
    var creditsItem: UIBarButtonItem!
    
    var initialRightBarItems = [UIBarButtonItem]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self;
        preferredDisplayMode = .allVisible
        
        if let masterNav = self.viewControllers.first as? UINavigationController,
           let master = masterNav.viewControllers.first {
            
            self.master = master
            initialRightBarItems = master.navigationItem.rightBarButtonItems ?? []
        }
    
        // Credits navigation bar button
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: .showCredits, for: .touchUpInside)
        creditsItem = UIBarButtonItem(customView: infoButton)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        setupBarButtons()
    }
    

    // MARK: - Actions
    
    func setupBarButtons() {
        
        if displayMode == .allVisible && !isCollapsed {
            // Only show Credits icon, since Login is on detail view
            master?.navigationItem.setRightBarButtonItems([creditsItem],
                                                          animated: true)
        } else {
            // Show User Login icon on master, on iPhone portrait
            master?.navigationItem.setRightBarButtonItems(initialRightBarItems + [creditsItem],
                                                          animated: true)
        }
    }
    
    @objc func showCredits() {
        
        let credits = CreditsTVC(style: .grouped)
        let nav = UINavigationController(rootViewController: credits)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
    
}


// MARK: - Split View Controller Delegate
extension NewsSplit: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        
        guard let detailNav = secondaryViewController as? UINavigationController,
              let detail = detailNav.viewControllers.first as? NewsArticleVC else {
                return true
        }
        return detail.article == nil
    }
    
    func splitViewController(_ svc: UISplitViewController,
                             willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        
        self.setupBarButtons()
    }
    
}
