//
//  Club.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 02/06/2018.
//  Copyright © 2018 Thomas Naudet

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

/// Describes a Member of a Club
struct ClubMember: Codable {
    
    let user: String
    
    let fullname: String
    
    let role: String
    
}


/// Describes a Club/BDE/… and its attributes
struct Club: Codable {
    
    /// Unique identifier for the club
    let ID: Int
    
    /// Name of the club (BDE)
    let name: String
    
    /// Short text (Bureau des Étudiants)
    let subtitle: String
    
    /// Long text (Le BDE est…)
    let description: String
    
    /// Image of the club
    let img: URL?
    
    /// JSON-like structure containing links
    /// Yeah it's a string because the one who recoded it forgot to make it a JSON array
    /// Feel free to correct this with a proper structure when the server is fixed
    let contacts: String
    
    /// List of club members
    let users: [ClubMember]
    
}


/// Describes a News JSON response from API
struct ClubsResult: APIResult, Decodable {
    
    let success: Bool
    
    let clubs: [Club]
    
}
