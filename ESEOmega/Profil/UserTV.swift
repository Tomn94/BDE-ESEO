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

// MARK: - Delegate
/// Delegate of the Settings table view in the user's profile
class UserTVDelegate: NSObject, UITableViewDelegate {
    
    /// View controller of the user's profile page
    weak var userTVC: UserTVC?
    
    /// Check mark displayed in front of the selected theme
    private static let tickPrefix = "✓ "
    
    
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
            /* Cell number for Lydia and events */
            forgetTel()
            break
            
        case 1:
            /* App color theme */
            selectTheme()
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
    
    
    // MARK: - Actions
    
    /// Reload table view and animate changes
    private func reloadDataAnimated() {
        
        userTVC?.optionsTable.reloadData()
        
        /* Make a simple transition
           Nicer animation than reloadSections:withRowAnimation: */
        let animation = CATransition()
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        userTVC?.optionsTable.layer.add(animation, forKey: nil)
    }
    
    
    // MARK: Phone number
    
    /// Asks the user to confirm the deletion of their stored phone number, and eventually do it.
    /// If there's no phone number, inform the user
    private func forgetTel() {
        
        guard self.userTVC != nil else { return }
        
        /* Display a different message when there's no phone registered */
        guard let phoneNumber = Keychain.string(for: .phone) else {
            let alert = UIAlertController(title: "Aucun numéro de téléphone renseigné",
                                          message: "Un numéro de téléphone portable est demandé par Lydia afin de lier les commandes cafet/event à votre compte, également lorsque vous vous inscrivez à un événement gratuit hors Lydia.\nIl n'est pas stocké sur nos serveurs sauf dans 2e cas.",
                                          preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.userTVC?.present(alert, animated: true)
            return
        }
        
        /* Display action sheet to confirm deletion.
           Action sheets are more appropriate than alerts for deletion on iOS */
        let alert = UIAlertController(title: "Voulez-vous effacer ce numéro de téléphone ?",
                                      message: phoneNumber + "\n\nVotre numéro de téléphone portable est utilisé par Lydia afin de lier les commandes cafet/event à votre compte, également lorsque vous vous inscrivez à un événement gratuit hors Lydia.\nIl n'est pas stocké sur nos serveurs sauf dans 2e cas.\n\nUn nouveau numéro vous sera demandé au prochain achat cafet/event via Lydia, ou inscription event.",
                                      preferredStyle: .actionSheet)
        
        /* Destructive type button to confirm */
        alert.addAction(UIAlertAction(title: "Supprimer", style: .destructive, handler: { _ in
            
            /* Delete stored value, and remove the phone number from the view */
            Keychain.deleteValue(for: .phone)
            self.reloadDataAnimated()
        }))
        
        /* Add also a Cancel button, and present inside this view controller */
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        self.userTVC?.present(alert, animated: true)
    }
    
    
    // MARK: App theme
    
    /// Present a theme picker to the user
    private func selectTheme() {
        
        /* Get app themes including the current one */
        let themes = ThemeManager.themes
        let currentTheme = ThemeManager.currentTheme
        
        /* Define what happens when a theme button is selected */
        let actionHandler = { (action: UIAlertAction) in
            
            /* Link the selected text to its theme.
               The current theme has a tick in the action.title, if selected again, it won't be found, nothing will happen, it's fine */
            if let index = themes.index(where: { $0.name == action.title }) {
                
                /* Apply the theme to the whole app */
                ThemeManager.currentTheme = themes[index]
                
                /* Update the profile view controller behind */
                if let userTVC = self.userTVC,
                   let userNavController = userTVC.navigationController {
                    
                    /* Repaint the navigation bar */
                    ThemeManager.updateTheme(of: userNavController)
                    
                    /* Display the new theme in the Settings table */
                    self.reloadDataAnimated()
                }
            }
        }
        
        /* Now configure the picker */
        var title   = "Choisissez un thème pour l'application"
        var message: String? = "Mettez à jour iOS pour en plus changer l'icône de l'app !"
        if #available(iOS 10.3, *) {
            title   = "Choisissez le thème et l'icône de l'application"
            message = nil
        }
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: .actionSheet)
        
        /* Add a button to the alert for each theme */
        for theme in themes {
            /* If we're dealing with the current theme, add a tick in front of its title */
            var actionTitle = theme.name
            if theme == currentTheme {
                actionTitle = UserTVDelegate.tickPrefix + actionTitle
            }
            
            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: actionHandler))
        }
        
        /* Add also a Cancel button, and present inside the profile view controller */
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        self.userTVC?.present(alert, animated: true)
    }
    
}


// MARK: - Data source
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
            if let phone = Keychain.string(for: .phone) {
                cell?.detailTextLabel?.text = phone
            } else {
                cell?.detailTextLabel?.text = "Aucun"
            }
            
        case 1:
            /* App color theme */
            let theme: ThemeManager.Theme = ThemeManager.Theme(rawValue: UserDefaults.standard.integer(forKey: UserDefaultsKey.appTheme)) ?? .common
            cell?.textLabel?.text = "Thème et icône"
            cell?.detailTextLabel?.text = theme.name
            
        default:
            break
        }
        
        return cell!
    }
    
}
