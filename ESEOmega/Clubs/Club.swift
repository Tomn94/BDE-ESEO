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
    
    let user: StudentID
    
    let fullname: String
    
    let role: String
    
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
    
    /// Call this to open website/social network/… and do the appropriate action
    ///
    /// - Parameters:
    ///   - contactMode: Selected contact mode
    ///   - viewController: View controller on top of which to present a web/mail/… view controller
    func handle(_ contactMode: KeyPath<ClubContactInfo, String?>,
                in viewController: UIViewController) {
        
        switch contactMode {
        case \ClubContactInfo.web:
            Data.shared().openURL(web, currentVC: viewController)
        case \ClubContactInfo.fb:
            Data.shared().openURL(fb, currentVC: viewController)
        case \ClubContactInfo.twitter:
            // Check if URL, otherwise @username
            if let profileURL = twitter,
               URL(string: profileURL) != nil {
                Data.shared().openURL(profileURL, currentVC: viewController)
            } else {
                Data.shared().twitter(twitter, currentVC: viewController)
            }
        case \ClubContactInfo.youtube:
            Data.shared().openURL(youtube, currentVC: viewController)
        case \ClubContactInfo.snap:
            Data.shared().snapchat(snap, currentVC: viewController)
        case \ClubContactInfo.instagram:
            // Check if URL, otherwise username
            if let profileURL = instagram,
               URL(string: profileURL) != nil {
                Data.shared().openURL(profileURL, currentVC: viewController)
            } else {
                Data.shared().instagram(instagram, currentVC: viewController)
            }
        case \ClubContactInfo.linkedIn:
            Data.shared().openURL(linkedIn, currentVC: viewController)
        case \ClubContactInfo.mail:
            if let vc = viewController as? UIViewController & MFMailComposeViewControllerDelegate {
                Data.shared().mail(mail, currentVC: vc)
            }
        case \ClubContactInfo.tel:
            Data.shared().tel(tel, currentVC: viewController)
        default:
            return
        }
    }
}


/// Describes a Club/BDE/… and its attributes
struct Club: Codable, Equatable {
    
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
    
    /// JSON-like structure containing links
    /// Yeah it's a string because the one who recoded it forgot to make it a JSON array
    /// Feel free to correct this with `ClubContactInfo` when the server is fixed
    let contacts: String
    
    /// List of club members
    var users: [ClubMember]
    
    /// ID of the president of the club
    let prez: StudentID
    
    
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
    mutating func sortClubMembers() {
        
        // Define increasing order for each role
        let weightForRole: (String, String) -> Int = { user, role in
            
            if role.contains("president") || user == self.prez {
                return 1
            }
            if role.contains("vice-pre") || role.contains("vice pre") || role.starts(with: "VP") {
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
