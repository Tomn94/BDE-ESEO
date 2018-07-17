//
//  ConnectivityHandler.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 27/05/2018.
//  Copyright © 2018 Thomas Naudet

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

import WatchConnectivity

/// Handles communications with Apple Watch
@objc class ConnectivityHandler: NSObject {
    
    /// Singleton
    @objc static let sharedHandler = ConnectivityHandler()
    private override init() {
        super.init()
    }
    
    
    /// Actual WatchConnectivity session
    let session = WCSession.default
    
    /// Session validity must be checked before using it and sending messages
    var isSessionValid: Bool {
        
        guard WCSession.isSupported() else {
            return false
        }
        return WCSession.isSupported() && session.isPaired && session.isWatchAppInstalled && session.isReachable
    }
    
    
    /// Establish connection with Apple Watch
    @objc func startSession() {
        
        // Check that's an iPhone with Apple Watch support
        guard WCSession.isSupported() else {
            return
        }
        
        // Start receiving messages
        session.delegate = self
        session.activate()
    }
    
}

// MARK: Session Delegate
extension ConnectivityHandler: WCSessionDelegate {
    
    // MARK: Message Reception
    
    /// Handles reception of messages from Watch and replies.
    ///
    ///- Parameters:
    ///   - session: Session carrying the message
    ///   - message: Content of the message,
    ///              typically a main key describing the intent, and its content
    ///   - replyHandler: Used to send a reply back with a dictionary as the content
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        
        // Handles multiple values asked by Watch
        if let getValue = message["get"] as? String {
            
            // Decide what to send depending on requested value
            switch getValue {
                
            case "token":
                // If user is not connected, there's no token, the Apple Watch app will handle this case.
                replyHandler(["token" : Keychain.string(for: .token) ?? ""])
                
            default:
                break
            }
        }
    }
    
    // MARK: Required stubs
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
}
