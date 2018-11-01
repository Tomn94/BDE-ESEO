//
//  OrderPanierTVC.swift
//  BDE-ESEO
//
//  Created by Benjamin Gondange on 01/11/2018.
//  Copyright © 2018 Benjamin Gondange

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
import LocalAuthentication

class OrderPanierTVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        
        self.rotateInsets()
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotateInsets), name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableViewData), name: NSNotification.Name(rawValue: "updPanier"), object: nil)
    }

    @objc func rotateInsets() {
        var dec: CGFloat = 44 + (self.navigationController?.navigationBar.frame.size.height)! + ((UIDevice.current.userInterfaceIdiom == .pad) ? 0 : UIApplication.shared.statusBarFrame.size.height)
        
        if #available(iOS 11, *) {
            dec = 44
        }
        
        self.tableView.contentInset = UIEdgeInsets(top: dec, left: 0, bottom: 0, right: 0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
        
        self.tableView.reloadEmptyDataSet()
    }
    
    func lancerCommande() {
        let alert = UIAlertController(title: "Voulez-vous ajouter un commentaire ?", message: "Vous pouvez taper ci-dessous quelques indications pour votre commande.", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = "Consignes, …"
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.delegate = self
        })
        
        let confirmAction = UIAlertAction(title: "Finaliser la commande", style: .default, handler: {(action: UIAlertAction) in
            let alert2: UIAlertController = UIAlertController(title: "Valider la commande ?", message: "En validant, vous vous engagez à payer et récupérer votre repas au comptoir de la cafet aujourd'hui aux horaires d'ouvertures.\n☝🏼\nSi ce n'est pas le cas, il vous sera impossible de passer une nouvelle commande dès demain.", preferredStyle: .alert)
            alert2.addAction(UIAlertAction(title: "Je confirme, j'ai faim !", style: .destructive, handler: {(action: UIAlertAction) in
                
                NotificationCenter.default.post(name: Notification.Name("updPanier"), object: nil)
                let context = LAContext()
                context.localizedFallbackTitle = ""
                var error: NSError?
                
                let policy: LAPolicy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
                
                if (context.canEvaluatePolicy(policy, error: &error)) {
                    context.evaluatePolicy(policy, localizedReason: "Valide l'envoi de votre commande", reply: {(success: Bool, error: Error?) in
                        if success {
                            DispatchQueue.main.async {
                                self.sendPanier()
                            }
                        } else {
                            DataStore.shared.cmdEnCours = false
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                        
                    })
                } else {
                    self.sendPanier()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
            self.present(alert2, animated: true, completion: nil)
        })
        
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
        
        alert.preferredAction = confirmAction
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func sendPanier() {
        self.tableView.reloadData()
        
        let panier = DataStore.shared.cafetPanier
        
        if panier?.selectedItems.count == 0 {
            DataStore.shared.cmdEnCours = false
            NotificationCenter.default.post(name: NSNotification.Name("updPanier"), object: nil)
            
            let alert = UIAlertController(title: "Hm… 🌚", message: "Impossible de valider un panier vide. Ajoutez quelques éléments de la carte d'abord.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.tableView.reloadData()
            return
        }
        
        guard let token = Keychain.string(for: .token)
            else { return }
        
        
        
        let orderData = panier!.orderData
        
        guard let panierJSON = try? String(data: JSONEncoder().encode(orderData), encoding: .utf8) else { return }
        
        API.request(.order, post: ["token": (panier?.token)!, "instructions": (panier?.instructions)!, "data": panierJSON!], authentication: token, completed: {data in
            
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = CafetOrder.dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            guard let result = try? decoder.decode(CafetOrderResult.self, from: data),
                result.success else {
                    
                    DataStore.shared.cmdEnCours = false
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("updPanier"), object: nil)
                        self.tableView.reloadData()
                    }
                    
                    API.handleFailure(data: data, mode: .presentFetchedMessage(self),
                                      defaultMessage: "Le serveur n'arrive pas à décoder votre panier (c'est un panier très compliqué !).\nVotre commande a peut-être été déjà validée.\nMerci de venir nous voir au comptoir.")
                    return
            }
            
            
            let alert = UIAlertController(title: "Commande validée !",
                                          message: "Celle-ci est en cours de préparation et sera disponible après avoir payé.\nVous serez averti d'une notification (si activées) quand elle vous attendra au comptoir.\nBon appétit ! 👌🏼",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Merci !",
                                          style: .cancel) { _ in
                                            
                                            NotificationCenter.default.post(name: Notification.Name("cmdValide"), object: nil)
            })

            self.present(alert, animated: true)
        }, failure: {_, data in
            DataStore.shared.cmdEnCours = false
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("updPanier"), object: nil)
                self.tableView.reloadData()
            }
            
            API.handleFailure(data: data, mode: .presentFetchedMessage(self),
                              defaultMessage: "Impossible de se connecter au serveur.\nSi le problème persiste, vous pouvez toujours venir commander au comptoir.")
        })
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if (DataStore.shared.cafetPanier?.selectedItems.count ?? 0 > 0) {
            return 3 // Panier + Total + Valider
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section > 0 {
            return 1
        }
        
        return DataStore.shared.cafetPanier?.selectedItems.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section > 0) {
            return 44
        }
        
        guard let cellText = DataStore.shared.cafetPanier?.selectedItems[indexPath.row].details else { return 44 }
        let cellFont = UIFont.systemFont(ofSize: 11)
        let attributedText = NSAttributedString(string: cellText, attributes: [NSAttributedString.Key.font: cellFont])
        
        let rect: CGRect = attributedText.boundingRect(with: CGSize(width: tableView.bounds.size.width - ((self.tableView.isEditing) ? 140 : 100), height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        
        return max(44, rect.size.height + 30)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            let cell: OrderItemCell = tableView.dequeueReusableCell(withIdentifier: "orderItemCell", for: indexPath) as! OrderItemCell
            
            let element: CafetElement = (DataStore.shared.cafetPanier?.selectedItems[indexPath.row])!
            
            cell.titre.text = element.name
            cell.detail.text = element.details
            cell.prix.text = String(format: "%.2f €", element.price).replacingOccurrences(of: ".", with: ",")
            
            return cell
            
        } else if (indexPath.section == 1) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "orderTotalCell", for: indexPath)
            cell.detailTextLabel?.text = String(format: "%.2f €", (DataStore.shared.cafetPanier?.price)!).replacingOccurrences(of: ".", with: ",")
            cell.textLabel?.text = self.tableView.isEditing ? "Vider tout le panier" : "Total"
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "orderConfirmCell", for: indexPath)
            if DataStore.shared.cmdEnCours {
                
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (!DataStore.shared.cmdEnCours && indexPath.section == 2) {
            self.lancerCommande()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if (self.tableView.numberOfSections > 0) {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 0, section: 2)], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section < 2 && !DataStore.shared.cmdEnCours
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            if (indexPath.section == 0) {
                DataStore.shared.cafetPanier?.removeElement(at: indexPath.row)
            } else if (indexPath.section == 1) {
                DataStore.shared.cafetPanier?.vider()
            }
            if ((DataStore.shared.cafetPanier?.selectedItems.count)! < 1) {
                self.setEditing(false, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Votre panier"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }
    
    @objc func reloadTableViewData() {
        self.tableView.setEditing(false, animated: true)
        self.tableView.reloadData()
        self.tableView.reloadEmptyDataSet()
    }
    
}

extension OrderPanierTVC: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: arc4random_uniform(2) == 1 ? "cafetVide1" : "cafetVide2")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "Vous n'avez encore rien ajouté à votre panier !"
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "Sélectionnez des éléments dans l'onglet Carte."
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.paragraphStyle: paragraph]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
}

extension OrderPanierTVC: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let nsString = textField.text as NSString?
        let proposedNewString: String = (nsString?.replacingCharacters(in: range, with: string))!
        let result = proposedNewString.trimmingCharacters(in: NSCharacterSet.whitespaces)
        let ok = result.count <= 100
        
        if (ok) {
            DataStore.shared.cafetPanier?.instructions = result
        }
        return ok
    }
    
}
