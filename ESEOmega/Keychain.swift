//
//  Keychain.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 12/11/2017.
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

import Foundation

class Keychain {
    
    private static let accessGroup = "com.eseomega.ESEOmega.KeyGroup"
    
    
    static func hasValue(for key: KeychainKey) -> Bool {
        return JNKeychain.loadValue(forKey: key.rawValue,
                                    forAccessGroup: Keychain.accessGroup) != nil
    }
    
    static func value(for key: KeychainKey) -> Any? {
        return JNKeychain.loadValue(forKey: key.rawValue,
                                    forAccessGroup: Keychain.accessGroup)
    }
    
    static func string(for key: KeychainKey) -> String? {
        return Keychain.value(for: key) as? String
    }
    
    static func save(value: Any, for key: KeychainKey) {
        JNKeychain.saveValue(value, forKey: key.rawValue,
                             forAccessGroup: Keychain.accessGroup)
    }
    
    static func deleteValue(for key: KeychainKey) {
        JNKeychain.deleteValue(forKey: key.rawValue,
                               forAccessGroup: Keychain.accessGroup)
    }
    
}


/// Common keys to get or set values in Keychain
enum KeychainKey: String {
    
    /// Name of the logged user (e.g. `Thomas NAUDET`)
    case name  = "uname"
    
    /// Email address of the logged user (e.g. `prenom.nom@reseau.eseo.fr`)
    case mail  = "mail"
    
    /// Token needed for API requests requiring login
    case token = "token"
    
    /// Name of the logged user (e.g. `Thomas 06 01 02 03 04`)
    case phone = "phone"
    
}
