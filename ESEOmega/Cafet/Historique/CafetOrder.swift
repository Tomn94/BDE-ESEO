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

import Foundation

/// Describes an order requested by the user at the school cafétéria
struct CafetOrder: Codable {
    
    /// Unique ID
    let idcmd: Int
    
    /// Generated string identifiant, used in front of `modcmd`
    let strcmd: String
    
    /// Modulo applied on `idcmd`, usually written after `strcmd`
    let modcmd: String
    
    /// Cooking status
    let status: Status
    
    /// Request date
    let datetime: Date
    
    /// Generated text describing the order
    let resume: String
    
    /// Client requests concerning their food/delivery
    let instructions: String?
    
    /// Price of the whole order
    let price: Double
    
    
    // MARK: Available after requesting details
    
    /// Category illustration
    let imgurl: URL?
    
    /// Whether the order is already paid (before it's been `Status.done`)
    let paidbefore: PaidBeforeStatus?
    
    /// ID of the transaction with Lydia, -1 otherwise
    /// means `paidbefore == .alreadyPaid`
    let idlydia: Int?
    
    /// Whether Lydia is enabled on the server
    let lydia_enabled: Bool?
    
    
    static let dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    /// Order status and associated raw JSON value
    enum Status: Int, Codable {
        /// Initial state
        case preparing = 0
        /// Kitchen finished preparing
        case ready     = 1
        /// Kitchen's done preparing and user paid for it
        case done      = 2
        /// Order was done but not paid
        case notPaid   = 3
    }
    
    /// Payment status during `Status.preparing` or `Status.ready` states
    enum PaidBeforeStatus: Int, Codable {
        /// User will likely pay at the counter when their order is `Status.done`
        case notPaidYet  = 0
        /// Paid using Lydia or at the counter, before order is `Status.done`
        case alreadyPaid = 1
    }
    
}


/// Describes a CafetOrder JSON response from API
struct CafetOrderResult: APIResult, Decodable {
    
    let success: Bool
    
    let orders: [CafetOrder]
    
}

