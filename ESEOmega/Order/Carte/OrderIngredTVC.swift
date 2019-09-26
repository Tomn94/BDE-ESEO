//
//  OrderIngredTVC.swift
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

class OrderIngredTVC: UITableViewController {

    var mainElement: CafetMainElement
    
    var text: UILabel
    
    var inMenu = true
    
    required init(style: UITableView.Style, mainElement: CafetMainElement, inMenu: Bool = true) {
        
        self.mainElement = mainElement
        self.text = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        self.inMenu = inMenu
        text.autoresizingMask = .flexibleWidth
        text.font = UIFont.systemFont(ofSize: 11)
        text.textColor = UIColor(white: 0.95, alpha: 1)
        
        super.init(style: style)
        
        self.setToolbarItems([UIBarButtonItem(customView: text), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "Valider", style: .done, target: self, action: #selector(valider))], animated: true)
        
        self.tableView.reloadData()
        self.title = mainElement.name
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    func updSupplement() {
        let supp = mainElement.priceSupplement()
        text.text = supp > 0 ? String(format: "Supplément : %.2f €", supp).replacingOccurrences(of: ".", with: ",") : ""
    }

    @objc func valider() {
        
        if inMenu {
            let userInfo: [String: CafetMainElement] = ["mainElement": mainElement]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "elemMenuSelec"), object: nil, userInfo: userInfo)
            self.navigationController?.popViewController(animated: true)
        } else {
            DataStore.shared.cafetPanier?.selectedMainElements.append(mainElement)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updPanier"), object: nil, userInfo: nil)
            self.navigationController?.popViewController(animated: true)
        }
        
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let c = mainElement.availableIngredients.count
        return c
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(format: "Vous pouvez ajouer %d ingrédient%@ de votre choix. Au delà, tout supplément est facturé.", mainElement.nbIngredients, mainElement.nbIngredients > 1 ? "s" : "")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = "orderDetailElemCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) ?? {
            return UITableViewCell(style: .default, reuseIdentifier: cellID)
            }()
        
        cell.textLabel?.text = mainElement.availableIngredients[indexPath.row].name
        
        let ids = mainElement.selectedIngredients.compactMap { $0.ID }
        
        let currentId = mainElement.availableIngredients[indexPath.row].ID
        
        if ((ids.contains(currentId))) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let index = mainElement.selectedIngredients.firstIndex(of: mainElement.availableIngredients[indexPath.row]) {
            mainElement.selectedIngredients.remove(at: index)
        } else {
            mainElement.selectedIngredients.append(mainElement.availableIngredients[indexPath.row])
        }
        self.updSupplement()
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }
    

}
