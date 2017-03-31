//
//  ThemeManager.swift
//  ESEOmega
//
//  Created by Thomas NAUDET on 31/01/2017.
//  Copyright © 2017 Thomas NAUDET

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

/// Application theme handler.
/// Allows the user to choose a theme and to apply it to the whole app
@objc class ThemeManager: NSObject {
    
    /// Disables instantiations
    private override init() {}
    
    
    typealias ThemeRawValue = Int
    
    // MARK: - Themes
    
    /// Describes themes for the app
    enum Theme: ThemeRawValue {
        
        /// A common theme for all Students’ Union
        case common     = 0
        
        /// Un thème qui a combattu
        case bdelirium  = 1
        
        /// Un thème hot
        case eseonfire  = 2
        
        /// Un thème qui claque sa dorade
        case bdeldorado = 3
        
        /// Un thème divin
        case eseomega   = 4
        
        /// Un thème exotique
        case eseoasis   = 5
        
       
        // MARK: Themes associated attributes
        
        /// Defines which attribute types a theme has
        typealias ThemeValue = (bars: UIColor, barButtons: UIColor, window: UIColor)
        
        /// Describes each attribute value for every theme
        var themeValue: ThemeValue {
            switch self {
            case .common:     return (bars: #colorLiteral(red: 0, green: 0.5333333333, blue: 1, alpha: 1), barButtons: #colorLiteral(red: 0.68, green: 0.8986666667, blue: 1, alpha: 1), window: #colorLiteral(red: 0, green: 0.5333333333, blue: 1, alpha: 1))
            case .bdelirium:  return (bars: #colorLiteral(red: 0.3403527123, green: 0, blue: 0.6107313368, alpha: 1), barButtons: #colorLiteral(red: 0.9921568627, green: 0.8899822682, blue: 0.5676783721, alpha: 1), window: #colorLiteral(red: 0.3403527123, green: 0, blue: 0.6107313368, alpha: 1))
            case .eseonfire:  return (bars: #colorLiteral(red: 0, green: 0.454615162, blue: 0.8524034288, alpha: 1), barButtons: #colorLiteral(red: 1, green: 0.8986666667, blue: 0.84, alpha: 1), window: #colorLiteral(red: 0, green: 0.454615162, blue: 0.8524034288, alpha: 1))
            case .bdeldorado: return (bars: #colorLiteral(red: 0.5882352941, green: 0.03137254902, blue: 0, alpha: 1), barButtons: #colorLiteral(red: 0.9921568627, green: 0.7960784314, blue: 0.1775602698, alpha: 1), window: #colorLiteral(red: 0.5882352941, green: 0.03137254902, blue: 0, alpha: 1))
            case .eseomega:   return (bars: #colorLiteral(red: 0, green: 0.647, blue: 1, alpha: 1), barButtons: #colorLiteral(red: 0.806, green: 0.959, blue: 1, alpha: 1), window: #colorLiteral(red: 0.078, green: 0.707, blue: 1, alpha: 1))
            case .eseoasis:   return (bars: #colorLiteral(red: 1, green: 0.5, blue: 0, alpha: 1), barButtons: #colorLiteral(red: 0.9608, green: 0.9205, blue: 0.816, alpha: 1), window: #colorLiteral(red: 1, green: 0.5, blue: 0, alpha: 1))
            }
        }
        
        /// String describing each theme
        var name: String {
            switch self {
            case .common:     return "Par défaut"
            case .bdelirium:  return "BDElirium"
            case .eseonfire:  return "ESE'On Fire"
            case .bdeldorado: return "BDEl'dorado"
            case .eseomega:   return "ESEOmega"
            case .eseoasis:   return "ESEOasis"
            }
        }
    }
    
    /// Returns the list of all the themes available
    static var themes: [Theme] {
        return [.common,
                .bdelirium,
                .eseonfire,
                .bdeldorado,
                .eseomega,
                .eseoasis]
    }
    
    
    // MARK: - Apply theme
    
    /// Stores the currently selected theme.
    /// Load value from user preferences, or return the default theme
    static var currentTheme = Theme(rawValue: UserDefaults.standard.integer(forKey: UserDefaultsKey.appTheme)) ?? Theme.common {
        didSet {
            /* Update the app appearance when the theme changes */
            if currentTheme != oldValue {
                ThemeManager.updateTheme()
            }
            
            /* Save preference */
            UserDefaults.standard.set(currentTheme.rawValue, forKey: UserDefaultsKey.appTheme)
        }
    }
    
    /// Applies the choosen theme to the whole app
    static func updateTheme() {
        
        let currentTheme = ThemeManager.currentTheme
        
        /* Customize Navigation Bars */
        UINavigationBar.appearance().barTintColor = currentTheme.themeValue.bars
        UINavigationBar.appearance().tintColor    = currentTheme.themeValue.barButtons
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        /* Apply tint color to every view controller */
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
           let window = delegate.window {
            window.tintColor = currentTheme.themeValue.window
        }
        
        /* Update every navigation bar in the app */
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? TabBarController,
           let tabs = tabBarController.viewControllers {
            
            tabs.forEach { tab in
                
                /* If its main view is directly a navigation controller, update its bar */
                if let navigationController = tab as? UINavigationController {
                    ThemeManager.updateTheme(of: navigationController)
                }
                /* Otherwise if it's a split view controller */
                else if let splitViewController = tab as? UISplitViewController {
                    /* Update each navigation controller inside */
                    splitViewController.viewControllers.forEach {
                        if let navigationController = $0 as? UINavigationController {
                            ThemeManager.updateTheme(of: navigationController)
                        }
                    }
                }
            }
            
            /* Refresh the color of any empty data set button in Cafeteria tab */
            if let cafetTab = tabs[3] as? UINavigationController,
               let cafetTVC = cafetTab.topViewController as? CommandesTVC {
                cafetTVC.tableView.reloadEmptyDataSet()
            }
        }
        
        /* Change app icon reflecting theme */
        if #available(iOS 10.3, *) {
            if UIApplication.shared.supportsAlternateIcons {
                
                let iconName = currentTheme != .common ? currentTheme.name : nil
                UIApplication.shared.setAlternateIconName(iconName)
            }
        }
        
        /* Notify theme change for any other single views */
        NotificationCenter.default.post(name: .themeChanged, object: nil)
    }
    
    /// Updates the theme of some navigation controller refusing to refresh
    ///
    /// - Parameter navigationController: Navigation Controller to repaint
    static func updateTheme(of navigationController: UINavigationController) {
        
        UIView.animate(withDuration: 0.3) {
            navigationController.navigationBar.barTintColor = UINavigationBar.appearance().barTintColor
            navigationController.navigationBar.tintColor    = UINavigationBar.appearance().tintColor
            navigationController.navigationBar.layoutIfNeeded()     // allows animation
        }
    }
    
    /// Overrides current theme with a special red theme during event ordering
    ///
    /// - Parameter navigationController: Applies theme on its Navigation Bar
    static func useEventTheme(on navigationController: UINavigationController) {
        
        let appColorEvent = #colorLiteral(red: 0.929, green: 0.11, blue: 0.141, alpha: 1)
        navigationController.navigationBar.barTintColor  = appColorEvent;
        navigationController.navigationBar.tintColor     = #colorLiteral(red: 0.9964, green: 0.8461, blue: 0.8497, alpha: 1);
        UIApplication.shared.keyWindow?.tintColor        = appColorEvent;
    }
    
    
    /// Returns the current theme raw value for Objective-C compability
    ///
    /// - Returns: Theme raw value
    static func objc_currentTheme() -> ThemeRawValue {
        return currentTheme.rawValue
    }
    
}
