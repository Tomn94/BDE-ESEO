//
//  YearsDetailCVC.swift
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

private let reuseIdentifier = "cell"

class YearsDetailCVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var yearRank: YearRank = YearRank(name: "", years: [""], urls: [""])
    var colors = [UIColor]()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView!.backgroundColor = .white

        
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return yearRank.years.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 8, left: 8, bottom: 8, right: 8)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! YearCollectionViewCell
    
        // Configure the cell
        cell.listNameLabel.text = yearRank.years[indexPath.item]
        cell.layer.cornerRadius = 15
        cell.backgroundColor = .systemPink
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: ((view.frame.width / 2) - 20), height: 110)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Open PDF from URL
        if #available(iOS 11.0, *) {
            // Load before displaying the pdf
            performSegue(withIdentifier: "showPDF", sender: self)
        } else {
            let alertController = UIAlertController(title: "Erreur", message: "Tu dois être sur iOS 11.0 ou ultérieur pour afficher les documents.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if #available(iOS 11.0, *) {
            guard let detailController = segue.destination as? PDFViewController, let index = collectionView?.indexPathsForSelectedItems?.first else { return }
            
            let urlString = yearRank.urls[index.item]
            detailController.urlString = urlString
        }
        
        
    }

}
