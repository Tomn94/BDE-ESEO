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
import UIKit

/// Describes a Member of a Club
struct ClubMember: Codable {
    
    /// Id of the student (e.g. "thomas.naudet")
    let user: StudentID
    
    /// Name of the student (e.g. "Thomas NAUDET")
    let fullname: String
    
    /// Role in the club (e.g. "Responsable Com")
    let role: String
    
    /// Whether the user is from the Board.
    /// It could be useful to use this in addition to comparing `self.user == club.prez`.
    var hasResponsibilities: Bool {
        var role = self.role.localizedLowercase
        if let roleWithoutAccents = role.applyingTransform(.stripDiacritics, reverse: false) {
            role = roleWithoutAccents
        }
        return role.contains("president")  ||
               role.contains("vice-pre")   || role.contains("vice pre")  || role.starts(with: "VP") || role.starts(with: "V-P") ||
               role.contains("secretaire") || role.contains("tresorier") ||
               role.contains("resp")       || role.contains("chargé")
    }
    
}


/// Describes how a Club can be contacted.
/// String are used instead of URLs because the value might be empty or an username.
struct ClubContactInfo: Codable {
    
    /// Website URL
    let web: String?
    
    /// Facebook page address
    let fb: String?
    
    /// Twitter username or profile URL
    let twitter: String?
    
    /// YouTube channel URL
    let youtube: String?
    
    /// Snapchat username or URL
    let snap: String?
    
    /// Instagram username or URL
    let instagram: String?
    
    /// LinkedIn page URL
    let linkedIn: String?
    
    /// Mail address
    let mail: String?
    
    /// Telephone number
    let tel: String?
    
    
    /// All available contact modes above
    static let contactModes  = [\ClubContactInfo.web,      \ClubContactInfo.fb,   \ClubContactInfo.twitter,
                                \ClubContactInfo.youtube,  \ClubContactInfo.snap, \ClubContactInfo.instagram,
                                \ClubContactInfo.linkedIn, \ClubContactInfo.mail, \ClubContactInfo.tel]
    
    /// Action title of all available contact modes
    static let contactTitles = ["Site",     "Facebook", "Twitter",
                                "YouTube",  "Snapchat", "Instagram",
                                "LinkedIn", "Mail…",    "Appeler…"]
    
    /// Images of all available contact modes
    static let contactImgs   = [#imageLiteral(resourceName: "web"), #imageLiteral(resourceName: "fb"), #imageLiteral(resourceName: "twitter"),
                                #imageLiteral(resourceName: "youtube"), #imageLiteral(resourceName: "snap"), #imageLiteral(resourceName: "instagram"),
                                #imageLiteral(resourceName: "linkedin"), #imageLiteral(resourceName: "mail"), #imageLiteral(resourceName: "tel")]
}


/// Describes a Club/BDE/… and its attributes
class Club: Codable, Equatable {
    
    /// Unique identifier for the club
    let ID: String
    
    /// Name of the club (BDE)
    let name: String
    
    /// Short text (Bureau des Étudiants)
    let subtitle: String
    
    /// Long text (Le BDE est…)
    let description: String
    
    /// Image of the club
    /// Feel free to use URL instead of String,
    /// but we'll be using this for now since the one who recoded doesn't provide images
    /// (JSONDecoder dislikes empty URLs)
    let img: String
    
    /// Containing links and usernames on social networks
    let contacts: ClubContactInfo
    
    /// List of club members
    var users: [ClubMember]
    
    /// ID of the president of the club
    let prez: StudentID
    
    
    /// Links struct variables and JSON keys
    private enum CodingKeys: String, CodingKey {
        case contacts = "contacts_json"
        case ID, name, subtitle, description, img, users, prez
    }
    
    
    /// Returns is this club is most likely the Students’ Union
    var isBDE: Bool {
        return name.localizedLowercase.contains("bde") || subtitle.localizedLowercase.contains("bde")
    }
    
    /// Returns is this club is most likely from Paris
    var isFromParis: Bool {
        return name.localizedLowercase.contains("paris") || subtitle.localizedLowercase.contains("paris")
    }
    
    /// Returns is this club is most likely from Angers
    var isNotParisNorDijon: Bool {
        return !name.localizedLowercase.contains("paris")
            && !name.localizedLowercase.contains("dijon")
            && !subtitle.localizedLowercase.contains("paris")
            && !subtitle.localizedLowercase.contains("dijon")
    }
    
    
    /// Sort users by decreasing responsibilities
    func sortClubMembers() {
        
        // Define increasing order for each role
        let weightForRole: (String, String) -> Int = { user, role in
            
            if role.contains("president") || user == self.prez {
                return 1
            }
            if role.contains("vice-pre") || role.contains("vice pre") || role.starts(with: "VP") || role.starts(with: "V-P") {
                return 2
            }
            if role.contains("secretaire") {
                return 3
            }
            if role.contains("tresorier") {
                return 4
            }
            if role.contains("resp") {
                return 5
            }
            if role.contains("chargé") {
                return 6
            }
            return 10
        }
        
        users = users.sorted { member1, member2 in
            var role1 = member1.role.localizedLowercase
            if let roleWithoutAccents = role1.applyingTransform(.stripDiacritics, reverse: false) {
                role1 = roleWithoutAccents
            }
            let weight1 = weightForRole(member1.user, role1)
            
            var role2 = member2.role.localizedLowercase
            if let roleWithoutAccents = role2.applyingTransform(.stripDiacritics, reverse: false) {
                role2 = roleWithoutAccents
            }
            let weight2 = weightForRole(member2.user, role2)
            
            if weight1 == weight2 {
                if role1 == role2 {
                    // Order by name for the same roles
                    return member1.fullname.localizedStandardCompare(member2.fullname) == .orderedAscending
                }
                // Otherwise order by role (the text is not the same, even if they have the same weight)
                return role1.localizedStandardCompare(role2) == .orderedAscending
            }
            // Otherwise show the higher roles first
            return weight1 < weight2
        }
    }
    
    
    static func == (left: Club, right: Club) -> Bool {
        return left.ID == right.ID
    }
    
}


/// Describes a News JSON response from API
struct ClubsResult: APIResult, Decodable {
    
    let success: Bool
    
    let clubs: [Club]
    
}
