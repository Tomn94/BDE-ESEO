//
//  Utils.swift
//  MessagesExtension
//
//  Created by Tomn on 09/09/2017.
//  Copyright © 2017 Thomas Naudet
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

/// Pot-pourri for MessagesExtension
enum Utils {

    /// Empty implementation, because needed in API requests, and because
    /// UIApplication.shared in requiresActivityIndicator(_:) from main target
    /// is not available in MessagesExtensions.
    static func requiresActivityIndicator(_ showIndicator: Bool) {
    }
    
}
