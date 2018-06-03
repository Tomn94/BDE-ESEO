//
//  User.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 26/05/2018.
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

struct User {
    
    /// Default domain name for mail addresses (used in autocomplete and placeholders)
    static let mailDomain = "reseau.eseo.fr"

}


/// Describes a Login JSON response from API
struct LoginResult: APIResult, Decodable {
    
    /// `API.ErrorResult.Error.ui` value if user entered wrong password
    static let wrongPasswordErrorCode = 7
    
    
    let success: Bool
    
    /// Id of the student (e.g. "thomas.naudet")
    let ID: String
    
    /// Name of the student (e.g. "Thomas NAUDET")
    let fullname: String
    
    /// API connection token granted
    let token: String
    
}
