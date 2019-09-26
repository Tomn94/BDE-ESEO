//
//  UserTVC+Avatar.swift
//  ESEOmega
//
//  Created by Tomn on 07/09/2017.
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


// MARK: - Actions
extension UserTVC {
    
    /// Finds the path to the user's avatar on disk
    ///
    /// - Returns: The URL of the image, if available
    func getPhotoURL() -> URL? {
        
        /* Get documents directory */
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                        .userDomainMask, true)
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
    @objc func changePhoto() {
        
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
        sheet.addAction(UIAlertAction(title: "Supprimer la photo",
                                      style: .destructive, handler: { _ in
            self.removePhoto()
        }))
        sheet.addAction(UIAlertAction(title: "Choisir une photo",
                                      style: .default, handler: { _ in
            self.selectPhoto()
        }))
        sheet.addAction(UIAlertAction(title: "Annuler",
                                      style: .cancel))
        
        self.present(sheet, animated: true)
    }
    
    /// Displays a standard photo picker to select a new avatar
    func selectPhoto() {
        
        /* The user will select a photo from the photos they have already taken */
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
        
            /* Create an instance of an iOS image picker */
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType    = .photoLibrary
            imagePicker.delegate      = self
            imagePicker.allowsEditing = true
            
            /* Show the picker in a pop-over on iPad, fullscreen if not */
            if UIDevice.current.userInterfaceIdiom == .pad,
               let avatarView = self.tableView.emptyDataSetView.imageView {
                
                /* Configure the picker as a pop-over */
                imagePicker.modalPresentationStyle = .popover   // needs to be set 1st
                
                /* Place the pop-over on the screen */
                let popPresentCtrl = imagePicker.popoverPresentationController
                popPresentCtrl?.sourceRect = avatarView.convert(avatarView.bounds,
                                                                to: UIApplication.shared.windows[0])
                popPresentCtrl?.sourceView = imagePicker.view
                popPresentCtrl?.permittedArrowDirections = .any
                
                /* Present pop-over */
                self.present(imagePicker, animated: true)
                
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
                                                      to: CGSize(width: UserTVC.avatarImgSize, height: UserTVC.avatarImgSize),
                                                      retina: false) {
            
            /* Create data representation */
            let imgData = scaledDownPic.pngData()
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
                alert.addAction(UIAlertAction(title: "OK",
                                              style: .cancel))
                self.present(alert, animated: true)
            }
        }
        
        /* Commit any change to the view */
        animateChange()
        self.refreshEmptyDataSet()
    }
    
}


// MARK: - Image Picker delegate

extension UserTVC: UIImagePickerControllerDelegate {
    
    /// Called when the user chose a picture from their library thanks to the image picker
    ///
    /// - Parameters:
    ///   - picker: The controller of the image picker
    ///   - info: Used to get the selected picture back
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        /* Get the chosen image */
        guard let chosenImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage
            else { return }
        
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
    
}


// MARK: - Navigation Controller delegate

extension UserTVC: UINavigationControllerDelegate {
    
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
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
