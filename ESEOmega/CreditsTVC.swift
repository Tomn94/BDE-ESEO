//
//  CreditsTVC.swift
//  ESEOmega
//
//  Created by Tomn on 08/09/2017.
//  Copyright © 2017 Thomas NAUDET. All rights reserved.

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
    /// Done button tapped
    static let close = #selector(CreditsTVC.close)
}


class CreditsTVC: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Crédits"
        tableView.emptyDataSetSource   = self
        tableView.emptyDataSetDelegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Fermer", style: .done,
                                                            target: self, action: .close)
        
        /* ¯\_(ツ)_/¯ */
        let imageView = UIImageView(image: #imageLiteral(resourceName: "ron"))
        imageView.frame = CGRect(x: 0, y: -100,
                                 width: view.bounds.width, height: 113)
        imageView.autoresizingMask = .flexibleWidth
        imageView.contentMode = .scaleAspectFit
        tableView.addSubview(imageView)
    }
    
    
    // MARK: - Actions
    
    func contact() {
        
        Data.shared().mail("tom" + "n72@gm"
                           + "ail.com", currentVC: self)
    }
    
    @objc func close() {
        
        dismiss(animated: true)
    }
    
}

extension CreditsTVC {
    
    override func numberOfSections(in tableView: UITableView) -> Int {

        return 0  // always show empty data set
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 0  // always show empty data set
    }
    
}


// MARK: Empty Data Set Source
extension CreditsTVC: DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "credits")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return NSAttributedString(string: " ")
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let text = """
© Thomas NAUDET pour ESEOmega
Collection Été 2015 - Hiver 2016
Hiver 2016 - 2017 pour ESEOasis
Été 2017 pour ESEOdin
Une question, un problème ? ↓
"""
        
        let subheadDescriptor     = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        let boldSubheadDescriptor = subheadDescriptor.withSymbolicTraits(.traitBold) ?? subheadDescriptor
        
        let mas = NSMutableAttributedString(string: text,
                                     attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline),
                                                  .foregroundColor : UIColor.lightGray])
        
        let boldAttr = [NSAttributedStringKey.font : UIFont(descriptor: boldSubheadDescriptor, size: 0)]
        mas.setAttributes(boldAttr, range: NSMakeRange(2,  13))
        mas.setAttributes(boldAttr, range: NSMakeRange(117, 29))
        
        return mas
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        
        return NSAttributedString(string: "Contacter",
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .headline),
                                               .foregroundColor : UINavigationBar.appearance().barTintColor ?? .blue])
    }
}


// MARK: Empty Data Set Delegate
extension CreditsTVC: DZNEmptyDataSetDelegate {
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        
        contact()
    }
    
}


// MARK: Mail Compose View Controller Delegate
extension CreditsTVC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
        dismiss(animated: true)
    }
    
}
