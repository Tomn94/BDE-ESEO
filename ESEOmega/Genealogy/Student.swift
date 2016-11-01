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

/// JSON raw types to identify a student
typealias StudentID = Int
typealias StudentRankRaw = Int

/// Describes a student level of studies
enum StudentRank: String {
    case P1 = "P1"
    case P2 = "P2"
    case I1 = "I1"
    case I2 = "I2"
    case I3 = "I3"
    case Alumni = "Alumni"
    
    /** Convert JSON raw value to enum type
        This function is needed to provide a default value */
    static func parse(_ value: StudentRankRaw) -> StudentRank {
        switch value {
            case 0:  return P1
            case 1:  return P2
            case 2:  return I1
            case 3:  return I2
            case 4:  return I3
            default: return Alumni
        }
    }
    
    /** Convert enum type to JSON raw value
        This function is needed to sort students by rank */
    var dataValue: StudentRankRaw {
        switch self {
            case .P1: return 0
            case .P2: return 1
            case .I1: return 2
            case .I2: return 3
            case .I3: return 4
            default:  return 5
        }
    }
}

func >(left: StudentRank, right: StudentRank) -> Bool {
    return left.dataValue > right.dataValue
}

/// Describes a student and their characteristics
struct Student {
    let id: StudentID
    let name: String
    let promotion: String
    let rank: StudentRank
    let parents: [StudentID]
    let children: [StudentID]
}

func ==(left: Student, right: Student) -> Bool {
    return left.id == right.id
}
