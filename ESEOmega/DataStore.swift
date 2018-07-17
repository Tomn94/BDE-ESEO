//
//  DataStore.swift
//  ESEOmega
//
//  Created by Tomn on 05/02/2017.
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
        
        Keychain.save(value: name,  for: .name)
        Keychain.save(value: mail,  for: .mail)
        Keychain.save(value: token, for: .token)
    }
    
    /// Returns whether the user is currently logged
    @objc static var isUserLogged: Bool {
        return Keychain.hasValue(for: .token)
    }
    
    /// Marks the user as disconnected in the app.
    /// Removes associated data.
    static func disconnectUser() {
        
        Data.delPushToken()
        
        Keychain.deleteValue(for: .name)
        Keychain.deleteValue(for: .mail)
        Keychain.deleteValue(for: .token)
    }
    
}
