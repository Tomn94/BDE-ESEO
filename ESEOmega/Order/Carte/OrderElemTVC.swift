//
//  OrderElemTVC.swift
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

class OrderElemTVC: UITableViewController {
    
    var text: UILabel
    
    var data: CafetMenu
    
    required init(style: UITableView.Style, menu: CafetMenu) {
        
        text = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        self.data = menu
        
        super.init(style: style)
        
        self.title = menu.name
        self.tableView.reloadData()
        
        
        text.autoresizingMask = .flexibleWidth
        text.font = UIFont.systemFont(ofSize: 11)
        text.textColor = UIColor(white: 0.95, alpha: 1)
        
        self.setToolbarItems([UIBarButtonItem(customView: text), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "Valider ce menu", style: .done, target: self, action: #selector(valider))], animated: true)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newSandwich(_:)), name: NSNotification.Name(rawValue: "elemMenuSelec"), object: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.toolbar.barTintColor = UINavigationBar.appearance().barTintColor
        self.navigationController?.toolbar.tintColor = UINavigationBar.appearance().tintColor
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.updSupplement()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func updSupplement() {
        var supplement: Double = 0
        for sandwich in data.selectedMainElements {
            supplement += sandwich.priceSupplement()
        }
        
        text.text = supplement > 0 ? String(format: "Supplément : + %.2f €", supplement).replacingOccurrences(of: ".", with: ",") : ""
    }
    
    @objc func newSandwich(_ notification: Notification) {
        guard let mainElement: CafetMainElement = notification.userInfo?["mainElement"] as? CafetMainElement else { return }
        
        data.selectedMainElements.append(mainElement)
        self.tableView.reloadData()
    }
    
    @objc func valider() {
        var count = 0
        for subElement in data.selectedSubElements {
            count += subElement.countsFor
        }
        
        if ((data.selectedMainElements).count < data.nbMainElements) {
            let alert = UIAlertController(title: "Vous n'avez pas sélectionné tous vos éléments principaux", message: String(format: "Vous devez choisir %d élément%@ parmi ceux présentés pour ce menu.", data.nbMainElements, data.nbMainElements > 1 ? "s" : ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else if (count < data.nbSubElements) {
            let alert = UIAlertController(title: "Vous n'avez pas sélectionné tous vos éléments secondaires", message: String(format: "Vous devez choisir %d élément%@ parmi ceux présentés pour ce menu.", data.nbSubElements, data.nbSubElements > 1 ? "s" : ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            DataStore.shared.cafetPanier?.selectedMenus.append(data)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updPanier"), object: nil, userInfo: nil)
            self.navigationController?.popViewController(animated: true)
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(sendNotif), userInfo: nil, repeats: false)
        }
        
    }
    
    @objc func sendNotif() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showMessagePanier"), object: nil, userInfo: ["nom": data.name])
    }

    
}
extension OrderElemTVC {
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {

        return data.nbMainElements + 1
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return section == data.nbMainElements ? data.availableSubElements.count : 1
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if (section < data.nbMainElements) {
            var ordinal: String = ""
            
            if (section == 0 && data.nbMainElements >= 1) {
                ordinal = "ᴱᴿ"
            } else if (section == 1 && data.nbMainElements >= 2) {
                ordinal = "ᴺᴰ"
            } else if (data.nbMainElements >= section + 1) {
                ordinal = "ᴱ"
            }
            return data.nbMainElements > 1 ? String(format: "Choisissez votre %d%@ élément principal", section + 1, ordinal) : "Choisissez votre élément secondaire"
        }
        else if (section == data.nbMainElements && data.nbSubElements > 0) {
            return data.nbSubElements > 1 ? String(format: "Choisissez vos %d éléments secondaires", data.nbSubElements) : "Choisissez votre élément secondaire"
        }
        
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellID = "orderDetailMenuCell"
        let cellID2 = "orderDetailMenuBtnCell"
        
        let section = indexPath.section
        
        if section == data.nbMainElements { // Dernière section -> Celle des éléments secondaires

            let cell = tableView.dequeueReusableCell(withIdentifier: cellID) ?? {
                return UITableViewCell(style: .default, reuseIdentifier: cellID)
                }()
            
            let subElement = data.availableSubElements[indexPath.row]
            
            cell.textLabel?.text = subElement.name
            cell.textLabel?.textColor = .black
            cell.textLabel?.textAlignment = .left
            
            if (data.selectedSubElements).contains(subElement) {
                cell.accessoryType = .checkmark
            }
            
            return cell

        } else if (data.selectedMainElements).indices.contains(section) { // Si un élément principal a déja été selectionné
            
            let mainElement = (data.selectedMainElements)[section]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cellID) ?? {
                return UITableViewCell(style: .default, reuseIdentifier: cellID)
                }()
            
            cell.textLabel?.text = mainElement.name
            cell.textLabel?.textColor = .black
            cell.textLabel?.textAlignment = .left
            cell.accessoryType = .detailButton
            
            if (mainElement.priceSupplement() > 0) {
                cell.detailTextLabel?.text = String(format: "+ %.2f €", mainElement.priceSupplement()).replacingOccurrences(of: ".", with: ",")
            }
            
            return cell
            
        } else { // Si un élément principal n'a pas été selectionné
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cellID2) ?? {
                return UITableViewCell(style: .default, reuseIdentifier: cellID2)
                }()
            
            cell.textLabel?.text = "Choisir …"
            cell.textLabel?.textColor = tableView.tintColor
            cell.textLabel?.textAlignment = .center
            cell.accessoryType = .none
            
            return cell
            
            
        }

        
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section
        
        if (section < data.nbMainElements) { // Elements principaux
            
            let dialog = UIAlertController(title: "Choix de l'élément principal", message: self.tableView(tableView, titleForHeaderInSection: section)?.appending(" parmi ceux-ci :"), preferredStyle: .alert)
            
            for mainElement in data.availableMainElements {
                
                var title = ""
                
                if (data.selectedMainElements).indices.contains(indexPath.row) {
                    title = "Modifier : "
                }
                
                title += mainElement.name
                
                dialog.addAction(UIAlertAction(title: title, style: .default, handler: {(action: UIAlertAction) in
                    
                    var detail = OrderIngredTVC(style: .grouped, mainElement: mainElement)
                    
                    if (self.data.selectedMainElements).indices.contains(indexPath.row) {
                        
                        detail = OrderIngredTVC(style: .grouped, mainElement: (self.data.selectedMainElements)[indexPath.row])
                    }
                    
                    self.navigationController?.pushViewController(detail, animated: true)
                }))
                
            }
            
            dialog.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
            self.present(dialog, animated: true, completion: nil)
            
        } else if (section == data.nbMainElements) { // Elements secondaires
            
            if data.availableSubElements.indices.contains(indexPath.row) {
                
                let subElement = data.availableSubElements[indexPath.row]
                
                if let index = (data.selectedSubElements).firstIndex(of: subElement){
                    data.selectedSubElements.remove(at: index)
                    tableView.reloadData()
                } else {
                    
                    var nbrElements = subElement.countsFor
                    for sEl in (data.selectedSubElements) {
                        nbrElements += sEl.countsFor
                    }
                    
                    if (nbrElements > data.nbSubElements) {
                        
                        let alert = UIAlertController(title: "Vous avez sélectionné trop d'éléments pour ce menu", message: String(format: "Vous ne pouvez sélectionner que %d élément%@ maximum, désélectionnez-%@ ou choisissez un autre menu.", data.nbSubElements, data.nbSubElements > 1 ? "s" : "", data.nbSubElements > 1 ? "en" : "le"), preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        
                        self.present(alert, animated: true, completion: nil)
                        
                    } else {
                        data.selectedSubElements.append(subElement)
                        
                    }
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }

}
