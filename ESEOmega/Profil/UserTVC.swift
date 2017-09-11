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


fileprivate extension Selector {
    
    /// Logoff button
    static let disconnect  = #selector(UserTVC.disconnect)
    
    /// Tap on user pic
    static let changePhoto = #selector(UserTVC.changePhoto)
    
}


/// User profile view.
/// If connected, displays user's avatar, name, phone number…
/// If not, features a connection form.
class UserTVC: JAQBlurryTableViewController {
    
    // MARK: - Constants
    
    /// Default domain name for mail addresses (used in autocomplete and placeholders)
    static let mailDomain = "reseau.eseo.fr"
    
    /// Some indications on how to fill the mail field. "@reseau.eseo.fr" is automatically added
    static let mailPlaceholders = ["tyrion.lannister", "john.snow", "arya.stark", "walter.white", "jesse.pinkman", "ron.swanson", "abed.nadir", "kenny.mccormick", "mulder.fox", "saul.goodman", "asher.roth", "archer.sterling", "rick.morty", "sam.sepiol", "elliot.alderson", "joe.macmillan", "gordon.clark", "cameron.howe", "donna.clark"]
    
    /// User picture diameter size
    static let avatarImgSize: CGFloat = 170
    
    /// Maximum number of attempts for an user to connect at once
    static let maxAttempts = 5
    
    /// Number of seconds before another set of attempts is given
    static let maxAttemptsWaitingTime: Double = 300
    
    /// Current number of connection attempts
    static var attemptsNbr = 0
    
    /// Time interval of connection attempt that hit the maximum. Init with a random past value
    static var lastMaxAttempt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.timeIntervalSinceReferenceDate
    
    /// Number of rows (options) in the table view dedicated to settings when logged
    static let optionsNbr = 2
    
    /// Top space between the settings table view and the empty data set text when logged
    static let optionsTableMargin: CGFloat = 26
    
    /// Vertical position of the settings table view when logged
    static let optionsTableYPos: CGFloat = 243 + UserTVC.optionsTableMargin
    
    
    // MARK: UI
    
    /// When not connected, represents the field for the user to enter their mail address
    @IBOutlet weak var mailField: UITextField!
    
    /// When not connected, represents the field for the user to enter their password
    @IBOutlet weak var passField: UITextField!
    
    /// When not connected, represents the field for the user to enter their mail address
    @IBOutlet weak var sendCell: UITableViewCell!
    
    /// When connecting, the displayed loading icon
    @IBOutlet var spin: UIActivityIndicatorView!
    
    /// When connecting, container of the spin icon in the navigation bar
    @IBOutlet var spinBtn: UIBarButtonItem!
    
    /// When connected, logout button in the navigation bar
    var logoutBtn: UIBarButtonItem!
    
    /// When connected, display a list of options
    var optionsTable: UITableView!
    
    /// optionsTable data source retained delegate
    let optionsTableDelegate = UserTVDelegate()
    
    /// optionsTable data source retained data source
    let optionsTableDataSource = UserTVDataSource()
    
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Configure Logout button action */
        logoutBtn = UIBarButtonItem(title: "Déconnexion", style: .plain,
                                    target: self, action: .disconnect)
        
        /* Make the UILabel look like a UIButton */
        sendCell.textLabel?.textColor = UINavigationBar.appearance().barTintColor
        /* No current text entry, so disable the Connect button */
        configureSendCell(mail: mailField.text, password: passField.text)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadUI()
        refreshEmptyDataSet()
    }
    
    /// Configure navigation bar and mail placeholder depending on the current connection state
    func loadUI() {
        
        /* Use logout button if connected */
        var currentBarButton = logoutBtn
        
        /* If disconnected */
        if !DataStore.isUserLogged {
            /* Set spin button used while connecting instead */
            currentBarButton = spinBtn
            
            /* Choose a random placeholder */
            changeMailPlaceholder()
            
            /* Display ESEO building as a banner above login form */
            self.configureBanner(with: #imageLiteral(resourceName: "batiment"),
                                 blurRadius: 0, blurTintColor: UIColor.clear, saturationFactor: 1,
                                 maxHeight: 157)
        }
        
        /* Create options table (displayed when logged) */
        optionsTable = UITableView(frame: CGRect(x: 0, y: UserTVC.optionsTableYPos,
                                                     width: self.tableView.frame.size.width,
                                                     height: CGFloat(UserTVC.optionsNbr * 44) - 1),
                                       style: .plain)
        optionsTable.autoresizingMask = .flexibleWidth
        optionsTable.delegate   = optionsTableDelegate
        optionsTable.dataSource = optionsTableDataSource
        optionsTable.isScrollEnabled = false
        optionsTableDelegate.userTVC = self
        
        /* Validate navigation bar changes */
        self.navigationItem.setLeftBarButton(currentBarButton, animated: true)
    }
    
    /// Randomizes a new placeholder for the mail field
    func changeMailPlaceholder() {
        
        /* Choose one random among predefined ones */
        let index = Int(arc4random_uniform(UInt32(UserTVC.mailPlaceholders.count)))
        mailField.placeholder = UserTVC.mailPlaceholders[index] + "@" + UserTVC.mailDomain
    }
    
    /// Called when text in fields is edited.
    /// Includes text deletion.
    @IBAction func textFieldEdited() {
        
        configureSendCell(mail:     mailField.text,
                          password: passField.text)
    }
    
    /// Visually enable or disable the Send button if the text inputs are empty
    ///
    /// - Parameters:
    ///   - mail: The text from the mail field
    ///   - password: The text from the password field
    func configureSendCell(mail: String?, password: String?) {
        
        /* Connect button not enabled by default */
        var tappable = false
        
        /* If available, get the text from the cell */
        if let mail     = mail,
           let password = password {
            /* Trim whitespaces from mail, and enable the cell if the result of each is not empty */
            tappable = !mail.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
        }
        
        /* Apply changes */
        DispatchQueue.main.async {
            self.sendCell.textLabel?.isEnabled     = tappable
            self.sendCell.isUserInteractionEnabled = tappable
            self.sendCell.selectionStyle           = tappable ? .default : .none
        }
    }
    
    /// Set avatar shape and tap reactions on the empty data set elements
    func refreshEmptyDataSet() {
        
        /* Reinit the view */
        self.tableView.contentInset.bottom = 0  // avoid offset calculation interferences
        self.tableView.reloadEmptyDataSet()
        
        /* Set avatar round aspect */
        self.tableView.emptyDataSetView.imageView.layer.cornerRadius = UserTVC.avatarImgSize / 2
        self.tableView.emptyDataSetView.imageView.clipsToBounds = true
        self.tableView.emptyDataSetView.imageView.layer.borderWidth = 4
        self.tableView.emptyDataSetView.imageView.layer.borderColor = UIColor.white.cgColor
        
        /* The picture reacts to tap interactions */
        let picTapRecognizer = UITapGestureRecognizer(target: self, action: .changePhoto)
        self.tableView.emptyDataSetView.imageView.isUserInteractionEnabled = true
        self.tableView.emptyDataSetView.imageView.addGestureRecognizer(picTapRecognizer)
        
        /* Add options view */
        self.tableView.emptyDataSetView.contentView.addSubview(optionsTable)
        /* Allow inner selection and ensure the view is always visible (scrollable to) */
        self.tableView.emptyDataSetView.contentView.frame.size.height += UserTVC.optionsTableMargin + optionsTable.frame.height
        self.tableView.emptyDataSetView.tapGesture.cancelsTouchesInView = false
        if DataStore.isUserLogged {
            self.tableView.contentInset.bottom = UserTVC.optionsTableYPos + CGFloat(UserTVC.optionsNbr * 44) + 80
        }
        optionsTable.reloadData()
    }
    
    /// Closes this whole profile view
    ///
    /// - Parameter sender: Unused
    @IBAction func close(_ sender: Any? = nil) {

        /* Animate keyboard while closing */
        mailField.resignFirstResponder()
        passField.resignFirstResponder()
        
        self.dismiss(animated: true)
    }
    
    /// Fade any change of the empty data set
    func animateChange() {
        
        /* Make a simple transition */
        let animation = CATransition()
        animation.duration = 0.42
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.tableView.layer.add(animation, forKey: nil)
    }
    
}


// MARK: - Table View Controller data source & delegate

extension UserTVC {
    
    // MARK: TVC data source
    
    /// Set every section to be displayed, zero if Empty Data Set
    ///
    /// - Parameter tableView: The table view containing the sections
    /// - Returns: Total number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        /* Display Empty Data Set if connected */
        if DataStore.isUserLogged {
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

        if DataStore.isUserLogged {
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
    
    // MARK: TVC delegate
    
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
    
}


// MARK: - Text Field delegate

extension UserTVC: UITextFieldDelegate {
    
    /// Behavior of the text field when the Return key is pressed.
    /// Helps going from one field to another, then return
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
    
    /// Updates the availability of the Send button when the text changes.
    /// Also autocompletes the mail address with the domain when the user types '@'
    ///
    /// - Parameters:
    ///   - textField: Text field being edited
    ///   - range: Part of the text to be replaced
    ///   - string: The part of the text that has just been typed/pasted or "" if erased
    /// - Returns: Whether the previous text should be replaced after this method
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        /* Return value to override if text set manually */
        var shouldAutoUpdateField = true
        
        /* Get previous text values */
        var mailTxt = mailField.text ?? ""
        var passTxt = passField.text ?? ""
        
        /* Get the new text value being considered */
        let proposedStr = ((textField.text ?? "") as NSString).replacingCharacters(in: range,
                                                                                   with: string)
        
        /* Operations on the mail field (which tag is 0) */
        if textField.tag == 0 {
            
            /* Add "reseau.eseo.fr" right after the user types '@' */
            if string == "@" &&                 // a @ has just been typed
               !mailTxt.contains("@") &&        // autocomplete just once
               proposedStr.hasSuffix("@") {     // the @ is at the end
                /* Update the text field */
                mailField.text = proposedStr + UserTVC.mailDomain
                shouldAutoUpdateField = false
            }
            
            /* Find another placeholder if the user clears the field */
            if proposedStr == "" {
                changeMailPlaceholder()
            }
            
            /* Assign the new value to the mail field */
            mailTxt = proposedStr
            
        } else {
            /* Otherwise assign the new value to the pass field (tag 1) */
            passTxt = proposedStr
        }
        
        configureSendCell(mail: mailTxt, password: passTxt)
        
        return shouldAutoUpdateField
    }
    
}


// MARK: - Empty Data Set delegate

extension UserTVC: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    /// When the user is connected, displays the user's avatar or a default picture
    ///
    /// - Parameter scrollView: UserTVC table view
    /// - Returns: The user's picture
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        /* Get the user avatar if available */
        if let picData = getPhoto() {
            return UIImage(data: picData)
        }
        
        /* Default image */
        return #imageLiteral(resourceName: "defaultUser")
    }
    
    /// When the user is connected, sets up the text description and its style
    ///
    /// - Parameter scrollView: UserTVC table view
    /// - Returns: Returns the stylized text header of the empty data set
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        /* Say hello to the user if we have their name */
        if let username = JNKeychain.loadValue(forKey: KeychainKey.name) as? String {
            
            let welcomeString = "Bonjour\n" + username
            
            /* Return the string with some style */
            return NSAttributedString(string: welcomeString,
                                      attributes: [.foregroundColor : UIColor.darkGray])
        }
        
        return NSAttributedString(string: "", attributes: [:])
    }
    
    /// When the user is connected, sets up the text description and its style
    ///
    /// - Parameter scrollView: UserTVC table view
    /// - Returns: Returns the stylized text body of the empty data set
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        /* Let the table view be above */
        var tip = ""
        for _ in 0 ..< UserTVC.optionsNbr {
            tip += "\n\n\n"
        }
        
        tip += "Vous avez accès à toutes les fonctionnalités, dont la commande à la cafétéria/événements et les notifications."
        
        return NSAttributedString(string: tip,
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline),
                                               .foregroundColor : UIColor.lightGray])
    }
    
}
