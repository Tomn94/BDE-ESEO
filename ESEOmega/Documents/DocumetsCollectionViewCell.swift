//
//  DocumetsCollectionViewCell.swift
//  BDE-ESEO
//
//  Created by Romain Rabouan on 15/09/2019.
//  Copyright © 2019 Romain Rabouan

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

class DocumentsCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UI
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Folder")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = "List"
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.textAlignment = .left
        return label
    }()
    
    
    fileprivate func setupCell() {
        roundCorner()
        setCellShadow()
        
        self.addSubview(iconImageView)
        self.addSubview(listNameLabel)
        
        /// Layout
        iconImageView.anchor(top: safeTopAnchor, left: safeLeftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 36, height: 36)
        listNameLabel.anchor(top: iconImageView.bottomAnchor, left: safeLeftAnchor, bottom: nil, right: nil, paddingTop: 18, paddingLeft: 8, paddingBottom: 0, paddingRight: 0)
        
    }
    
    // MARK: Methods
       func setCellShadow() {
           self.layer.shadowColor = UIColor.black.cgColor
           self.layer.shadowOffset = CGSize(width: 0, height: 1)
           self.layer.shadowOpacity = 0.2
           self.layer.shadowRadius = 1.0
           self.layer.masksToBounds = false
           self.layer.cornerRadius = 3
           self.clipsToBounds = false
       }
       
       
       func roundCorner() {
           self.contentView.layer.cornerRadius = 12.0
           self.contentView.layer.masksToBounds = true
           self.contentView.layer.borderWidth = 1.0
           self.contentView.layer.borderColor = UIColor.clear.cgColor
       }
}
