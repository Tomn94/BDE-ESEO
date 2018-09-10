//
//  SponsorsCell.swift
//  BDE-ESEO
//
//  Created by Benjamin Gondange on 10/09/2018.
//  Copyright © 2018 Benjamin Gondange

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

class SponsorsCell: UITableViewCell {

    @IBOutlet var nomLabel: UILabel?
    @IBOutlet var descLabel: UILabel?
    @IBOutlet var contactLabel: UILabel?
    @IBOutlet var logoView: UIImageView?
    @IBOutlet var bonsPlansView: UITextView?
    
    var avantages: [String]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func setAvantages(avt: [String]) {
        avantages = avt
        if (avt.count < 1) {
            self.bonsPlansView?.text = ""
        } else {
            self.bonsPlansView?.text = String(format: "✅ %@", avt.joined(separator: "\n✅ ")).replacingOccurrences(of: "\\n", with: "\n")
            self.bonsPlansView?.textColor = UIColor.darkGray
            self.bonsPlansView?.font = UIFont.systemFont(ofSize: 13)
            self.bonsPlansView?.layoutManager.delegate = self
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension SponsorsCell: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager,
                       lineSpacingAfterGlyphAt glyphIndex: Int,
                       withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return 7
    }
}
