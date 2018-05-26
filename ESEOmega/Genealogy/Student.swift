//
//  Student.swift
//  ESEOmega
//
//  Created by Thomas Naudet on 31/10/2016.
//  Copyright © 2016 Thomas Naudet

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


/// JSON raw type to identify a student
typealias StudentID = String

/// Describes a student level of studies, and the associated JSON raw value.
/// Currently starts with `0` for Josephson. The less, the older.
typealias StudentRank = Int

/// JSON raw type to identify a student family
typealias FamilyID = Int

/// Describes a student and their characteristics
struct FamilyMember: Decodable {
    
    /// API Student ID
    let ID: StudentID
    
    /// Name of the student (e.g. `Thomas NAUDET`)
    let fullname: String
    
    /// Name of the class (e.g. `De Gennes`)
    let promo: String
    
    /// Index of the class (e.g. `0` for "Josephson")
    let rank: StudentRank
    
    /// API Family ID
    let familyID: FamilyID
    
    /// List of the IDs of the student's parents in the tree view
    let parentIDs: [StudentID]?
    
    /// List of the IDs of the student's children in the tree view
    let childIDs: [StudentID]?
    
    
    /// Finds equality between 2 students
    static func == (left: FamilyMember, right: FamilyMember) -> Bool {
        return left.ID == right.ID
    }
    
}

/// Describes a Family JSON response from API
struct FamilyResult: APIResult, Decodable {
    
    let success: Bool
    
    /// List of Students in a family
    let familyMembers: [FamilyMember]
    
}

/// Describes a Student Search JSON response from API
struct StudentSearchResult: APIResult, Decodable {
    
    let success: Bool
    
    /// List of Students corresponding to query
    let users: [FamilyMember]
    
}
