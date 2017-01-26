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


// MARK: - Global notifications within the app
extension Notification.Name {
    static let connectionStateChanged = Notification.Name("connecte")   // User login/out
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
    
    /// Default domain name for mail addresses (used in autocomplete and placeholders)
    let mailDomain = "reseau.eseo.fr"
    
    /// Maximum number of attempts for an user to connect at once
    let maxAttempts = 5
    
    /// Number of seconds before another set of attempts is given
    let maxAttemptsWaitingTime: Double = 300
    
    /// Current number of connection attempts
    var attemptsNbr = 0
    
    /// Time interval of connection attempt that hit the maximum. Init with a random past value
    var lastMaxAttempt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.timeIntervalSinceReferenceDate
    
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
    var logoutBtn: UIBarButtonItem!
    
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Get an eventual last try back, so the user cannot close and reopen this view to bypass it */
        if let lastSavedAttempt = Data.shared().tooManyConnect {
            lastMaxAttempt = lastSavedAttempt.timeIntervalSinceReferenceDate
            
            /* Already disable login if recently blocked */
            if Date.timeIntervalSinceReferenceDate - lastMaxAttempt <= maxAttemptsWaitingTime {
                attemptsNbr = maxAttempts
            }
        }
        
        /* Configure Logout button action */
        logoutBtn = UIBarButtonItem(title: "Déconnexion", style: .plain, target: self, action: .disconnect)
        
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
        if !Data.estConnecte() {
            /* Set spin button used while connecting instead */
            currentBarButton = spinBtn
            
            /* Choose a random placeholder */
            changeMailPlaceholder()
            
            /* Display ESEO building as a banner above login form */
            self.configureBanner(with: #imageLiteral(resourceName: "batiment"),
                                 blurRadius: 0, blurTintColor: UIColor.clear, saturationFactor: 1,
                                 maxHeight: 157)
        }
        
        /* Validate navigation bar changes */
        self.navigationItem.setLeftBarButton(currentBarButton, animated: true)
    }
    
    /// Randomizes a new placeholder for the mail field
    func changeMailPlaceholder() {
        
        /* Choose one random among predefined ones */
        let index = Int(arc4random_uniform(UInt32(mailPlaceholders.count)))
        mailField.placeholder = mailPlaceholders[index] + "@" + mailDomain
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
            /* Trim whitespaces from mail, and enable the cell if the result of each is not empty */
            tappable = mail.trimmingCharacters(in: .whitespaces) != "" && password != ""
        }
        
        /* Apply changes */
        sendCell.textLabel?.isEnabled = tappable
        sendCell.isUserInteractionEnabled = tappable
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
    @IBAction func close(_ sender: Any? = nil) {

        /* Animate keyboard while closing */
        mailField.resignFirstResponder()
        passField.resignFirstResponder()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Fade any change of the empty data set
    func animateChange() {
        
        /* Make a simple transition */
        let animation = CATransition()
        animation.duration = 0.42
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.tableView.layer.add(animation, forKey: nil)
    }
    
    
    // MARK: - Actions
    
    // MARK: Login
    
    /// Sends data to connection API and reacts accordingly
    func connect() {
        
        /* Hide keyboard */
        mailField.resignFirstResponder()
        passField.resignFirstResponder()
        
        guard checkConnect() else { return }
        
        /* Disable send button */
        configureSendCell(mail: "", password: "")
        
        /* Encode password to POST */
        let password = self.passField.text ?? ""
        let postPass = encode(password: password)
        
        /* CONNECT TO API */
        
        /* Create URL encoded POST attributes */
        let mail = mailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let mailEnc = Data.encoderPourURL(mail) ?? ""
        let passEnc = Data.encoderPourURL(postPass) ?? ""
        let hash = Data.encoderPourURL(Data.hashed_string(mail + postPass + "selfRetain_$_0x128D4_objc")) ?? ""
        let body = "mail=\(mailEnc)&pass=\(passEnc)&hash=\(hash)"
        
        /* Set URL Session */
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
        var urlRequest = URLRequest(url: URL(string: URL_LOGIN)!)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body.data(using: .utf8)
        
        /* Set data callback */
        let dataTask = urlSession.dataTask(with: urlRequest) { (data, urlResponse, error) in
            
            /* Stop loading indicators */
            Data.shared().updLoadingActivity(false)
            self.spin.stopAnimating()
            
            /* Allow Send button to be tapped again */
            self.configureSendCell(mail: self.mailField.text, password: password)
            
            /* If we get some data back */
            if let d = data, error == nil {
                do {
                    /* Parse the JSON response */
                    if let json = try JSONSerialization.jsonObject(with: d) as? [String : Any],
                       let status = json["status"] as? Int {
                        
                        /* If connected */
                        if status == 1,
                           let jsonData = json["data"] as? [String: Any] {
                            
                            /* Set up the app as connected */
                            let saltedPass = Data.hashed_string("Oups, erreur de connexion" + password)
                            let username = jsonData["username"] as? String
                            
                            Data.connecter(mail, pass: saltedPass, nom: username)
                            
                            /* Alert other views */
                            NotificationCenter.default.post(name: .connectionStateChanged, object: nil)
                            
                            /* Present greeting message */
                            self.connectionSucceeded(username: username,
                                                     info: jsonData["info"] as? String)
                            return
                            
                        } else if let cause = json["cause"] as? String {
                            /* Present custom error message otherwise */
                            self.connectionFailed(error: cause, code: status)
                            return
                        }
                    }
                } catch { }
            }
            
            /* If any previous case didn't success, present unknown error */
            self.connectionFailed()
        }
        
        /* Fire connection */
        Data.shared().updLoadingActivity(true)
        spin.startAnimating()
        dataTask.resume()
    }
    
    /// Checks connection parameters (mail, password) and blocks if too many attempts
    ///
    /// - Returns: True if no error, the connection can be established
    func checkConnect() -> Bool {
        
        /* Get mail (clean an lowercased) and password values */
        guard let mail = mailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              let pass = passField.text,
              mail != "",
              pass != "" else { return false }
        
        /* Give a try at the current date */
        attemptsNbr += 1
        let currentTimeInterval = Date.timeIntervalSinceReferenceDate
        
        /* In case the limit has been hit */
        let onTooManyAttempts = {
            
            /* Display an integer of the remaning minutes to wait */
            let minToWait = Int(ceil((self.maxAttemptsWaitingTime - currentTimeInterval + self.lastMaxAttempt) / 60))
            let unit = "minute" + (minToWait > 1 ? "s" : "")
            
            /* Present error message */
            let alert = UIAlertController(title: "Doucement",
                                          message: "Veuillez attendre \(minToWait) \(unit), vous avez réalisé trop de tentatives à la suite.",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Mince !", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        /* If the user has hit the maximum */
        if attemptsNbr == maxAttempts + 1 {
            
            /* Start the countdown */
            lastMaxAttempt = currentTimeInterval
            Data.shared().tooManyConnect = Date()
            
            /* Display error message and cancel */
            onTooManyAttempts()
            return false
        }
        else if attemptsNbr > maxAttempts + 1 {

            /* If enough time has passed, set a normal number of attempts */
            if currentTimeInterval - lastMaxAttempt > maxAttemptsWaitingTime {
                attemptsNbr = 1
            } else {
                /* If the user still has to wait, display an error message and cancel */
                onTooManyAttempts()
                return false
            }
        }
        
        return true
    }
    
    /// Encode the password to transit data
    ///
    /// - Returns: An encoded password
    func encode(password: String) -> String {
        
        /* This function will not be commented… */
        let passB64 = password.data(using: .utf8)?.base64EncodedString() ?? ""
        
        var passInc = ""
        for character in password.characters {
            let scalars = String(character).unicodeScalars
            let value   = scalars[scalars.startIndex].value
            passInc    += String(Character(UnicodeScalar(value + 1)!))
        }
        let passIncB64 = passInc.data(using: .utf8)?.base64EncodedString() ?? ""
        
        var passFinal = ""
        for (index, character) in passIncB64.characters.enumerated() {
            let charIndex = passB64.index(passB64.startIndex, offsetBy: index)
            passFinal += String(passB64[charIndex])
            passFinal += String(character)
        }
        
        if passFinal.contains("====") {
            passFinal  = String(passFinal.characters.dropLast(2))
        } else {
            passFinal += "=="
        }
        
        return passFinal
    }
    
    /// Displays an alert confirming login was a success, and inits push
    ///
    /// - Parameters:
    ///   - username: Customize welcome message with the name of the user
    ///   - info: Provides some information about the database.
    ///           If this string contains "existe", the welcome message will be adapted to welcome back
    func connectionSucceeded(username: String?, info: String?) {
        
        /* Set default values */
        let userIsBack = info?.contains("existe") ?? false
        var title = userIsBack ? "Vous êtes de retour" : "Bienvenue"
        
        /* Customize with name if available */
        if let name = username,
           let firstName = name.components(separatedBy: " ").first {
            title += ", \(firstName)"
        }
        
        title += " !"
        
        /* Present alert box */
        let alert = UIAlertController(title: title,
                                      message: "Vous êtes connecté, vous bénéficiez désormais de la commande à la cafétéria/événements.\n\nPour être notifié lorsque votre repas est prêt, veuillez accepter les notifications !",
                                      preferredStyle: .alert)
        
        /* Custom message whether the user has already push notifications */
        let hasPushEnabled = Data.shared().pushToken != nil
        alert.addAction(UIAlertAction(title: hasPushEnabled ? "Parfait" : "Parfait, j'y penserai !",
                                      style: .cancel,
                                      handler: { _ in
                                        /* Register for push notifications */
                                        if let delegate = UIApplication.shared.delegate as? AppDelegate {
                                            Data.registeriOSPush(delegate)
                                        }
                                        
                                        /* Sync the device push token with the server to allow future push */
                                        if hasPushEnabled &&
                                           JNKeychain.loadValue(forKey: "login") != nil {
                                            Data.sendPushToken()
                                        }
                                        
                                        /* Close the whole profile panel */
                                        self.close()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Displays an alert explaining why login has failed
    ///
    /// - Parameters:
    ///   - error: Description of the cause of the error, default alert texts if empty
    ///   - code: Error code
    func connectionFailed(error: String = "", code: Int = 0) {
        
        /* Set default error messages */
        var title = "Impossible de valider votre connexion sur nos serveurs"
        var message = "Impossible de valider votre connexion sur nos serveurs. Si le problème persiste, contactez-nous."
        
        /* Use a description of the error instead if provided */
        if error != "" {
            title   = code == -2 ? "Oups…" : "Erreur"  // customize if wrong password
            message = error
        }
        
        /* Don't display error code for obvious messages (wrong password, wrong mail domain) */
        if code != -2 && code != -4 {
            message += " (Code : \(code))"
        }
        
        /* Show alert with message */
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: Logout
    
    /// Asks the user whether they are sure to logout, and eventually do it
    func disconnect() {
        
        /* Display an alert to confirm the choice */
        let alert = UIAlertController(title: "Voulez-vous vraiment vous déconnecter ?",
                                      message: "Vos éventuelles commandes en cours à la cafétéria restent dues.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Se déconnecter", style: .destructive, handler: { _ in
            
            /* Delete any avatar from disk */
            if self.getPhoto() != nil {
                self.removePhoto()
            }
            
            /* Delete all profile data */
            Data.deconnecter()
            
            /* Display connection form and appropriate navigation bar buttons */
            self.animateChange()
            self.loadUI()
            self.tableView.reloadData()
            
            /* Alert other views */
            NotificationCenter.default.post(name: .connectionStateChanged, object: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: Avatar
    
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
        
        /* Directly choose photo if there's already a picture */
        if getPhoto() == nil {
            selectPhoto()
            return
        }
        
        /* Ask what action to do */
        let sheet = UIAlertController(title: "",
                                      message: "Changer l'image de profil",
                                      preferredStyle: .actionSheet)
        
        /* Configure actions */
        sheet.addAction(UIAlertAction(title: "Supprimer la photo", style: .destructive, handler: { _ in
            self.removePhoto()
        }))
        sheet.addAction(UIAlertAction(title: "Choisir une photo", style: .default, handler: { _ in
            self.selectPhoto()
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
                /* Present fullscreen on iPhone */
                self.present(imagePicker, animated: true, completion: {
                    /* Apply light status bar style to the image picker */
                    UIApplication.shared.statusBarStyle = .lightContent
                })
            }
        }
    }
    
    /// Save a given picture to disk
    ///
    /// - Parameter picture: Picture to be saved as PNG
    func savePhoto(_ picture: UIImage) {
        
        /* Get destination path and scale down picture */
        if let saveURL = getPhotoURL(),
           let scaledDownPic = Data.scaleAndCropImage(picture,
                                                      to: CGSize(width: avatarImgSize, height: avatarImgSize),
                                                      retina: false) {
            
            /* Create data representation */
            let imgData = UIImagePNGRepresentation(scaledDownPic)
            do {
                /* Try to write data to destination */
                try imgData?.write(to: saveURL)
            } catch {}
        }
    }
    
    /// Deletes the current user picture from disk without confirmation
    func removePhoto() {
        
        /* If the user has currently an avatar */
        if getPhoto() != nil,
           let avatarURL = getPhotoURL() {
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
        animateChange()
        self.refreshEmptyDataSet()
    }
    
    
    // MARK: Phone number
    
    /// Asks the user to confirm the deletion of their stored phone number, and eventually do it
    func forgetTel() {
        
        /* Only display if there's a phone registered */
        guard JNKeychain.loadValue(forKey: "phone") != nil else { return }
        
        /* Display action sheet to confirm deletion.
           Action sheets are more appropriate than alerts for deletion on iOS */
        let alert = UIAlertController(title: "Voulez-vous oublier le numéro de téléphone ?",
                                      message: "Votre numéro de téléphone portable est utilisé par Lydia afin de lier vos commandes à votre compte. Il n'est pas stocké sur nos serveurs.\nUn nouveau numéro vous sera demandé au prochain achat cafet/event via Lydia.\n\nCependant lorsque vous vous inscrivez à un événement (sans utiliser Lydia), ce numéro est communiqué au BDE.", preferredStyle: .actionSheet)
        
        /* Destructive type button to confirm */
        alert.addAction(UIAlertAction(title: "Supprimer", style: .destructive, handler: { _ in
            /* Delete stored value, and remove the phone number from the view */
            JNKeychain.deleteValue(forKey: "phone")
            self.animateChange()
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
        let proposedStr = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        
        /* Operations on the mail field (which tag is 0) */
        if textField.tag == 0 {
            
            /* Add "reseau.eseo.fr" right after the user types '@' */
            if string == "@" &&                 // a @ has just been typed
               !mailTxt.contains("@") &&        // autocomplete just once
               proposedStr.hasSuffix("@") {     // the @ is at the end
                /* Update the text field */
                mailField.text = proposedStr + mailDomain
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
    
    
    // MARK: - Image Picker delegate
    
    /// Called when the user chose a picture from their library thanks to the image picker
    ///
    /// - Parameters:
    ///   - picker: The controller of the image picker
    ///   - info: Used to get the selected picture back
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        /* Get the chosen image */
        guard let chosenImage = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        
        /* Save it to disk */
        savePhoto(chosenImage)
        
        /* Update the avatar */
        animateChange()
        self.refreshEmptyDataSet()
        
        /* Dismiss the picker */
        self.dismiss(animated: true) {
            UIApplication.shared.statusBarStyle = .lightContent     // Apply app style back
        }
    }
    
    /// Called when the user cancelled the operation of changing avatar
    ///
    /// - Parameter picker: The controller of the image picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        /* Dismiss the picker */
        self.dismiss(animated: true) {
            UIApplication.shared.statusBarStyle = .lightContent     // Apply app style back
        }
    }
    
    
    // MARK: - Navigation Controller delegate
    
    /// Called when the user chooses an album from their library
    ///
    /// - Parameters:
    ///   - navigationController: The picker navigation controller
    ///   - viewController: The new controller being presented
    ///   - animated: Whether the presentation is animated
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        
        /* Apply app style to the picker */
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    
    // MARK: - Empty Data Set delegate
    
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
        if let username = JNKeychain.loadValue(forKey: "uname") as? String {
            
            let welcomeString = "Bonjour\n" + username
            
            /* Return the string with some style */
            return NSAttributedString(string: welcomeString,
                                      attributes: [NSForegroundColorAttributeName : UIColor.darkGray])
        }
        
        return NSAttributedString(string: "", attributes: [:])
    }
    
    /// When the user is connected, sets up the text description and its style
    ///
    /// - Parameter scrollView: UserTVC table view
    /// - Returns: Returns the stylized text body of the empty data set
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        /* Default text */
        var tip = "Vous avez accès à toutes les fonctionnalités, dont la commande à la cafétéria/événements et les notifications."
        
        /* Set text style */
        let descriptionFont = UIFont.preferredFont(forTextStyle: .subheadline)
        
        let descriptionAttr: [String : Any] = [NSFontAttributeName : descriptionFont,
                                               NSForegroundColorAttributeName : UIColor.lightGray,
                                               NSUnderlineStyleAttributeName : NSUnderlineStyle.styleNone.rawValue] // no style to allow further changes
        
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
                                                   NSUnderlineStyleAttributeName : NSUnderlineStyle.styleSingle.rawValue,
                                                   NSBackgroundColorAttributeName : UIColor.clear]  // clear background needed
            attrStringAndDeleteBtn.append(NSAttributedString(string: "Supprimer", attributes: phoneAttributes))
            
            /* And that's it */
            return attrStringAndDeleteBtn
        }
        
        /* If no phone number, simply say it and return the default style */
        tip += "\n\nAucun téléphone associé aux commandes Lydia.\n" // final \n to avoid text jump when deleting phone number
        
        return NSAttributedString(string: tip, attributes: descriptionAttr)
    }
    
}
