//
//  ClubsSplit.swift
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

class ClubsSplit: UISplitViewController {
    
    var master: UIViewController?
    
    var initialRightBarItems = [UIBarButtonItem]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        preferredDisplayMode = .allVisible
        
        if let masterNav = self.viewControllers.first as? UINavigationController,
           let master = masterNav.viewControllers.first {
            
            self.master = master
            initialRightBarItems = master.navigationItem.rightBarButtonItems ?? []
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        setupBarButtons()
    }
    
    
    // MARK: - Actions
    
    func setupBarButtons() {
        
        if displayMode == .allVisible && !isCollapsed {
            // Only show Credits icon, since Login is on detail view
            master?.navigationItem.setRightBarButtonItems([],
                                                          animated: true)
        } else {
            // Show User Login icon on master, on iPhone portrait
            master?.navigationItem.setRightBarButtonItems(initialRightBarItems,
                                                          animated: true)
        }
    }
    
}


// MARK: - Split View Controller Delegate
extension ClubsSplit: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        
        guard let detailNav = secondaryViewController as? UINavigationController,
              let detail    = detailNav.viewControllers.first as? ClubDetailTVC else {
                return true
        }
        return detail.club == nil
    }
    
    func splitViewController(_ svc: UISplitViewController,
                             willChangeTo displayMode: UISplitViewController.DisplayMode) {
        
        self.setupBarButtons()
    }
    
}
