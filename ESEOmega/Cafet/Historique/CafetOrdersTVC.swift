//
//  CafetOrdersTVC.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 08/10/2017.
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


/// Lists user's orders at the cafétéria
class CafetOrdersTVC: UITableViewController {

}


extension CafetOrdersTVC: APIViewer {
    
    typealias T = [CafetOrder]
    
    
    func loadFromCache() {
    }
    
    func fetchRemote() {
    }
    
    func loadData(_ data: [CafetOrder]) {
    }
    
    func reloadData() {
    }
}


// MARK: - Table View Data Source
extension CafetOrdersTVC {
    
}


// MARK: - Table View Delegate
extension CafetOrdersTVC {
    
}


// MARK: - 3D Touch
extension CafetOrdersTVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
    }
    
    
}


// MARK: - Empty Data Set Source
extension CafetOrdersTVC: DZNEmptyDataSetSource {
    
}


// MARK: - Empty Data Set Delegate
extension CafetOrdersTVC: DZNEmptyDataSetDelegate {
    
}
