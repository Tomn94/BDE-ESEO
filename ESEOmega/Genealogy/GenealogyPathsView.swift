//
//  GenealogyPathsView.swift
//  ESEOmega
//
//  Created by Thomas Naudet on 04/11/2016.
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

import UIKit

class GenealogyPathsView: UIView {
    
    private let minLabelHeight: CGFloat = 35
    private let topMargin:      CGFloat =  5
    private let pathWidth:      CGFloat =  3
    
    var family: [[Student]] = []
    
    var currentRank: Int?
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let width = rect.width
        let height = rect.height
        
        guard let rank = currentRank, rank < family.count
            else { return }
        
        /* Enumerate for each student on a line */
        let brothers = family[rank]
        for (index, student) in brothers.enumerated() {
            
            /* Get the horizontal center of its label */
            let x = xFrom(index: index, nbrItems: brothers.count, width: width)
            let center = CGPoint(x: x, y: height / 2)
            
            /* Draw TOP line if it has parents */
            let parents = student.parents
            if !parents.isEmpty {
                /* Compute the sum of each X from the student's parents */
                var xTopBaricenter: CGFloat = 0
                if rank > 0 {
                    let elderly = family[rank - 1]
                    for (oldIndex, oldOne) in elderly.enumerated() {
                        if oldOne.children.contains(student.id) {
                            xTopBaricenter += xFrom(index: oldIndex, nbrItems: elderly.count, width: width)
                        }
                    }
                }
                
                /* And do the average */
                xTopBaricenter /= CGFloat(student.parents.count)
                let topBaricenter = CGPoint(x: xTopBaricenter, y: 0)
                
                /* And draw on the view */
                drawLink(from: CGPoint(x: center.x, y: center.y - (minLabelHeight / 2) + topMargin),
                         to: topBaricenter)
            }
            
            /* Draw BOTTOM line if it has children */
            if !student.children.isEmpty {
                /* Analyze brothers to see which ones have the same children
                   Then do the sum of each X from brothers found */
                var xBottomBaricenter: CGFloat = 0
                var nbrBrotherWithChildren = 0  // Incest
                for (brotherIndex, brother) in brothers.enumerated() {
                    /* The brother has children in common with current student */
                    if !Set(brother.children).intersection(Set(student.children)).isEmpty {
                        xBottomBaricenter += xFrom(index: brotherIndex, nbrItems: brothers.count, width: width)
                        nbrBrotherWithChildren += 1
                    }
                }
                
                /* And do the average */
                if nbrBrotherWithChildren > 0 {
                    xBottomBaricenter /= CGFloat(nbrBrotherWithChildren)
                } else { // Fallback to the center of the current student label if no common children
                    xBottomBaricenter = x
                }
                let bottomBaricenter = CGPoint(x: xBottomBaricenter, y: height)
                
                /* And draw on the view */
                drawLink(from: CGPoint(x: center.x, y: center.y + (minLabelHeight / 2) + topMargin - 1),
                         to: bottomBaricenter)
            }
        }
    }
    
    /**
     Simply set color and draw the given path
     - Parameter path: Path to draw
    */
    func drawLink(from start: CGPoint, to end: CGPoint) {
        
        let ctrlPt1 = CGPoint(x: start.x, y: end.y)
        let ctrlPt2 = CGPoint(x: end.x, y: start.y)
        
        /* Create the line */
        let path = UIBezierPath()
        path.move(to: start)
        path.addCurve(to: end, controlPoint1: ctrlPt1, controlPoint2: ctrlPt2)
        
        /* Set characteristics of the line and validate */
        var pathColor = UIColor.gray
        var hue: CGFloat = 0.0; var saturation: CGFloat = 0.0; var brightness: CGFloat = 0.0; var alpha: CGFloat = 0.0
        if let color = UINavigationBar.appearance().barTintColor,
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            pathColor = UIColor(hue: hue,
                                saturation: saturation - 0.15,
                                brightness: brightness + 0.15,
                                alpha: alpha)
        }
        pathColor.setStroke()
        path.lineWidth = pathWidth
        path.stroke()
    }
    
    /**
     Get horizontal center value from a centered item in a stack view
     - Parameters:
        - index: Position of the item in the list
        - nbrItems: Total number of items in the list
        - width: Scale of the horizontal list
     - Returns: the x value of the center of the item at index
     */
    func xFrom(index: Int, nbrItems: Int, width: CGFloat) -> CGFloat {
        
        let shiftIndex = CGFloat(index * 2) + 1
        let centerDivider = CGFloat(nbrItems) * 2
        return shiftIndex * width / centerDivider
    }
}
