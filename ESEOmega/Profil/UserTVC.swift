//
//  UserTVC.swift
//  ESEOmega
//
//  Created by Thomas Naudet on 24/01/2017.
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


/// <#Description#>
class ImagePickerController: UIImagePickerController {
    
    
    
}


/// <#Description#>
class UserTVC: JAQBlurryTableViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    // MARK: - Constants
    
    /// <#Description#>
    let maxAttempts = 5
    
    /// <#Description#>
    let imgSize = UIScreen.main.bounds.size.height < 500 ? 120 : 170
    
    
    // MARK: - UI
    
    @IBOutlet weak var mailField: UITextField!
    
    @IBOutlet weak var passField: UITextField!
    
    @IBOutlet weak var sendCell: UITableViewCell!
    
    @IBOutlet var spin: UIActivityIndicatorView!
    
    @IBOutlet var spinBtn: UIBarButtonItem!
    
    var logoutBtn: UIBarButtonItem!
    
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendCell.textLabel?.textColor = UINavigationBar.appearance().barTintColor
        configureSendCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    func loadUI() {
        
    }
    
    func configureSendCell() {
        
        var tappable = true
        
        sendCell.textLabel?.isEnabled = tappable
        sendCell.selectionStyle = tappable ? .default : .none
    }
    
    func refreshEmptyDataSet() {
        
    }
    
    @IBAction func close(_ sender: Any) {
        
    }
    
    
    // MARK: - Actions
    
    func connect()  {
        
    }
    
    func disconnect() {
        
    }
    
    func choosePhoto() {
        
    }
    
    func removePhoto() {
        
    }
    
    func showPhotos() {
        
    }
    
    func forgetTel() {
        
    }
    
    
    // MARK: - Table View Controller delegate
    
    /// Set every section to be displayed, zero if Empty Data Set
    ///
    /// - Parameters:
    ///   - tableView: The table view containing the sections
    /// - Returns: Total number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        /* Display Empty Data Set if connected */
        if Data.estConnecte() {
            return 0
        }
        /* Otherwise display Form and Send sections */
        return 2
    }
    
    /// Returns a different number of rows depending on the section
    ///
    /// - Parameters:
    ///   - tableView: The table view containing the rows
    ///   - section: Index of the section we want to populate
    /// - Returns: Number of rows in a given section
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {

        if Data.estConnecte() {
            /* Display Empty Data Set if connected */
            return 0
        }
        else if section == 0 {
            /* Otherwise display form fields in the 1st section */
            return 2
        }
        
        /* Display Send form button at the bottom of the 1st section */
        return 1
    }
    
    /// Reacts depending on the row tapped
    ///
    /// - Parameters:
    ///   - tableView: The table view getting hit
    ///   - indexPath: Position of the selected row
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        /* Only react to Send form button */
        if indexPath.section == 1 && indexPath.row == 0 {
            connect()
        }
    }
    
    
    // MARK: - Text Field delegate
    
    /// Behavior of the text field when the Return key is pressed
    ///
    /// - Parameter textField: Text field where the event is occurring
    /// - Returns: No, the text field doesn't support multiline text
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if mailField.isFirstResponder {
            /* If the focus is on the mail field, focus the next one */
            passField.becomeFirstResponder()
        } else {
            /* End of the form after the password field, thus validate */
            connect()
        }
        
        /* Don't add return character */
        return false
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - textField: <#textField description#>
    ///   - range: <#range description#>
    ///   - string: <#string description#>
    /// - Returns: <#return value description#>
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        
        return true
    }
    
    
    // MARK: - Pop Over delegate
    
    /// <#Description#>
    ///
    /// - Parameter controller: <#controller description#>
    /// - Returns: <#return value description#>
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        /* */
        return .none
    }
    
    
    // MARK: - Image Picker delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    
    // MARK: - Navigation Controller delegate
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
    }
    
    
    // MARK: - Empty Data Set delegate
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return nil
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return nil
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return nil
    }
    
}
