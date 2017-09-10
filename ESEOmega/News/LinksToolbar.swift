//
//  LinksToolbar.swift
//  ESEOmega
//
//  Created by Tomn on 10/09/2017.
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

import UIKit

fileprivate extension Selector {
    static let updateTheme = #selector(LinksToolbar.updateTheme)
}

class LinksToolbar: UIView {
    
    let toolbar = UIToolbar()
    
    var bdeItem: UIBarButtonItem {
        
        return UIBarButtonItem(image: Data.linksToolbarBDEIcon(),
                               style: .plain,
                               target: self, action: nil)
    }
    
    var toolbarItems: [UIBarButtonItem] {
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [flexibleSpace,
                UIBarButtonItem(image: #imageLiteral(resourceName: "eseoMails"), style: .plain, target: nil, action: nil),
                flexibleSpace,
                UIBarButtonItem(image: #imageLiteral(resourceName: "eseo"), style: .plain, target: nil, action: nil),
                flexibleSpace,
                UIBarButtonItem(image: #imageLiteral(resourceName: "eseoPortail"), style: .plain, target: nil, action: nil),
                flexibleSpace,
                UIBarButtonItem(image: #imageLiteral(resourceName: "eseoCampus"), style: .plain, target: nil, action: nil),
                flexibleSpace,
                UIBarButtonItem(image: #imageLiteral(resourceName: "dreamspark"), style: .plain, target: nil, action: nil),
                flexibleSpace,
                bdeItem,
                flexibleSpace]
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: 64)
        autoresizingMask = .flexibleWidth
        backgroundColor  = UIColor(white: 0.98, alpha: 1)
        
        let border = UIView()
        border.frame = CGRect(x: 0, y: 0, width: frame.width,
                              height: 1 / UIScreen.main.scale)
        border.autoresizingMask = .flexibleWidth
        border.backgroundColor = UIColor(white: 0.8, alpha: 1)
        addSubview(border)
        
        let header = UILabel(frame: CGRect(x: 4, y: 0,
                                           width: frame.width, height: 20))
        header.text = "LIENS RAPIDES"
        header.textColor = UIColor(white: 0.5, alpha: 1)
        header.sizeToFit()
        header.font = UIFont.preferredFont(forTextStyle: .caption2)
        addSubview(header)
        
        toolbar.frame = CGRect(x: 0, y: 16, width: frame.width, height: 48)
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.delegate = self
        toolbar.items = toolbarItems
        toolbar.setBackgroundImage(UIImage(),
                                   forToolbarPosition: .any, barMetrics: .default)
        addSubview(toolbar)
        
        NotificationCenter.default.addObserver(self, selector: .updateTheme,
                                               name: .themeChanged, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func updateTheme() {
        toolbar.items = toolbarItems
    }

}


// MARK: - Tool Bar Delegate
extension LinksToolbar: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        
        return .top
    }
    
}
