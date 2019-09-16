//
//  DocumentsCVC.swift
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
import SwiftUI

private let reuseIdentifier = "cell"

class DocumentsCVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Constants
    
    let sections = ["Prépa Intégrée 🤓", "Cycle Ingénieur 🤩", "Bachelor 🆕"]
    
    let colors = [[#colorLiteral(red: 0.2494148612, green: 0.8105323911, blue: 0.8425348401, alpha: 1),#colorLiteral(red: 0, green: 0.6073564887, blue: 0.7661359906, alpha: 1)], [#colorLiteral(red: 0.9654200673, green: 0.1590853035, blue: 0.2688751221, alpha: 1),#colorLiteral(red: 0.7559037805, green: 0.1139892414, blue: 0.1577021778, alpha: 1)], [#colorLiteral(red: 0.9953531623, green: 0.54947716, blue: 0.1281470656, alpha: 1),#colorLiteral(red: 0.9409626126, green: 0.7209432721, blue: 0.1315650344, alpha: 1)]]
    
    // MARK: - UI
    
    /// Black color for the title
    let titleAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupCollectionView()
        
        if #available(iOS 13.0, *) {
            // Show the onboarding view, made with SwiftUI
            if !UserDefaults.standard.bool(forKey: "didShowOnboarding") {
                let onboardingController = UIHostingController(rootView: OnboardingView())
            
                self.present(onboardingController, animated: true) {
                    UserDefaults.standard.set(true, forKey: "didShowOnboarding")
                }
            }
            
            
        }

        
    }
    
    fileprivate func setupNavigationBar() {
        /// Set up the NavBar
        let navigationBar = navigationController!.navigationBar
        navigationBar.tintColor = .white
        navigationBar.backgroundColor = .white
        /// Hide the thin separator view between the navigation bar and the view itself
        navigationBar.shadowImage = UIImage()
        
        /// NavigationBar title color
        navigationBar.titleTextAttributes = titleAttributes

    }
    
    fileprivate func setupCollectionView() {
        
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
        }
        
        collectionView?.register(DocumentsCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.alwaysBounceVertical = true
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return grades.count
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return grades[section].count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! DocumentsCollectionViewCell
        
        cell.listNameLabel.text = grades[indexPath.section][indexPath.item].name
        cell.iconImageView.image = UIImage(named: "Folder")
        
        cell.contentView.setGradientBackgroundColor(colorOne: colors[indexPath.section][0], colorTwo: colors[indexPath.section][1])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: ((view.frame.width / 2) - 20), height: 110)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "showYears", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let detailController = segue.destination as? YearsDetailCVC, let index = collectionView?.indexPathsForSelectedItems?.first else { return }
        
        detailController.yearRank = grades[index.section][index.item]
        detailController.colors = colors[index.section]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 8, left: 8, bottom: 8, right: 8)
    }
       
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "titleDocumentsHeader", for: indexPath) as! DocumentsCollectionReusableView
            
            header.titleLabel.text = sections[indexPath.section]
            
            return header
        }
        
        if kind == UICollectionElementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footerView", for: indexPath) as! DocumentsFooter
            
            return footer
        }

           return UICollectionReusableView()

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section != 2 {
            return .zero
        }
        
        return CGSize(width: UIScreen.main.bounds.width, height: 62)
    }
}


