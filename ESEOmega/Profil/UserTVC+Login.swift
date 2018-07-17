//
//  UserTVC+Login.swift
//  ESEOmega
//
//  Created by Tomn on 07/09/2017.
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

extension UserTVC {
    
    // MARK: - Login
    
    /// Sends data to connection API and reacts accordingly
    func connect() {
        
        /* Hide keyboard */
        mailField.resignFirstResponder()
        passField.resignFirstResponder()
        
        guard checkConnect() else { return }
        
        /* Disable send button */
        configureSendCell(mail: "", password: "")
        
        /* CONNECT TO API */
        
        /* Create URL encoded POST attributes */
        let cleanMail = mailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let password  = self.passField.text ?? ""
        
        /* Set URL Session */
        API.request(.userLogin, get: ["email"    : cleanMail,
                                      "password" : password],
        completed: { data in
            
            DispatchQueue.main.async {
                self.spin.stopAnimating()
                
                /* Allow Send button to be tapped again */
                self.configureSendCell(mail: self.mailField.text, password: password)
            }
            
            guard let result = try? JSONDecoder().decode(LoginResult.self, from: data),
                  result.success else {
                
                let error = API.handleFailure(data: data)
                self.connectionFailed(error: error.message, code: error.code ?? -1)
                return
            }
            
            /* Validated, save data */
            DataStore.connectUser(name: result.fullname, mail: cleanMail, token: result.token)
            
            /* Alert other views */
            NotificationCenter.default.post(name: .connectionStateChanged, object: nil)
            
            /* Present greeting message */
            self.connectionSucceeded(for: result.fullname)
        
        }, failure: { error, data in
            
            DispatchQueue.main.async {
                self.spin.stopAnimating()
            }
            
            /* Allow Send button to be tapped again */
            self.configureSendCell(mail: self.mailField.text, password: password)
            
            self.connectionFailed(error: error?.localizedDescription ?? "Impossible de valider votre connexion sur nos serveurs.\nSi le problème persiste, contactez-nous.")
        })
        
        spin.startAnimating()
    }
    
    /// Checks connection parameters (mail, password) and blocks if too many attempts
    ///
    /// - Returns: True if no error, the connection can be established
    func checkConnect() -> Bool {
        
        /* Get mail (clean an lowercased) and password values */
        guard let mail = mailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              let pass = passField.text,
              mail != "",
              pass != "" else { return false }
        
        /* Give a try at the current date */
        UserTVC.attemptsNbr += 1
        let currentTimeInterval = Date.timeIntervalSinceReferenceDate
        
        /* In case the limit has been hit */
        let onTooManyAttempts = {
            
            /* Display an integer of the remaning minutes to wait */
            let minToWait = Int(ceil((UserTVC.maxAttemptsWaitingTime - currentTimeInterval + UserTVC.lastMaxAttempt) / 60))
            let unit = "minute" + (minToWait > 1 ? "s" : "")
            
            /* Present error message */
            let alert = UIAlertController(title: "Doucement",
                                          message: "Veuillez attendre \(minToWait) \(unit), vous avez réalisé trop de tentatives à la suite.",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Mince !", style: .cancel))
            
            self.present(alert, animated: true)
        }
        
        /* If the user has hit the maximum */
        if UserTVC.attemptsNbr == UserTVC.maxAttempts + 1 {
            
            /* Start the countdown */
            UserTVC.lastMaxAttempt = currentTimeInterval
            
            /* Display error message and cancel */
            onTooManyAttempts()
            return false
        }
        else if UserTVC.attemptsNbr > UserTVC.maxAttempts + 1 {

            /* If enough time has passed, set a normal number of attempts */
            if currentTimeInterval - UserTVC.lastMaxAttempt > UserTVC.maxAttemptsWaitingTime {
                UserTVC.attemptsNbr = 1
            } else {
                /* If the user still has to wait, display an error message and cancel */
                onTooManyAttempts()
                return false
            }
        }
        
        return true
    }
    
    /// Displays an alert confirming login was a success, and inits push
    ///
    /// - Parameters:
    ///   - username: Customize welcome message with the name of the user
    func connectionSucceeded(for username: String) {
        
        /* Set default values */
        var title = "Bienvenue"
        
        /* Customize with name if available */
        let formatter = PersonNameComponentsFormatter()
        if #available(iOS 10.0, *),
           let nameComponents = formatter.personNameComponents(from: username),
           let firstName = nameComponents.givenName {
            title += ", \(firstName)"
        }
        else if let firstName = username.components(separatedBy: " ").first {
            title += ", \(firstName)"
        }
        title += " !"
        
        /* Present alert box */
        let alert = UIAlertController(title: title,
                                      message: "Vous êtes connecté, vous bénéficiez désormais de la commande à la cafétéria/événements.\n\nPour être notifié lorsque votre repas est prêt, veuillez accepter les notifications !",
                                      preferredStyle: .alert)
        
        /* Custom message whether the user has already push notifications */
        let hasPushEnabled = Data.shared().pushToken != nil
        alert.addAction(UIAlertAction(title: hasPushEnabled ? "Parfait" : "Parfait, j'y penserai !",
                                      style: .cancel,
                                      handler: { _ in
            /* Register for push notifications */
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                Data.registeriOSPush(delegate)
            }
            
            /* Sync the device push token with the server to allow future push */
            if hasPushEnabled &&
               Keychain.hasValue(for: .token) {
                Data.sendPushToken()
            }
             
            /* Reset typed data if the user already wants to Disconnect */
            self.mailField.text = ""
            self.passField.text = ""
            
            /* Update whole profile panel */
            self.animateChange()
            self.tableView.reloadData()
            self.loadUI()
            self.titleImageView.removeFromSuperview()
            self.blurImageView.removeFromSuperview()
            self.contentView.removeFromSuperview()
            self.tableView.tableHeaderView = nil
            self.refreshEmptyDataSet()
        }))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    /// Displays an alert explaining why login has failed
    ///
    /// - Parameters:
    ///   - error: Description of the cause of the error, default alert texts if empty
    ///   - code: Error code (defaults to -1)
    func connectionFailed(error: String, code: Int = -1) {
        
        /* Customize title if wrong password */
        let title = code == LoginResult.wrongPasswordErrorCode
                    ? "Oups…" : "Erreur de connexion"
        
        /* Show alert with message */
        let alert = UIAlertController(title: title, message: error,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    
    // MARK: - Logout
    
    /// Asks the user whether they are sure to logout, and eventually do it
    @objc func disconnect() {
        
        /* Display an alert to confirm the choice */
        let alert = UIAlertController(title: "Voulez-vous vraiment vous déconnecter ?",
                                      message: "Vos éventuelles commandes en cours à la cafétéria restent dues.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Annuler",
                                      style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Se déconnecter",
                                      style: .destructive,
                                      handler: { _ in
            
            /* Delete any avatar from disk */
            if self.getPhoto() != nil {
                self.removePhoto()
            }
            
            /* Delete all profile data */
            DataStore.disconnectUser()
                                        
            /* Remove user's orders
               Since it's a tab, it's very probable they're currently on it, or right after */
            APIArchiver.removeCache(for: .orders)
            
            /* Display connection form and appropriate navigation bar buttons */
            self.animateChange()

            /* Reset default theme */
            ThemeManager.currentTheme = .common
            // Repaint the navigation bar
            if let userNavController = self.navigationController {
                ThemeManager.updateTheme(of: userNavController)
            }
                                        
            self.loadUI()
            self.tableView.reloadData()
            
            /* Alert other views */
            NotificationCenter.default.post(name: .connectionStateChanged, object: nil)
        }))
        
        self.present(alert, animated: true)
    }
    
}
