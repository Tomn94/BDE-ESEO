//
//  GenealogyPathsView.swift
//  ESEOmega
//
//  Created by Tomn on 04/11/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class GenealogyPathsView: UIView
{
    let margins: CGFloat = 5
    let pathWidth: CGFloat = 3
    let pathColor = UINavigationBar.appearance().barTintColor ?? UIColor.gray
    var family: [[Student]] = []
    var currentRank: Int?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let width = rect.width
        let height = rect.height
        
        if let rank = currentRank, rank < family.count {
            /* Enumerate for each student on a line */
            let brothers = family[rank]
            for (index, student) in brothers.enumerated() {
                
                /* Get the horizontal center of its label */
                let x = xFrom(index: index, nbrItems: brothers.count, width: width)
                let center = CGPoint(x: x, y: height / 2)
                
                
                /* Draw top line if it has parents */
                let parents = student.parents
                if !parents.isEmpty {
                    let path = UIBezierPath()
                    
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
                    
                    /* Then draw a straight line */
                    path.move(to: center)
                    path.addLine(to: topBaricenter)
                    
                    draw(path)
                }
                
                /* Draw bottom line if it has children */
                if !student.children.isEmpty {
                    let path = UIBezierPath()
                    
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
                    
                    /* Then draw a straight line */
                    path.move(to: center)
                    path.addLine(to: bottomBaricenter)
                    
                    draw(path)
                }
            }
        }
    }
    
    /**
     Simply set color and draw the given path
     - parameter path: Path to draw
    */
    func draw(_ path: UIBezierPath) {
        path.close()
        path.lineWidth = pathWidth
        pathColor.setStroke()
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
