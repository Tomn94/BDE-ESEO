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
              let  token = JNKeychain.loadValue(forKey: KeychainKey.token) as? String
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
            
            alert.dismiss(animated: true, completion: {
                
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
                                                   inVC: vc!)
                        } else {
                            let alert = UIAlertController(title: "État du paiement Lydia",
                                                          message: message,
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
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
            })
                        
        }, failure: { error, data in
            
            alert.dismiss(animated: true, completion: {
                
                let errorMessage = error?.localizedDescription ?? "Vous n'êtes pas connecté à Internet."
                let alert = UIAlertController(title: "Impossible de vérifier l'état du paiement Lydia",
                                              message: errorMessage + "\nSi le problème persiste, parlez-en à un membre du BDE.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                vc?.present(alert, animated: true)
            })
        })
    }
    
}
