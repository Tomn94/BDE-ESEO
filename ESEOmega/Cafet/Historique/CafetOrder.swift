//
//  CafetOrder.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 08/10/2017.
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

/// Describes an order requested by the user at the school cafétéria
class CafetOrder: Equatable, Codable {
    
    /// Unique ID
    let ID: Int
    
    /// Modulo applied on `idcmd`, usually written after `strcmd`
    let modID: Int
    
    /// Cooking status
    let status: Status
    
    /// Date for status 0 (Token has been requested)
    let startTime: Date
    
    /// Date for status 1 (User has completed his order)
    let completeTime: Date?
    
    /// Date for status 2 (Kitchen has taken the order)
    let takenTime: Date?
    
    /// Date for status 3 (Order is ready)
    let readyTime: Date?
    
    /// Date for status 4 (Order is finished)
    let endTime: Date?
    
    /// Generated text describing the order
    let friendlyText: String
    
    /// Client requests concerning their food/delivery
    let instructions: String?
    
    /// Price of the whole order
    let price: Double
    
    /// Whether the order is paid
    let paid: Bool
    
    /// Order client's username
    let username: String?
    
    /// Order client's full name
    let clientName: String?
    
    /// Where the order is from
    let source: String?
    
    /// Order string token
    let token: String?
    
    /// Order json data
    let order: String?
    
    // MARK: Available after requesting details
    
    /// Category illustration
    let imgurl: String?
    
    static let dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    /// Order status and associated raw JSON value
    enum Status: Int, Codable {
        /// Initial state
        case created = 0
        /// User has completed his order
        case complete     = 1
        /// Kitchen is has taken the order, started preparing
        case preparing      = 2
        /// Kitchen has finished to prepare the order. It is waiting for the user to take it
        case ready   = 3
        /// The user has taken his order
        case finished = 4
        
        
        var color: UIColor {
            let values = [UIColor.darkGray, UIColor.darkGray, #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1), #colorLiteral(red: 0.5490196078, green: 0.8235294118, blue: 0, alpha: 1), UIColor.darkGray]
            return values[self.rawValue]
        }
        
        var pluralName: String {
            let values = ["", "En attente", "En préparation", "Prêtes", "Terminées"]
            return values[self.rawValue]
        }
        
        var singularName: String {
            let values = ["", "En attente", "En préparation", "Prête",  "Terminée"]
            return values[self.rawValue]
        }
        
        var fullName: String {
            let values = ["", "Commande en attente", "Commande en préparation", "Commande prête",  "Commande terminée"]
            return values[self.rawValue]
        }
    }
    
    static func == (left: CafetOrder, right: CafetOrder) -> Bool {
        return left.ID == right.ID && left.status == right.status
    }
    
    private enum CodingKeys: String, CodingKey {
        case ID, modID, status, startTime, completeTime, takenTime, readyTime, endTime, friendlyText, instructions, price, paid, username, clientName, source, token, order, imgurl
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ID = try values.decode(Int.self, forKey: .ID)
        modID = try values.decode(Int.self, forKey: .modID)
        status = try values.decode(Status.self, forKey: .status)
        startTime = try values.decode(Date.self, forKey: .startTime)
        completeTime = try? values.decode(Date.self, forKey: .completeTime)
        takenTime = try? values.decode(Date.self, forKey: .takenTime)
        readyTime = try? values.decode(Date.self, forKey: .readyTime)
        endTime = try? values.decode(Date.self, forKey: .endTime)
        friendlyText = try values.decode(String.self, forKey: .friendlyText)
        instructions = try values.decode(String.self, forKey: .instructions)
        price = try values.decode(Double.self, forKey: .price)
        paid = try values.decode(Int.self, forKey: .paid) == 1
        username = try values.decode(String.self, forKey: .username)
        clientName = try values.decode(String.self, forKey: .clientName)
        source = try values.decode(String.self, forKey: .source)
        token = try values.decode(String.self, forKey: .token)
        order = try values.decode(String.self, forKey: .order)
        imgurl = try? values.decode(String.self, forKey: .imgurl)
    
    }
    
}

/// Describes a JSON status reponse from API
struct CafetInfo: Decodable {
    
    /// Is cafet open ?
    let isOpen: Bool
    
    /// Can the user order ?
    let canOrder: Bool
    
    /// Menus available
    let menus: [CafetMenu]
    
    /// Ingredients available
    let ingredients: [CafetIngredient]
    
    /// MainElements available
    let mainElements: [CafetMainElement]
    
    /// SubElements available
    let subElements: [CafetSubElement]
    
    /// Categories available
    let categories: [CafetCategory]
    
    /// Get array of all elements
    var allElements: [CafetElement] {
        return [mainElements, subElements].flatMap({ (element: [CafetElement]) in
            return element
        })
    }
    
}

struct CafetPanier: Encodable {
    
    /// Order token
    let token: String!
    
    /// Selected menus
    var selectedMenus: [CafetMenu]
    
    /// Selected mainElements
    var selectedMainElements: [CafetMainElement]
    
    /// Selected subElements
    var selectedSubElements: [CafetSubElement]
    
    /// Order instructions
    var instructions: String = ""
    
    init(token: String) {
        self.token = token
        self.selectedMenus = []
        self.selectedMainElements = []
        self.selectedSubElements = []
        self.instructions = ""
    }
    
    /// Returns every cafet item
    var selectedItems: [CafetElement] {
        get {
            var arr: [CafetElement] = self.selectedMenus
            arr.append(contentsOf: self.selectedMainElements)
            arr.append(contentsOf: self.selectedSubElements)
            return arr
        }
    }
    
    /// Returns this cart's price
    var price: Double {
        get {
            var somme: Double = 0
            for menu in selectedMenus {
                somme += menu.realPrice
            }
            for mainElement in selectedMainElements {
                somme += mainElement.realPrice
            }
            for subElement in selectedSubElements {
                somme += subElement.price
            }
            return somme
        }
    }
    
    /// Empties current cart
    mutating func vider() {
        self.selectedMainElements = []
        self.selectedSubElements = []
        self.selectedMenus = []
    }
    
    /// Removes cart element at given index
    mutating func removeElement(at index: Int) {
        let elementToRemove = self.selectedItems[index]
        
        if let menu = elementToRemove as? CafetMenu {
            self.selectedMenus.remove(at: self.selectedMenus.firstIndex(of: menu)!)
        } else if let mainElement = elementToRemove as? CafetMainElement {
            self.selectedMainElements.remove(at: self.selectedMainElements.firstIndex(of: mainElement)!)
        } else if let subElement = elementToRemove as? CafetSubElement {
            self.selectedSubElements.remove(at: self.selectedSubElements.firstIndex(of: subElement)!)
        }
    }
    
    var orderData: OrderData {
        get {
            return OrderData(menus: self.selectedMenus, mainElements: self.selectedMainElements, subElements: self.selectedSubElements)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case token, instructions
        case data = "data"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(OrderData(menus: selectedMenus, mainElements: selectedMainElements, subElements: selectedSubElements), forKey: .data)
    }
    
    
}

struct OrderData: Encodable {
    
    let menus: [CafetMenu]
    
    let mainElements: [CafetMainElement]
    
    let subElements: [CafetSubElement]
    
    init(menus: [CafetMenu], mainElements: [CafetMainElement], subElements: [CafetSubElement]) {
        self.menus = menus
        self.mainElements = mainElements
        self.subElements = subElements
    }
}

/// Describes a Service JSON response from API
struct CafeteriaSettingResult: APIResult, Decodable {
    
    let success: Bool
    
    let setting: [CafeteriaSetting]
    
}

struct CafeteriaSetting: Decodable {
    
    let key: String
    
    let value: String
}

/// Describes a CafetOrder list JSON response from API
struct CafetOrdersResult: APIResult, Decodable {
    
    /// `API.ErrorResult.Error.uid` value if wrong token was given
    static let wrongTokenErrorCode = 13
    
    
    let success: Bool
    
    let orders: [CafetOrder]
    
}

/// Describes a CafetOrder JSON response from API
struct CafetOrderResult: APIResult, Decodable {
    
    let success: Bool
    
    let order: CafetOrder
    
}

/// Describes a JSON response with token from API when creating a new order
struct CafetNewOrderResult: APIResult, Decodable {
    
    let success: Bool
    
    let token: String
    
}

/// Describes a JSON response from API containing available items
struct CafetMenusResult: APIResult, Decodable {
    
    let success: Bool
    
    let cafeteria: CafetInfo
    
}

struct CafetCategory: Decodable {
    
    let position: Int
    let name: String
    let imgUrl: String
    let description: String
}

class CafetElement: Codable, Equatable {
    
    /// Element ID
    let ID: Int
    
    /// Element name
    let name: String
    
    /// Element price
    let price: Double
    
    /// Element availability
    var available: Bool
    
    /// Element category ID
    var category: Int
    
    /// Element details
    var details: String {
        get {
            fatalError("Must be overriden")
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case ID, name, price
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ID = try values.decode(Int.self, forKey: .ID)
        name = try values.decode(String.self, forKey: .name)
        price = try values.decode(Double.self, forKey: .price)
        
        available = false
        category = -1
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ID, forKey: .ID)
    }
    
    static func == (lhs: CafetElement, rhs: CafetElement) -> Bool {
        return lhs.ID == rhs.ID && lhs.name == rhs.name
    }
    
}

class CafetMenu: CafetElement {
    
    /// Max number of main elements in this menu
    var nbMainElements: Int
    
    /// Max number of sub elements in this menu
    var nbSubElements: Int
    
    /// Is menu temporary ?
    var temporary: Bool
    
    /// If the menu is temporary, represents the starting date
    var startDate: Date?
    
    /// If the menu is temporary, represents the ending date
    var endDate: Date?
    
    /// Every possible main elements in this menu
    var mainElements: [CafetMainElement]
    
    /// Every possible sub elements in this menu
    var subElements: [CafetSubElement]
    
    var selectedMainElements: [CafetMainElement]
    var selectedSubElements: [CafetSubElement]
    
    static let dateFormat = "yyyy-MM-dd"
    
    /// Only available main elements in this menu
    var availableMainElements: [CafetMainElement] {
        get {
            return self.mainElements.filter { $0.available }
        }
    }
    
    /// Only available sub elements in this menu
    var availableSubElements: [CafetSubElement] {
        get {
            return self.subElements.filter { $0.available }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case mainElements, subElements, nbMainElements, nbSubElements, temporary, startDate, endDate, available, ID, price, name
        case category = "category"
    }
    
    required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        mainElements = try values.decode([CafetMainElement].self, forKey: .mainElements)
        subElements = try values.decode([CafetSubElement].self, forKey: .subElements)
        nbMainElements = try values.decode(Int.self, forKey: .nbMainElements)
        nbSubElements = try values.decode(Int.self, forKey: .nbSubElements)
        temporary = try values.decode(Bool.self, forKey: .temporary)
        startDate = try? values.decode(Date.self, forKey: .startDate)
        endDate = try? values.decode(Date.self, forKey: .endDate)
        
        selectedMainElements = []
        selectedSubElements = []
        
        try super.init(from: decoder)
        
        category = try values.decode(Int.self, forKey: .category)
        available = try values.decode(Bool.self, forKey: .available)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ID, forKey: .ID)
        try container.encode(selectedMainElements, forKey: .mainElements)
        try container.encode(selectedSubElements, forKey: .subElements)
    }
    
    /// Menu real price including supplements
    var realPrice: Double {
        get {
            var somme: Double = price
            
            for mainElement in mainElements {
                somme += mainElement.priceSupplement()
            }
            
            return somme
        }
    }
    
    override var details: String {
        get {
            var string = ""
            for mainElement in selectedMainElements {
                string += String(format: "– %@ (%@)\n", mainElement.name, mainElement.details)
            }
            
            for subElement in selectedSubElements {
                string += String(format: "– %@\n", subElement.name)
            }
            
            return string
        }
    }
    
}

class CafetMainElement: CafetElement {
    
    /// Element's choosable ingredients
    var ingredients: [CafetIngredient]
    
    /// Selected element's ingredient
    var selectedIngredients: [CafetIngredient]
    
    /// Number of maximum ingredients without any supplement
    var nbIngredients: Int
    
    enum CodingKeys: String, CodingKey {
        case ingredients, available, nbIngredients, ID, price, name
        case category = "idCategory"
    }
    
    required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ingredients = try values.decode([CafetIngredient].self, forKey: .ingredients)
        nbIngredients = try values.decode(Int.self, forKey: .nbIngredients)
        
        selectedIngredients = []
        
        try super.init(from: decoder)
        
        category = try values.decode(Int.self, forKey: .category)
        available = try values.decode(Bool.self, forKey: .available)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ID, forKey: .ID)
        try container.encode(selectedIngredients, forKey: .ingredients)
    }
    
    func priceSupplement() -> Double {
        var somme: Double = 0
        if self.selectedIngredients.count > 0 {
            for i in 0...self.selectedIngredients.count - 1 {
                if (i > self.nbIngredients - 1) {
                    somme += self.selectedIngredients[i].price
                }
            }
        }
        
        return somme
    }
    
    var availableIngredients: [CafetIngredient] {
        get {
            return self.ingredients.filter { $0.available }
        }
    }
    
    /// Real element price including supplement
    var realPrice: Double {
        get {
            return price + priceSupplement()
        }
    }
    
    override var details: String {
        get {
            return selectedIngredients.compactMap { $0.name }.joined(separator: ", ")
        }
    }
    
}

class CafetSubElement: CafetElement {
    
    /// Sub element remaining stock
    var stock: Int
    
    /// How many "standard" elements this item equals to
    var countsFor: Int
    
    enum CodingKeys: String, CodingKey {
        case ID, name, price, stock, countsFor
        case category = "idCategory"
    }
    
    required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        stock = try values.decode(Int.self, forKey: .stock)
        countsFor = try values.decode(Int.self, forKey: .countsFor)
        
        try super.init(from: decoder)
        
        category = try values.decode(Int.self, forKey: .category)
        available = stock > 0
        
    }
    
    override var details: String {
        get {
            return ""
        }
    }
}


class CafetIngredient: CafetElement {
    
    enum CodingKeys: String, CodingKey {
        case available, category
    }
    
    required init(from decoder: Decoder) throws {

        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        try super.init(from: decoder)
        
        available = try values.decode(Bool.self, forKey: .available)
        
    }
    
}

