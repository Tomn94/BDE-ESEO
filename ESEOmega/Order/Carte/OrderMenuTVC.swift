//
//  OderMenuTVC.swift
//  BDE-ESEO
//
//  Created by Benjamin Gondange on 31/10/2018.
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

class OrderMenuTVC: UITableViewController {

    var data: CafetInfo? = nil
    var statut: UIView? = nil
    var label: UILabel? = nil
    var timerMessage: Timer? = nil
    let pvcHolder: UIView? = UIView()
    
    let NBR_MAX_MENUS = 2
    let NBR_MAX_PANIER = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let cData = DataStore.shared.cafetData else {
            return
        }
        data = cData
        self.tableView.separatorStyle = .none
        
        var topInset: CGFloat = 0
        if #available(iOS 11.0, *) {
            topInset = self.view.safeAreaInsets.top
        }
        
        statut = UIView(frame: CGRect(x: 0, y: topInset, width: self.view.bounds.size.width, height: 20))
        statut?.backgroundColor = UIColor(red: 0.447, green: 0.627, blue: 0.000, alpha: 1.000)
        label = UILabel(frame: (statut?.bounds)!)
        label?.autoresizingMask = .flexibleWidth
        label?.text = "Ajouté au panier !"
        label?.textColor = .white
        label?.textAlignment = .center
        label?.font = UIFont.systemFont(ofSize: 12)
        statut?.addSubview(label!)
        let tapRecon = UITapGestureRecognizer(target: self, action: #selector(masquerMessage))
        self.pvcHolder!.addGestureRecognizer(tapRecon)
        self.pvcHolder!.addSubview(statut!)
        statut?.alpha = 0
        self.rotateInsets()
        
        let ctr: NotificationCenter = NotificationCenter.default
        
        ctr.addObserver(self, selector: #selector(afficherMessage(notif:)), name: NSNotification.Name(rawValue: "showMessagePanier"), object: nil)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.rotateInsets()
    }
    
    func rotateInsets() {
        self.masquerMessageQuick()
        
        let toolbarHeight = CGFloat(44)
        
        if #available(iOS 11, *) {
             self.additionalSafeAreaInsets = UIEdgeInsets(top: toolbarHeight, left: 0, bottom: 0, right: 0)
        } else {
            let dec = toolbarHeight + (self.navigationController?.navigationBar.frame.size.height)! + ((UIDevice.current.userInterfaceIdiom == .pad) ? 0 : UIApplication.shared.statusBarFrame.size.height)
            self.tableView.contentInset = UIEdgeInsets(top: dec, left: 0, bottom: 0, right: 0)
            self.tableView.scrollIndicatorInsets = self.tableView.contentInset
        }
        
    }

}

extension OrderMenuTVC {
    func choseMenu(menu: CafetMenu) {
        let detail = OrderElemTVC(style: .grouped, menu: menu)
        self.navigationController?.pushViewController(detail, animated: true)
    }
    
    func chooseIngredientsFor(element: CafetMainElement) {
        let detail = OrderIngredTVC(style: .grouped, mainElement: element, inMenu: false)
        self.navigationController?.pushViewController(detail, animated: true)
    }
}

extension OrderMenuTVC {
    // MARK: - TableView Delegates
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data!.categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OrderMenuCell = tableView.dequeueReusableCell(withIdentifier: "orderMenuCell", for: indexPath) as! OrderMenuCell
        
        let donnees = data!.categories[indexPath.row]
        cell.nom.text = donnees.name
        cell.detail.text = donnees.description
        cell.prix.text = ""
        
        cell.nom.layer.shadowRadius = 4
        cell.nom.layer.shadowColor = UIColor.black.cgColor
        cell.nom.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.nom.layer.shadowOpacity = 1
        cell.detail.layer.shadowRadius = 3
        cell.detail.layer.shadowColor = UIColor.black.cgColor
        cell.detail.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.detail.layer.shadowOpacity = 1
        cell.prix.layer.shadowRadius = 3
        cell.prix.layer.shadowColor = UIColor.black.cgColor
        cell.prix.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.prix.layer.shadowOpacity = 1
        
        cell.back.sd_setImage(with: URL(string: donnees.imgUrl))
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if Data.shared()?.cafetCmdEnCours ?? false {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        let category = data!.categories[indexPath.row]
        
        if (DataStore.shared.cafetPanier?.selectedItems.count)! >= NBR_MAX_PANIER {
            let alert = UIAlertController(title: "Votre panier est plein", message: String(format: "Vous ne pouvez avoir que Md objets maximum dans votre panier.\nAllez dans Panier puis appuyez sur modifier pour en retirer.", NBR_MAX_PANIER), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if category.name == "Menus" {
            if (DataStore.shared.cafetPanier?.selectedMenus.count ?? 0 >= NBR_MAX_MENUS) {
                let alert = UIAlertController(title: "Vous avez encore faim ?", message: String(format: "Vous ne pouvez avoir que %d menus maximum dans votre panier. Allez dans Panier puis appuyez sur Modifier pour en retirer.\nCependant vous pouvez toujours ajouter d'autres éléments.", NBR_MAX_MENUS), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                return
            }
            
            let dialog = UIAlertController(title: "Nos menus", message: "Pour commencer, choisissez un menu parmi ceux-ci :", preferredStyle: .alert)
            for menu in data!.menus {
                var titre = menu.name + String(format: " (%.2f €", menu.price).replacingOccurrences(of: ".", with: ",")
                
                if (menu.nbMainElements > 0 || menu.nbSubElements > 0) {
                    titre = titre + " · "
                }
                if menu.nbMainElements > 0 {
                    titre = titre + String(format: "%d🍔", menu.nbMainElements)
                }
                if menu.nbSubElements > 0 {
                    if menu.nbMainElements > 0 {
                        titre = titre + " + "
                    }
                    titre = titre + String(format: "%d🍫", menu.nbSubElements)
                }
                titre = titre + ")"
                dialog.addAction(UIAlertAction(title: titre, style: .default, handler: {(action: UIAlertAction) -> Void in
                    self.choseMenu(menu: menu)
                }))
            }
            dialog.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
            self.present(dialog, animated: true, completion: nil)
            
        } else {
            let dialog = UIAlertController(title: category.name, message: "Choisissez un élément parmi ceux-ci :", preferredStyle: .alert)
            
            let elements = data!.allElements
            
            for element in elements {
                if (element.category == category.position && element.available) {
                    dialog.addAction(UIAlertAction(title: String(format: "%@ (%.2f €)", element.name, element.price).replacingOccurrences(of: ".", with: ","), style: .default, handler: {(action: UIAlertAction) in
                        if let mainElement = element as? CafetMainElement {
                            self.chooseIngredientsFor(element: mainElement)
                        } else if let subElement = element as? CafetSubElement {
                            DataStore.shared.cafetPanier?.selectedSubElements.append(subElement)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updPanier"), object: nil, userInfo: nil)
                            self.afficher(message: subElement.name)
                        }
                    }))
                }
            }
            
            if (dialog.actions.count < 2) {
                dialog.message = ""
            }
            
            dialog.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
            self.present(dialog, animated: true, completion: nil)
            
            tableView.deselectRow(at: indexPath, animated: true)
            
        }
    }
}

extension OrderMenuTVC {
    //MARK: Messages
    
    func afficher(message: String) {
        timerMessage?.invalidate()
        self.majFrameMessage()
        label!.text = String(format: "Ajouté au panier : %@", message)
        
        let animation = CATransition()
        animation.delegate = self as? CAAnimationDelegate
        animation.duration = 0.6
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = .init(rawValue: "cube")
        animation.subtype = CATransitionSubtype.fromBottom
        statut?.layer.add(animation, forKey: nil)
        
        statut?.alpha = 1
        
        timerMessage = Timer(timeInterval: 2, target: self, selector: #selector(masquerMessage), userInfo: nil, repeats: false)
        
        if #available(iOS 10.0, *) {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
        
    }
    
    @objc func afficherMessage(notif: Notification?) {
        guard let unwraped = notif else {
            return
        }
        if (unwraped.userInfo == nil) {
            return
        }
        
        self.afficher(message: unwraped.userInfo!["nom"] as! String)
        
    }
    
    @objc func masquerMessage() {
        timerMessage?.invalidate()
        
        let animation = CATransition()
        animation.duration = 0.6
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = .init(rawValue: "cube")
        animation.subtype = CATransitionSubtype.fromTop
        statut?.layer.add(animation, forKey: nil)
        
        statut?.alpha = 0
    }
    
    @objc func masquerMessageQuick() {
        timerMessage?.invalidate()
        UIView.animate(withDuration: 0.2, animations: {() -> Void in
            self.statut!.alpha = 0
        })
    }
    
    @objc func majFrameMessage() {
        var topInset = CGFloat(integerLiteral: 0)
        if #available(iOS 11.0, *) {
            topInset = self.view.safeAreaInsets.top
        }
        
        statut?.frame = CGRect(x: 0, y: topInset, width: self.view.bounds.size.width, height: 20)
        label!.frame = (statut?.bounds)!
    }
}
