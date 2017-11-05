//
//  Lydia.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 05/11/2017.
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

@objc class Lydia: NSObject {
    
    static let appURL = URL(string: "com.lydia-app://")!
    
    static let minPrice = 0.5
    static let maxPrice = 250.0
    
    enum Category: String {
        case cafet = "CAFET"
        case event = "EVENT"
    }
    
    /// Lydia API limits
    static func isValid(price: Double) -> Bool {
        return minPrice...maxPrice ~= price
    }
    
    
    @objc static func checkStatusObjCBridge(_ raw: [String : String]) {
        
        guard let order    = raw["id"],
              let category = raw["cat"],
              let type     = Category(rawValue: category)
            else { return }
        
        Lydia.checkStatus(for: order, type: type, viewController: nil)
    }
    
    static func checkStatus(for order: String, type: Category,
                            viewController: UIViewController?) {
        
        var vc = viewController
        if vc == nil,
           let window = UIApplication.shared.delegate?.window {
            vc = window?.rootViewController
        }
        guard vc != nil,
              let token = JNKeychain.loadValue(forKey: KeychainKey.token) as? String
            else { return }
        
        let alert = UIAlertController(title: "État du paiement Lydia",
                                      message: "Vérification en cours…",
                                      preferredStyle: .alert)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30)) { [weak alert] in
            alert?.dismiss(animated: true)
        }
        vc!.present(alert, animated: true)
        
        API.request(.lydiaCheck, post: ["idcmd"     : order,
                                        "cat_order" : type.rawValue],
                    authentication: token,
                    completed: { data in
            
            alert.dismiss(animated: true) {
                
                if let raw    = try? JSONSerialization.jsonObject(with: data),
                   let json   = raw as? [String : Any],
                   let status = json["status"] as? Int {
                    
                    if status == 1,
                       let result  =   json["data"] as? [String : Any],
                       let message = result["info"] as? String {
                        
                        if type == .event,
                           let subStatus = result["status"] as? Int,
                           subStatus == 2 {
                            // Send ticket to user via mail
                            Data.shared().sendMail(["id"  : order,
                                                    "cat" : type.rawValue],
                                                   inVC: vc)
                        } else {
                            let alert = UIAlertController(title: "État du paiement Lydia",
                                                          message: message,
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                            if let subStatus = result["status"] as? Int,
                               subStatus != 0, subStatus != 2, // not: cash or paid
                               canOpenLydiaApp {
                                let lydiaAction = UIAlertAction(title: "Ouvrir Lydia", style: .default) { _ in
                                    openLydiaApp()
                                }
                                alert.addAction(lydiaAction)
                                alert.preferredAction = lydiaAction
                            }
                            vc?.present(alert, animated: true)
                        }
                        
                    } else {
                        
                        let errorMessage  = json["cause"] as? String ?? "Erreur inconnue… ¯\\_(ツ)_/¯"
                        let alert = UIAlertController(title: "Impossible de vérifier l'état du paiement Lydia",
                                                      message: errorMessage + "\nParlez-en à un membre du BDE.",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        vc?.present(alert, animated: true)
                    }
                }
            }
                        
        }, failure: { error, data in
            
            alert.dismiss(animated: true) {
                
                let errorMessage = error?.localizedDescription ?? "Vous n'êtes pas connecté à Internet."
                let alert = UIAlertController(title: "Impossible de vérifier l'état du paiement Lydia",
                                              message: errorMessage + "\nSi le problème persiste, parlez-en à un membre du BDE.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                vc?.present(alert, animated: true)
            }
        })
    }
    
    
    @objc static func startRequestObjCBridge(order: Int, type: String) {
        
        guard let category = Category(rawValue: type)
            else { return }
        
        Lydia.startRequest(for: order, type: category, viewController: nil)
    }
    
    static func startRequest(for order: Int, type: Category,
                             viewController: UIViewController?) {
        
        var vc = viewController
        if vc == nil,
           let window = UIApplication.shared.delegate?.window {
            vc = window?.rootViewController
        }
        guard vc != nil else { return }
        
        guard JNKeychain.loadValue(forKey: KeychainKey.phone) == nil else {
            Lydia.sendRequest(for: order, type: type, viewController: vc)
            return
        }
        
        var message = "Votre numéro de téléphone portable est utilisé par Lydia afin de lier la commande à votre compte. Il n'est pas stocké sur nos serveurs."
        if Data.shared().tempPhone != nil {
            message += "\n\nRéessayez, numéro incorrect."
        }
        
        let alert = UIAlertController(title: "Paiement par Lydia",
                                      message: message,
                                      preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder  = "0601234242"
            textField.keyboardType = .phonePad
            textField.delegate     = Data.shared()
            textField.text         = Data.shared().tempPhone
        }
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        let confirmAction = UIAlertAction(title: "Payer maintenant", style: .default) { _ in
            Lydia.sendRequest(for: order, type: type, viewController: vc)
        }
        alert.addAction(confirmAction)
        alert.preferredAction = confirmAction
        
        vc!.present(alert, animated: true)
    }
    
    
    private static func sendRequest(for order: Int, type: Category,
                                    viewController: UIViewController?) {
        
        var vc = viewController
        if vc == nil,
           let window = UIApplication.shared.delegate?.window {
            vc = window?.rootViewController
        }
        
        guard let token = JNKeychain.loadValue(forKey: KeychainKey.token) as? String else {
            
            let alert = UIAlertController(title: "Vous n'êtes pas connecté",
                                          message: "Impossible de payer une commande Lydia.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            vc?.present(alert, animated: true)
            return
        }
        
        var phone = JNKeychain.loadValue(forKey: KeychainKey.phone) as? String
        if phone == nil {
            
            guard let num = Data.shared().tempPhone,
                  num.range(of: "^((\\+|00)33\\s?|0)[679](\\s?\\d{2}){4}$",
                            options: String.CompareOptions.regularExpression) != nil else {
                            
                // Ask phone number again
                Lydia.startRequest(for: order, type: type, viewController: vc)
                return;
            }
                
            phone = num
            Data.shared().tempPhone = nil
            JNKeychain.saveValue(num, forKey: KeychainKey.phone)
        }
        guard let phoneB64 = phone?.data(using: .utf8)?.base64EncodedString()
            else { return }
        
        let alert = UIAlertController(title: "Demande de paiement Lydia",
                                      message: "Veuillez patienter…",
                                      preferredStyle: .alert)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30)) { [weak alert] in
            alert?.dismiss(animated: true)
        }
        vc?.present(alert, animated: true)
        
        API.request(.lydiaAsk, post: ["idcmd"     : String(order),
                                      "cat_order" : type.rawValue,
                                      "phone"     : phoneB64,
                                      "os"        : "IOS"],
                    authentication: token,
                    completed: { data in
            
            alert.dismiss(animated: true) {
                
                if let raw  = try? JSONSerialization.jsonObject(with: data),
                   let json = raw as? [String : Any] {
                    
                    Lydia.openLydia(requestResponse: json, viewController: vc)
                } else {
                    let alert = UIAlertController(title: "Erreur paiement Lydia",
                                                  message: "Impossible d'interpréter la requête de paiement.\nSi le problème persiste, parlez-en à un membre du BDE.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    vc?.present(alert, animated: true)
                }
            }
                        
        }, failure: { error, data in
            
            alert.dismiss(animated: true) {
                
                let alert = UIAlertController(title: "Erreur paiement Lydia",
                                              message: "Impossible d'envoyer la requête de paiement.\nSi le problème persiste, parlez-en à un membre du BDE.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                vc?.present(alert, animated: true)
            }
        })
    }
    
    
    private static var canOpenLydiaApp: Bool {
        
        return UIApplication.shared.canOpenURL(Lydia.appURL)
    }
    
    private static func openLydiaApp() {

        if canOpenLydiaApp {
            UIApplication.shared.openURL(Lydia.appURL)
        }
    }
    
    
    private static func openLydia(requestResponse json: [String : Any],
                                  viewController: UIViewController?) {
        
        var vc = viewController
        if vc == nil,
           let window = UIApplication.shared.delegate?.window {
            vc = window?.rootViewController
        }
        
        var errorMessage = json["cause"] as? String ?? "Raison inconnue 😿"
        
        if let status = json["status"] as? Int {
            if status == 1 {
                errorMessage = "Impossible d'ouvrir l'app ou le site Lydia."
                if let result = json["data"] as? [String : Any],
                   let intent = result["lydia_intent"] as? String,
                   let url    = result["lydia_url"]    as? String,
                   intent != "", url != "" {
                    
                    let alert = UIAlertController(title: "Demande de paiement Lydia",
                                                  message: "Veuillez patienter…",
                                                  preferredStyle: .alert)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak alert] in
                        alert?.dismiss(animated: true)
                    }
                    vc?.present(alert, animated: true)
                    
                    Data.shared().alertRedir = alert
                    
                    if let appLydia = URL(string: intent),
                       UIApplication.shared.canOpenURL(appLydia) {
                        UIApplication.shared.openURL(appLydia)
                    } else if let siteLydia = URL(string: url) {
                        UIApplication.shared.openURL(siteLydia)
                    }
                    
                    return
                }
            } else if status == -2 {
                JNKeychain.deleteValue(forKey: KeychainKey.phone)
            } else if status <= -8000 {  // Lydia error
                errorMessage += "\nCode erreur : \(status)"
            }
        }
        
        let alert = UIAlertController(title: "Erreur Lydia",
                                      message: "Demande de paiement annulée.\n" + errorMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        vc?.present(alert, animated: true)
    }
    
}
