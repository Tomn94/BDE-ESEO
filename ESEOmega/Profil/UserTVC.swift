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

// MARK: - UserTVC actions
fileprivate extension Selector {
    static let disconnect  = #selector(UserTVC.disconnect)  // Logoff button
    static let changePhoto = #selector(UserTVC.changePhoto) // Tap on user pic
    static let forgetTel   = #selector(UserTVC.forgetTel)   // Tap on telephone number
}


/// User profile view.
/// If connected, displays user's avatar, name, phone number…
/// If not, features a connection form.
class UserTVC: JAQBlurryTableViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    // MARK: - Constants
    
    /// Maximum number of attempts for an user to connect at once
    let maxAttempts = 5
    
    /// Current number of connection attempts
    var attemptsNbr = 0
    
    /// Time interval of last connection attempt. Init with a random past value
    var lastAttempt = Calendar.current.date(byAdding: .day, value: -1, to: Date())?.timeIntervalSinceReferenceDate
    
    /// User picture diameter size
    let avatarImgSize: CGFloat = UIScreen.main.bounds.size.height < 500 ? 120 : 170
    
    /// Some indications on how to fill the mail field. "@reseau.eseo.fr" is automatically added
    let mailPlaceholders = ["tyrion.lannister", "john.snow", "arya.stark", "walter.white", "jesse.pinkman", "ron.swanson", "abed.nadir", "kenny.mccormick", "mulder.fox", "saul.goodman", "asher.roth", "archer.sterling", "rick.morty", "sam.sepiol", "elliot.alderson"]
    
    
    // MARK: - UI
    
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
    let logoutBtn = UIBarButtonItem(title: "Déconnexion", style: .plain, target: self, action: .disconnect)
    
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Get an eventual last try back, so the user cannot close and reopen this view to bypass it */
        if let lastSavedAttempt = Data.shared().tooManyConnect {
            lastAttempt = lastSavedAttempt.timeIntervalSinceReferenceDate
        }
        
        /* Make the UILabel look like a UIButton */
        sendCell.textLabel?.textColor = UINavigationBar.appearance().barTintColor
        /* No current text entry, so disable the Connect button */
        configureSendCell(mail: mailField.text, password: passField.text)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        loadUI()
        self.configureBanner(with: #imageLiteral(resourceName: "batiment"),
                             blurRadius: 0, blurTintColor: UIColor.clear, saturationFactor: 1,
                             maxHeight: 157)
        refreshEmptyDataSet()
    }
    
    /// Configure navigation bar and mail placeholder depending on the current connection state
    func loadUI() {
        
        /* Use logout button if connected */
        var currentBarButton = logoutBtn
        
        /* If disconnected */
        if !Data.estConnecte() {
            /* Set spin button used while connecting instead */
            currentBarButton = spinBtn
            
            /* Choose a random placeholder */
            let index = Int(arc4random_uniform(UInt32(mailPlaceholders.count)))
            mailField.placeholder = mailPlaceholders[index] + "@reseau.eseo.fr"
        }
        
        /* Validate navigation bar changes */
        self.navigationItem.setLeftBarButton(currentBarButton, animated: true)
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
        if let mail = mail,
           let password = password {
            /* Trim whitespaces and enable the cell if the result of each is not empty */
            tappable =     mail.trimmingCharacters(in: .whitespaces) != "" &&
                       password.trimmingCharacters(in: .whitespaces) != ""
        }
        
        /* Apply changes */
        sendCell.textLabel?.isEnabled = tappable
        sendCell.selectionStyle = tappable ? .default : .none
    }
    
    /// Set avatar shape and tap reactions on the empty data set elements
    func refreshEmptyDataSet() {
        /* Reinit the view */
        self.tableView.reloadEmptyDataSet()
        
        /* Set avatar round aspect */
        self.tableView.emptyDataSetView.imageView.layer.cornerRadius = avatarImgSize / 2
        self.tableView.emptyDataSetView.imageView.clipsToBounds = true
        self.tableView.emptyDataSetView.imageView.layer.borderWidth = 4
        self.tableView.emptyDataSetView.imageView.layer.borderColor = UIColor.white.cgColor
        
        /* The picture reacts to tap interactions */
        let picTapRecognizer = UITapGestureRecognizer(target: self, action: .changePhoto)
        self.tableView.emptyDataSetView.imageView.isUserInteractionEnabled = true
        self.tableView.emptyDataSetView.imageView.addGestureRecognizer(picTapRecognizer)
        
        /* The detail text (phone number) also reacts to tap */
        let telTapRecognizer = UITapGestureRecognizer(target:self, action: .forgetTel)
        self.tableView.emptyDataSetView.detailLabel.isUserInteractionEnabled = true
        self.tableView.emptyDataSetView.detailLabel.addGestureRecognizer(telTapRecognizer)
    }
    
    /// Closes this whole profile view
    ///
    /// - Parameter sender: Unused
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Actions
    
    func connect()  {
        
    }
    
    func disconnect() {
        
    }
    
    /// Finds the path to the user's avatar on disk
    ///
    /// - Returns: The URL of the image, if available
    func getPhotoURL() -> URL? {
        
        /* Get documents directory */
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if paths.count > 0 {
            let documentsDirectory = paths[0]
            
            /* The image file is stored right inside this documents directory */
            return NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent("imageProfil.png")
        }
        
        return nil
    }
    
    /// Load the user's avatar from disk
    ///
    /// - Returns: The data of the image, if available
    func getPhoto() -> Foundation.Data? {
        
        /* Get the URL of the image file */
        if let avatarURL = getPhotoURL() {
            do {
                /* Read data and return */
                return try Foundation.Data(contentsOf: avatarURL)
            } catch {}
        }
        
        return nil
    }
    
    /// Asks the user whether they want to change or delete their avatar
    func changePhoto() {
        /* Make sure there's already a picture */
        guard getPhoto() != nil else { return }
        
        /* Ask what action to do */
        let sheet = UIAlertController(title: "Changer l'image de profil",
                                      message: "",
                                      preferredStyle: .actionSheet)
        
        /* Configure actions */
        sheet.addAction(UIAlertAction(title: "Supprimer la photo", style: .destructive, handler: { _ in
            self.removePhoto()
        }))
        sheet.addAction(UIAlertAction(title: "Choisir une photo", style: .default, handler: { _ in
            //OperationQueue.main.addOperation {
            self.selectPhoto()
            //}
        }))
        sheet.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    /// Displays a standard photo picker to select a new avatar
    func selectPhoto() {
        
        /* The user will select a photo from the photos they have already taken */
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
        
            /* Create an instance of an iOS image picker */
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            
            /* Show the picker in a pop-over on iPad, fullscreen if not */
            if Data.isiPad(),
               let avatarView = self.tableView.emptyDataSetView.imageView,
               let popPresentCtrl = imagePicker.popoverPresentationController {
                
                /* Configure the picker as a pop-over */
                imagePicker.modalPresentationStyle = .popover
                
                /* Place the pop-over on the screen */
                popPresentCtrl.sourceRect = avatarView.convert(avatarView.bounds, to: UIApplication.shared.windows[0])
                popPresentCtrl.sourceView = imagePicker.view
                popPresentCtrl.permittedArrowDirections = .any
                
                self.present(imagePicker, animated: true, completion: nil)
                
            } else {
                self.present(imagePicker, animated: true, completion: {
                    /* Apply light status bar style to the image picker */
                    UIApplication.shared.statusBarStyle = .lightContent
                })
            }
        }
    }
    
    /// Deletes the current user picture from disk without confirmation
    func removePhoto() {
        
        /* If the user has currently an avatar */
        if let avatarURL = getPhotoURL() {
            do {
                /* Delete it from disk */
                try FileManager.default.removeItem(at: avatarURL)
            } catch let error {
                /* Display an error message if any issue arises */
                let alert = UIAlertController(title: "Impossible de supprimer l'image",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        /* Commit any change to the view */
        self.refreshEmptyDataSet()
    }
    
    /// Asks the user to confirm the deletion of their stored phone number
    func forgetTel() {
        
        /* Display action sheet to confirm deletion.
           Action sheets are more appropriate than alerts for deletion on iOS */
        let alert = UIAlertController(title: "Voulez-vous oublier le numéro de téléphone ?",
                                      message: "Votre numéro de téléphone portable est utilisé par Lydia afin de lier vos commandes à votre compte. Il n'est pas stocké sur nos serveurs.\nUn nouveau numéro vous sera demandé au prochain achat cafet/event via Lydia.\n\nCependant lorsque vous vous inscrivez à un événement (sans utiliser Lydia), ce numéro est communiqué au BDE.", preferredStyle: .actionSheet)
        
        /* Destructive type button to confirm */
        alert.addAction(UIAlertAction(title: "Supprimer", style: .destructive, handler: { _ in
            /* Delete stored value, and remove the phone number from the view */
            JNKeychain.deleteValue(forKey: "phone")
            self.refreshEmptyDataSet()
        }))
        
        /* Add also a Cancel button, and present inside this view controller */
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        
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
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    
    // MARK: - Navigation Controller delegate
    
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        
    }
    
    
    // MARK: - Empty Data Set delegate
    
    /// When the user is connected, displays the user's avatar or a default picture
    ///
    /// - Parameter scrollView: UserTVC table view
    /// - Returns: <#return value description#>
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        let screenSize = UIScreen.main.bounds.size
        
        /* Hide picture if landscape */
        if !Data.isiPad() &&
           (UIDeviceOrientationIsLandscape(UIDevice.current.orientation) ||
            screenSize.width > screenSize.height) {
            return nil
        }
        
        /* Get the user avatar if available */
        if let picData = getPhoto() {
            return UIImage(data: picData)
        }
        
        /* Return default image with smaller size on iPhone 4 */
        if screenSize.height < 500 {
            return Data.scaleAndCropImage(#imageLiteral(resourceName: "defaultUser"), to: CGSize(width: avatarImgSize, height: avatarImgSize), retina: false)
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
        if let username = JNKeychain.loadValue(forKey: "uname") as? String {
            
            let welcomeString = "Bonjour\n" + username
            
            /* Return the string with some style */
            return NSAttributedString(string: welcomeString,
                                      attributes: [NSForegroundColorAttributeName : UIColor.darkGray,
                                                   NSFontAttributeName : UIFont.preferredFont(forTextStyle: .headline)])
        }
        
        return nil
    }
    
    /// When the user is connected, sets up the text description and its style
    ///
    /// - Parameter scrollView: UserTVC table view
    /// - Returns: Returns the stylized text body of the empty data set
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        /* Default text */
        var tip = "Vous avez accès à toutes les fonctionnalités, dont la commande à la cafétéria/événements et les notifications."
        
        /* Set text style */
        let descriptionFont = UIFont.preferredFont(forTextStyle: .caption1)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        
        let descriptionAttr: [String : Any] = [NSFontAttributeName : descriptionFont,
                                               NSForegroundColorAttributeName : UIColor.lightGray,
                                               NSParagraphStyleAttributeName : paragraph,
                                               NSUnderlineStyleAttributeName : NSUnderlineStyle.styleNone]
        
        /* If the user has already set a phone number */
        if let phone = JNKeychain.loadValue(forKey: "phone") as? String {
            
            /* Display this phone number */
            tip += "\n\nTéléphone associé aux commandes Lydia :\n" + phone + " "
            
            /* Create the first part as before */
            let attrStringAndDeleteBtn = NSMutableAttributedString()
            attrStringAndDeleteBtn.append(NSAttributedString(string: tip, attributes: descriptionAttr))
            
            /* Add a bold & underlined Delete label at the end */
            let boldDescriptor = descriptionFont.fontDescriptor.withSymbolicTraits(.traitBold)
            let phoneAttributes: [String : Any] = [NSFontAttributeName : UIFont(descriptor: boldDescriptor!, size: 0),
                                   NSUnderlineStyleAttributeName : NSUnderlineStyle.styleSingle,
                                   NSBackgroundColorAttributeName : UIColor.clear]
            attrStringAndDeleteBtn.append(NSAttributedString(string: "Supprimer", attributes: phoneAttributes))
            
            /* And that's it */
            return attrStringAndDeleteBtn
        }
        
        /* If no phone number, simply say it and return the default style */
        tip += "\n\nAucun téléphone associé aux commandes Lydia."
        return NSAttributedString(string: tip, attributes: descriptionAttr)
    }
    
}
