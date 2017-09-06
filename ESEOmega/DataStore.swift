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
    
    /// Rooms data received
    static let newDataRooms           = NSNotification.Name(Room.apiPath)
    
    /// IngeNews data received
    static let newDataIngeNews        = NSNotification.Name(IngeNews.apiPath)
    
    /// Debug refresh control stuck when quitting and reopening the app
    static let debugRefresh           = NSNotification.Name("debugRefresh")
    
}


/// Common keys used to get or set values in User Defaults
enum UserDefaultsKey {
    
    /// Current app appearance (0 = common | 1 = BDEl'dorado | 2 = ESEOmega | 3 = ESEOasis | …)
    static let appTheme       = "appTheme"
    
    /// Sort rooms list mode (0 = by name | 1 = by building | 2 = by floor)
    static let roomsSortMode  = "roomsSortMode"
    
    /// Tip How To Print a Document (see values in PrintWarningStatus)
    static let printWarning   = "messageImpressionLu"
    
    /// Whether the user has seen some new events so a tab badge should be hidden (true = hide badge | false = display badge)
    static let seenEventBadge = "nouveauBoutonEventVu"
    
    /// Whether GP is enabled or not
    static let gp             = "GPenabled"
    
    /// Whether app data has already been erased to support ESEOasis API
    static let usesAPIv4      = "alreadyLaunchedv4NewAPI"
    
    /// Whether app data has already been erased to support ESEOdin API
    static let usesAPIv5      = "alreadyLaunchedv5NewAPI"
    
}


/// Common keys to get or set values in Keychain
enum KeychainKey {
    
    /// Name of the logged user (e.g. `Thomas NAUDET`)
    static let name     = "uname"
    
    /// Email address of the logged user (e.g. `prenom.nom@reseau.eseo.fr`)
    static let mail     = "mail"
    
    /// Token needed for API requests requiring login
    static let token    = "token"
    
    /// Name of the logged user (e.g. `Thomas 06 01 02 03 04`)
    static let phone    = "phone"
    
}

/// Lists all available API Paths
enum API: String {
    
    /// Common URL for all API requests
    static private let apiURL = "https://api.bdeeseo.fr/"
    
    
    /// Creates an URL Request for the API quickly,
    /// using one of the available API Paths
    static func request(_ apiPath: API) -> URLRequest {
        return URLRequest(url: URL(string: apiURL + apiPath.rawValue)!)
    }
    
    
    /// Connect user
    case userLogin = "users/login"
    
}


/// Stores all crucial data for the app,
/// and has some convenience methods revolving around them
@objc class DataStore: NSObject {
    
    
    // MARK: - User Login
    
    /// Marks the user as logged in the app, and store their info
    ///
    /// - Parameters:
    ///   - name:  Full name of the user
    ///   - mail:  Mail address of the user (ESEO)
    ///   - token: Connection token to API
    static func connectUser(name: String, mail: String, token: String) {
        
        JNKeychain.saveValue(name,  forKey: KeychainKey.name)
        JNKeychain.saveValue(mail,  forKey: KeychainKey.mail)
        JNKeychain.saveValue(token, forKey: KeychainKey.token)
    }
    
    /// Returns whether the user is currently logged
    @objc static var isUserLogged: Bool {
        return JNKeychain.value(forKey: KeychainKey.token) != nil
    }
    
    /// Marks the user as disconnected in the app.
    /// Removes associated data.
    static func disconnectUser() {
        
        Data.delPushToken()
        
        JNKeychain.deleteValue(forKey: KeychainKey.name)
        JNKeychain.deleteValue(forKey: KeychainKey.mail)
        JNKeychain.deleteValue(forKey: KeychainKey.token)
    }
    
}
