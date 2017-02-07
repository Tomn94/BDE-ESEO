//
//  UserTV.swift
//  ESEOmega
//
//  Created by Thomas Naudet on 07/02/2017.
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

/// Delegate of the Settings table view in the user's profile
class UserTVDelegate: NSObject, UITableViewDelegate {
    
    /// Reaction when the user touches a cell
    ///
    /// - Parameters:
    ///   - tableView: Options table view
    ///   - indexPath: Selected index path
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        /* React differently to row position */
        switch indexPath.row {
        case 0:
            break
            
        case 1:
            break
            
        default:
            break
        }
        
        /* Deselect row */
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// Reaction when the user taps the info button of the cell
    ///
    /// - Parameters:
    ///   - tableView: Options table view
    ///   - indexPath: Position of the button which has been tapped
    func tableView(_ tableView: UITableView,
                   accessoryButtonTappedForRowWith indexPath: IndexPath) {
        self.tableView(tableView, didSelectRowAt: indexPath)
    }
    
}

/// Data source of the Settings table view in the user's profile
class UserTVDataSource: NSObject, UITableViewDataSource {
    
    /// Cell identifier of the Options table view rows
    static let cellIdentifier = "UserProfileOptionCell"
    
    /// Returns the number of rows in the table view
    ///
    /// - Parameters:
    ///   - tableView: Options table view
    ///   - section: The one and only section of the table view
    /// - Returns: Number of options (a.k.a. rows) to be displayed
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return UserTVC.optionsNbr
    }
    
    /// Fills an Options table view cell with its content
    ///
    /// - Parameters:
    ///   - tableView: Options table view
    ///   - indexPath: Position of the cell to customize
    /// - Returns: A new cell with its content
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        /* Set up a cell with detailed info on the right */
        var cell = tableView.dequeueReusableCell(withIdentifier: UserTVDataSource.cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: UserTVDataSource.cellIdentifier)
        }
        
        cell?.accessoryType = .detailButton
        
        /* Cell customization */
        switch indexPath.row {
        case 0:
            /* Cell number for Lydia and events */
            cell?.textLabel?.text = "Identifiant Lydia"
            if let phone = JNKeychain.loadValue(forKey: KeychainKey.phone) as? String {
                cell?.detailTextLabel?.text = phone
            } else {
                cell?.detailTextLabel?.text = "Aucun"
            }
            
        case 1:
            /* App color theme */
            let theme: ThemeManager.Theme = ThemeManager.Theme(rawValue: UserDefaults.standard.integer(forKey: UserDefaultsKey.appTheme)) ?? .common
            cell?.textLabel?.text = "Thème de l'app"
            cell?.detailTextLabel?.text = theme.name
            
        default:
            break
        }
        
        return cell!
    }
    
}
