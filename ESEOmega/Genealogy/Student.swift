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

// MARK: - Student rank

/// Describes a student level of studies, and their associated JSON raw value
enum StudentRank: Int, Codable {
    
    /// First year, prep cycle
    case p1 = 0
    /// Second year, prep cycle
    case p2 = 1
    /// First year, engineer cycle
    case i1 = 2
    /// Second year, engineer cycle
    case i2 = 3
    /// Last year, engineer cycle
    case i3 = 4
    /// Graduated student
    case alumni = 5
    
    /// Returns the student rank title
    var name: String {
        switch self {
            case .p1: return "P1"
            case .p2: return "P2"
            case .i1: return "I1"
            case .i2: return "I2"
            case .i3: return "I3"
            default:  return "Alumni"
        }
    }
}

/// Compares 2 student ranks
///
/// - Parameters:
///   - left: First rank
///   - right: Second rank
/// - Returns: True if the first rank is higher than the second
func > (left: StudentRank, right: StudentRank) -> Bool {
    return left.rawValue > right.rawValue
}


// MARK: - Student

/// JSON raw type to identify a student
typealias StudentID = Int

/// Describes a student and their characteristics
struct Student: Decodable {
    
    /// API Student ID
    let id: StudentID
    
    /// Name of the student (e.g. `Thomas NAUDET`)
    let name: String
    
    /// Name of the class (e.g. `De Gennes`)
    let promotion: String
    
    /// Year of studies (e.g. `I3`)
    let rank: StudentRank
    
    /// List of the IDs of the student's parents in the tree view
    let parents: [StudentID]
    
    /// List of the IDs of the student's children in the tree view
    let children: [StudentID]
    
    
    /// Finds equality between 2 students
    static func == (left: Student, right: Student) -> Bool {
        return left.id == right.id
    }
    
}

/// Describes a Student JSON response from API
struct StudentResult: APIResult, Decodable {
    
    let success: Bool
    
    /// List of Students in a family
    let students: [Student]
    
}


// MARK: - Search

struct GenealogySearchItem: Decodable {
    
    let id: StudentID
    
    let name: String
    
    let rank: StudentRank
    
    let promotion: String
    
}

/// Describes a Student Search JSON response from API
struct GenealogySearchResult: APIResult, Decodable {
    
    let success: Bool
    
    /// List of Students corresponding to query
    let students: [GenealogySearchItem]
    
}
