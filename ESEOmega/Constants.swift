//
//  Constants.swift
//  ESEOmega
//
//  Created by Tomn on 07/09/2017.
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

import Foundation

// MARK: - Global notifications names within the app
extension Notification.Name {
    
    /// User has just been logged in/out
    static let connectionStateChanged = Notification.Name("connecte")
    
    /// App theme has been changed
    static let themeChanged           = NSNotification.Name("themeUpdated")
    
    /// Debug refresh control stuck when quitting and reopening the app
    static let debugRefresh           = NSNotification.Name("debugRefresh")
    
    
    // MARK: MessagesExtension
    
    /// Sticker list changed
    static let stickersReloaded       = Notification.Name("stickersReloaded")
    
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
    
    
    // MARK: MessagesExtension
    
    /// Server response cached for fast reload
    static let stickers       = "stickers"
    
    
    // MARK: WatchExtension
    
    /// Server response cached for fast reload
    static let watchRooms     = "watchRooms"
    
}


/// Types used for NSUserActivity/Handoff
enum ActivityType {
    
    typealias ActivityInfo = (type: String, title: String, url: URL)
    
    static let baseURL = "https://bdeeseo.fr/"
    
    static let cafetDisplayURL = "https://portail.bdeeseo.fr/modules/lacommande/displayCafet/"
    
    
    static let news = ActivityInfo(type: "com.eseomega.ESEOmega.news",
                                   title: "Liste des news",
                                   url: URL(string: baseURL + "news")!)
    
    static let article = ActivityInfo(type: "com.eseomega.ESEOmega.article",
                                      title: "Actualité",
                                      url: URL(string: baseURL + "news")!)
    
    static let clubs = ActivityInfo(type: "com.eseomega.ESEOmega.clubs",
                                    title: "BDE & liste des clubs",
                                    url: URL(string: baseURL + "clubs")!)
    
    static let cafet = ActivityInfo(type: "com.eseomega.ESEOmega.cafet",
                                    title: "Liste de mes commandes à la cafet",
                                    url: URL(string: cafetDisplayURL)!)
    
    static let order = ActivityInfo(type: "com.eseomega.ESEOmega.order",
                                    title: "Commander à la cafet",
                                    url: URL(string: cafetDisplayURL)!)
    
    static let rooms = ActivityInfo(type: "com.eseomega.ESEOmega.rooms",
                                    title: "Liste des salles",
                                    url: URL(string: baseURL + "rooms")!)
    
    static let families = ActivityInfo(type: "com.eseomega.ESEOmega.families",
                                       title: "Familles & parrainages",
                                       url: URL(string: baseURL + "families")!)
    
}
