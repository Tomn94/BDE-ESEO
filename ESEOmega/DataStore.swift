//
//  DataStore.swift
//  ESEOmega
//
//  Created by Tomn on 05/02/2017.
//  Copyright © 2017 Tomn. All rights reserved.
//

import Foundation

enum UserDefaultsKey {
    static let appTheme       = "appTheme"
    static let roomsSortMode  = "roomsSortMode"
    static let printWarning   = "messageImpressionLu"
    static let seenEventBadge = "nouveauBoutonEventVu"
    static let gp             = "GPenabled"
    static let usesAPIv4      = "alreadyLaunchedv4NewAPI"
}

enum JSONid {
    static let news        = "news"
    static let events      = "events"
    static let eventOrders = "eventsCmds"
    static let clubs       = "clubs"
    static let orders      = "cmds"
    static let orderStatus = "service"
    static let orderMenus  = "menus"
    static let sponsors    = "sponsors"
    static let rooms       = "rooms"
    static let ingenews    = "ingenews"
}

enum KeychainKey {
    static let login    = "login"
    static let password = "passw"
    static let name     = "uname"
    static let phone    = "phone"
    static let mail     = "mail"
}

class DataStore {
}
