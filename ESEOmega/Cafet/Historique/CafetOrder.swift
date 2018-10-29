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
struct CafetOrder: Equatable, Codable {
    
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
    let paid: Int
    
    let username: String?
    
    let clientName: String?
    
    let source: String?
    
    let token: String?
    
    let oder: String?
    
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
    
}


/// Describes a Service JSON response from API
struct CafetServiceResult: APIResult, Decodable {
    
    let success: Bool
    
    let message: String
    
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
    
    let orders: [CafetOrder]
    
}

/// Describes a JSON response with token from API when creating a new order
struct CafetNewOrderResult: APIResult, Decodable {
    
    let success: Bool
    
    let token: String
    
}

/// Describes a JSON response from API containing available items
struct CafetMenusResult: APIResult, Decodable {
    
    let success: Bool
    
    let categories: [CafetCategory]
    
    let menus: [CafetMenu]
    
    let mainElements: [CafetMainElement]
    
    let subElement: [CafetSubElement]
    
    let ingredients: [CafetIngredient]
    
}

struct CafetCategory: Decodable {
    
    let position: Int
    let name: String
    let imgUrl: String
    let description: String
}

struct CafetMenu: Decodable {
    
    let ID: Int
    let name: String
    let price: Double
    let nbMainElements: Int
    let nbSubElements: Int
    let category: Int
    let available: Bool
    let temporary: Bool
    let startDate: Date
    let endDate: Date
    
    let mainElements: [CafetMainElement]
    let subElements: [CafetSubElement]
    
    let selectedMainElements: [CafetMainElement]?
    let selectedSubElements: [CafetSubElement]?
}

struct CafetMainElement: Decodable {
    
    let ID: Int
    let name: String
    let price: Double
    let idCategory: Int
    let available: Bool
    let ingredients: [CafetIngredient]
    
    let selectedIngredients: [CafetIngredient]?
}

struct CafetSubElement: Decodable {
    
    let ID: Int
    let name: String
    let price: Double
    let idCategory: Int
    let stock: Int
    let countsFor: Int
    
}

struct CafetIngredient: Decodable {
    
    let ID: Int
    let name: String
    let available: Bool
    let price: Double
}
