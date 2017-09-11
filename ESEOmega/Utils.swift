//
//  Utils.swift
//  ESEOmega
//
//  Created by Tomn on 07/09/2017.
//  Copyright © 2017 Thomas NAUDET

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

import UIKit

/// Pot-pourri
enum Utils {
    
    // MARK: Activity Loading Indicator
    
    /// Number of resources requesting iOS activity
    /// indicator in status bar to be displayed
    private static var loadingCount = 0
    
    /// Retain or release iOS activity indicator in status bar
    ///
    /// - Parameter showIndicator: Whether the caller needs the indicator or not
    static func requiresActivityIndicator(_ showIndicator: Bool) {
    
        if showIndicator {
            loadingCount += 1
        } else {
            loadingCount -= 1
        }
    
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = loadingCount > 0
        }
    }
    
}


extension UISplitViewController {
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

extension UINavigationController {
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
