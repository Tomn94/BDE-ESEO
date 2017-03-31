//
//  DataStore.swift
//  ESEOmega
//
//  Created by Tomn on 05/02/2017.
//  Copyright © 2017 Tomn. All rights reserved.
//

import Foundation


// MARK: - Global notifications within the app
extension Notification.Name {
    
    /// User has just been logged in/out
    static let connectionStateChanged = Notification.Name("connecte")
    
    /// App theme has been changed
    static let themeChanged           = NSNotification.Name("themeUpdated")
    
}


/// Common keys used to get or set values in User Defaults
enum UserDefaultsKey {
    
    /// Current app appearance (0 = common | 1 = BDEl'dorado | 2 = ESEOmega | 3 = ESEOasis | …)
    static let appTheme       = "appTheme"
    
    /// Sort rooms list mode (0 = by name | 1 = by building | 2 = by floor)
    static let roomsSortMode  = "roomsSortMode"
    
    /// Tip How To Print a Document (0 = not seen | 1 = already seen once | 2 = don't show again)
    static let printWarning   = "messageImpressionLu"
    
    /// Whether the user has seen some new events so a tab badge should be hidden (true = hide badge | false = display badge)
    static let seenEventBadge = "nouveauBoutonEventVu"
    
    /// Whether GP is enabled or not
    static let gp             = "GPenabled"
    
    /// Whether app data has already been erased to support ESEOasis API
    static let usesAPIv4      = "alreadyLaunchedv4NewAPI"
    
}


/// Common keys to get or set values in Keychain
enum KeychainKey {
    /// Login of the connected user (e.g. `naudettho`)
    static let login    = "login"
    /// Hashed password of the logged user
    static let password = "passw"
    /// Name of the logged user (e.g. `Thomas NAUDET`)
    static let name     = "uname"
    /// Name of the logged user (e.g. `Thomas 06 01 02 03 04`)
    static let phone    = "phone"
    /// Email address of the logged user (e.g. `thomas.naudet@reseau.eseo.fr`)
    static let mail     = "mail"
}


/// Common JSON names to identify API services
enum JSONid {
    /// News list
    static let news        = "news"
    /// Events list
    static let events      = "events"
    /// Bought events list
    static let eventOrders = "eventsCmds"
    /// Clubs list
    static let clubs       = "clubs"
    /// Orders list
    static let orders      = "cmds"
    /// Kitchen status
    static let orderStatus = "service"
    /// Menu items available
    static let orderMenus  = "menus"
    /// Sponsors list
    static let sponsors    = "sponsors"
    /// Rooms list
    static let rooms       = "rooms"
    /// Ingenews documents lsit
    static let ingenews    = "ingenews"
}


/// Replaces deprecated Data class
class DataStore {
}
