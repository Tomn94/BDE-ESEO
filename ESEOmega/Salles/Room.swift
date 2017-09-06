//
//  Room.swift
//  ESEOmega
//
//  Created by Tomn on 06/09/2017.
//  Copyright © 2017 Tomn. All rights reserved.
//

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

/// Describes a room and its attributes
struct Room: Codable {
    
    /// Remote API path,
    /// and reference when asking Rooms cache or data updates
    static let apiPath = "rooms"
    
    /// Ways to sort rooms.
    /// Raw value is how this preference is stored
    enum SortMode: Int {
        case byName     = 0
        case byBuilding = 1
        case byFloor    = 2
    }
    
    
    /// Name of the room
    let name: String
    
    /// Letter of the building (A, B, C)
    let building: String
    
    /// Floor where the room is (-1, 0, 1, 2, 3, 4)
    let floor: Int
    
    /// Eventual number of the room (CS001)
    let number: String?
    
    /// Eventual information about the room (À gauche après l'escalier)
    let info: String?
    
}
