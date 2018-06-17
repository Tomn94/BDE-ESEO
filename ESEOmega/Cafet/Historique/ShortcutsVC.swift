//
//  ShortcutsVC.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 17/06/2018.
//  Copyright © 2018 Thomas Naudet

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
import IntentsUI

@available(iOS 12, *)
class ShortcutsVC: UITableViewController {
    
    private static let reuseIdentifier = "shortcutCell"
    
    let shortcuts = [(title: "Commander",          activity: ActivityType.order,
                     (title: "Voir mes commandes", activity: ActivityType.cafet)]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell, forCellReuseIdentifier: ShortcutsVC.reuseIdentifier)
    }

}


// MARK: - Table view data source
extension ShortcutsVC {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return shortcuts.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Ajouter un raccourci à Siri"
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ShortcutsVC.reuseIdentifier,
                                                 for: indexPath)

        cell.textLabel?.text = shortcuts[indexPath.row].title
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)

        return cell
    }

}


// MARK: - Table view delegate
extension ShortcutsVC {
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcutsFromCenter, error in
            
            guard let shortcuts = shortcutsFromCenter,
                  error == nil else {
                    let alert = UIAlertController(title: "Erreur lors de la récupération des raccourcis",
                                                  message: error?.localizedDescription ?? "Erreur inconnue",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    present(alert, animated: true)
                    return
            }
            
            let activity = NSUserActivity(activityType: info.type)
            activity.title = info.title
            activity.webpageURL = info.url
            activity.isEligibleForSearch = true
            activity.isEligibleForHandoff = true
            activity.isEligibleForPublicIndexing = true
            activity.isEligibleForPrediction = true
            activity.suggestedInvocationPhrase = activity.title
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(info.type)
            INVoiceShortcutCenter.shared.setShortcutSuggestions([INShortcut(userActivity: activity)])
            if shortcuts[indexPath.row].activity == .cafet {
                activity.suggestedInvocationPhrase = "Où en est ma commande ?"
            }
            let shortcut = INShortcut(userActivity: activity)
            
            let viewController: UIViewController
            if shortcuts.first({ voiceShortcut in
                voiceShortcut.identifier == "" // TODO:
            }) != nil {
                viewController = INUIEditVoiceShortcutViewController(shortcut: shortcut)
            } else {
                viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
            }
            viewController.delegate = self
            
            if let presentingVC = presentingViewController {
                dismiss(animated: true) {
                    presentingVC.present(viewController, animated: true)
                }
            }
        }
    }
    
}


// MARK: - INUIAddVoiceShortcutViewControllerDelegate
extension ShortcutsVC: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        dismiss(animated: true) {
            if let error = error {
                let alert = UIAlertController(title: "Erreur lors de l'ajout du raccourci",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                present(alert, animated: true)
            }
        }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        dismiss(animated: true)
    }
    
}


// MARK: - INUIAddVoiceShortcutViewControllerDelegate
extension ShortcutsVC: INUIAddVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        dismiss(animated: true) {
            if let error = error {
                let alert = UIAlertController(title: "Erreur lors de l'édition du raccourci",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                present(alert, animated: true)
            }
        }
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        dismiss(animated: true)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        dismiss(animated: true)
    }
    
}
