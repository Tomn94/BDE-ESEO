//
//  Sponsor.swift
//  BDE-ESEO
//
//  Created by Benjamin Gondange on 11/09/2018.
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

import Foundation

/// Describe a sponsor and its attributes

struct Sponsor: Codable, Equatable {
    
    /// Sponsor name
    let name: String
    
    /// Sponsor description
    let description: String
    
    /// Sponsor image URL
    let image: String?
    
    /// Sponsor URL
    let url: String?
    
    /// Sponsor postal address
    let address: String?
    
    /// Sponsor perks
    let perks: [String]
    
    static func == (left: Sponsor, right: Sponsor) -> Bool {
        return left.name == right.name
    }
}

struct SponsorsResult: APIResult, Decodable {
    
    let success: Bool
    
    let sponsors: [Sponsor]
}
