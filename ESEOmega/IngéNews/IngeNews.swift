//
//  IngeNews.swift
//  ESEOmega
//
//  Created by Tomn on 10/07/2017.
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

/// Describes an IngéNews document
struct IngeNews: Codable {
    
    /// Unique identifier for the document
    let id: Int
    
    /// Name of the edition
    let name: String
    
    /// Date when the edition was published
    let date: Date
    
    /// Remote file URL where the document is stored
    let file: URL
    
    /// Size of the remote document
    let size: Int64
    
    /// Thumbnail icon for document preview
    let img: URL?
    
}
