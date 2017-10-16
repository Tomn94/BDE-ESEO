//
//  OrderCartTVC.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 16/10/2017.
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

struct CafetSendOrderResult: APIResult, Decodable {
    
    let success: Bool
    
    let order: CafetSendOrder
    
    struct CafetSendOrder: Decodable {
        let price: Double
        let pict: String
        let idstr: String
        let idcmd: Int
        let text: String
        let lydia_enabled: Bool
    }
    
}

class OrderCartTVC: UITableViewController {
    
    @objc static func sendCart(_ cart: String, instructions: String?,
                               viewController: UITableViewController) {
        
        guard let cafetToken = Data.shared().cafetToken,
              let  userToken = JNKeychain.loadValue(forKey: KeychainKey.token) as? String
            else { return }
        
        API.request(.sendOrder,
                    post: ["token"        : cafetToken,
                           "data"         : cart,
                           "instructions" : instructions ?? ""],
                    authentication: userToken,
                    completed: { data in
            
            guard let result = try? JSONDecoder().decode(CafetSendOrderResult.self, from: data),
                  result.success else {
                    
                Data.shared().cafetCmdEnCours = false
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("updPanier"), object: nil)
                    viewController.tableView.reloadData()
                }
                
                API.handleFailure(data: data, mode: .presentFetchedMessage(viewController),
                                  defaultMessage: "Le serveur n'arrive pas à décoder votre panier (c'est un panier très compliqué !).\nVotre commande a peut-être été déjà validée.\nMerci de venir nous voir au comptoir.")
                return
            }
            
            let cbPaymentAvailable = result.order.lydia_enabled &&
                                     Lydia.isValid(price: result.order.price)
            
            let alert = UIAlertController(title: cbPaymentAvailable
                                                   ? "Commande validée !\nComment voulez-vous la payer ?"
                                                   : "Commande validée !",
                                          message: "Celle-ci est en cours de préparation et sera disponible après avoir payé.\nVous serez averti d'une notification (si activées) quand elle vous attendra au comptoir.\nBon appétit ! 👌🏼",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: cbPaymentAvailable
                                                   ? "Payer plus tard au comptoir 💰" : "Merci !",
                                          style: .cancel) { _ in
                
                NotificationCenter.default.post(name: Notification.Name("cmdValide"), object: nil)
            })
            if cbPaymentAvailable {
                let payNowAction = UIAlertAction(title: "Payer immédiatement (Lydia 💳)",
                                                 style: .default) { _ in
                    
                    NotificationCenter.default.post(name: Notification.Name("cmdValideLydia"), object: nil,
                                                    userInfo: ["idcmd"    : result.order.idcmd,
                                                               "catOrder" : "CAFET"])
                }
                alert.addAction(payNowAction)
                alert.preferredAction = payNowAction
            }
            viewController.present(alert, animated: true)
                        
        }, failure: { _, data in
            
            Data.shared().cafetCmdEnCours = false
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("updPanier"), object: nil)
                viewController.tableView.reloadData()
            }
            
            API.handleFailure(data: data, mode: .presentFetchedMessage(viewController),
                              defaultMessage: "Impossible de se connecter au serveur.\nSi le problème persiste, vous pouvez toujours venir commander au comptoir.")
            
        })
    }
    
}
