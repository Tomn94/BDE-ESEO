//
//  CafetOrderVC.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 15/10/2017.
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
    /// Timer for regular updates on order status
    static let triggerUpdate = #selector(CafetOrderVC.fetchDetailedOrder)
    /// Called when Low Power mode toggled
    static let toggleUpdates = #selector(CafetOrderVC.toggleUpdates)
    /// Dismiss modal view on iPad
    static let dismissDetail = #selector(CafetOrdersTVC.dismissDetail)
}

class CafetOrderDetailSegue: UIStoryboardSegue {
    
    override func perform() {
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            
            guard let typedSource = self.source as? CafetOrdersTVC
                else { return }
            
            let navVC = UINavigationController(rootViewController: destination)
            navVC.modalPresentationStyle = .formSheet
            
            let dismissButton = UIBarButtonItem(barButtonSystemItem: .done,
                                                target: source,
                                                action: .dismissDetail)
            destination.navigationItem.leftBarButtonItem = dismissButton
            
            source.present(navVC, animated: true) {
                if let selection = typedSource.tableView.indexPathForSelectedRow {
                    typedSource.tableView.deselectRow(at: selection, animated: true)
                }
            }
            
        } else {
            source.navigationController?.pushViewController(destination,
                                                            animated: true)
        }
    }
    
}

class CafetOrderVC: UIViewController {
    
    var order: CafetOrder?
    
    var updateTimer: Timer?
    
    var loaded = false
    
    @IBOutlet weak var bandeau: UIImageView!
    @IBOutlet weak var titreLabel: UILabel!
    @IBOutlet weak var prix: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var numCmdLabel: UILabel!
    @IBOutlet weak var numCmdLabelBack: UIView!
    @IBOutlet weak var numCmdHeader: UILabel!
    @IBOutlet weak var numCmdBack: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        showOrder()
        
        NotificationCenter.default.addObserver(self, selector: .toggleUpdates,
                                               name: .NSProcessInfoPowerStateDidChange,
                                               object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchDetailedOrder()
        startUpdates()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopUpdates()
    }
    
    func startUpdates() {
        
        guard !ProcessInfo.processInfo.isLowPowerModeEnabled else {
            stopUpdates()
            return
        }
        
        updateTimer = Timer.scheduledTimer(timeInterval: CafetOrdersTVC.updateInterval,
                                           target: self, selector: .triggerUpdate,
                                           userInfo: nil, repeats: true)
    }
    
    func stopUpdates() {
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc func toggleUpdates() {
        
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            stopUpdates()
        } else if !(updateTimer?.isValid ?? false) {
            startUpdates()
        }
    }
    
    
    // MARK: - Actions
    
    func showOrder() {
        
        guard let order = self.order else { return }
        
        /* VC Title & Color */
        self.title = order.status.fullName
        let color  = order.status.color
        
        var r = CGFloat(0), g = CGFloat(0), b = CGFloat(0), a = CGFloat(0)
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lighterColor = UIColor(red:  min(r + 0.2, 1), green: min(g + 0.2, 1),
                                   blue: min(b + 0.2, 1), alpha: a)
        
        prix.textColor = color
        numCmdHeader.textColor = color
        numCmdLabelBack.backgroundColor = color
        numCmdBack.backgroundColor = lighterColor
        
        /* Title */
        let dateString = DateFormatter.localizedString(from: order.startTime,
                                                       dateStyle: .full,
                                                       timeStyle: .none)
        titreLabel.text = "Votre commande du " +
                          dateString.replacingOccurrences(of: " ", with: " ")  // Non-Breaking Space
        
        /* Price */
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale      = Locale(identifier: "fr_FR")
        var priceString = numberFormatter.string(from: NSDecimalNumber(value: order.price)) ?? "Unknown price"
        if !order.paid {
            priceString += " ⚠️"
        }
        prix.attributedText = NSAttributedString(string: priceString,
                                                 attributes: [.textEffect : NSAttributedString.TextEffectStyle.letterpressStyle])
        
        /* Detail */
        let resume = "– " + order.friendlyText.replacingOccurrences(of: "<br>", with: "\n– ")
        detailLabel.text = resume
        
        /* Instructions */
        var instructions = resume
        var addedInstructions = false
        guard let instr = order.instructions else {
            instructions = ""
            return
        }
        instructions += "\n\nCommentaire :\n" + instr
        addedInstructions = true
        

        let attrStr = NSMutableAttributedString(string: instructions,
                                                attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline)])
        if addedInstructions {
            attrStr.setAttributes([.font : UIFont.preferredFont(forTextStyle: .subheadline).bold()],
                                  range: NSMakeRange(resume.count + 2, 13))
        }
        detailLabel.attributedText = attrStr
        
        /* Num */
        let numString = String(format: "%03d", order.modID)
        numCmdLabel.attributedText = NSAttributedString(string: numString,
                                                        attributes: [.textEffect : NSAttributedString.TextEffectStyle.letterpressStyle])
        
        /* Image */
        if let imgURL = order.imgurl, imgURL != "" {
            bandeau.sd_setImage(with: URL(string: imgURL),
                                placeholderImage: #imageLiteral(resourceName: "placeholder"),
                                completed: { image, error, cacheType, url in
                
                guard !self.loaded else { return }
                
                let animation = CATransition()
                animation.duration = 0.42
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                animation.type     = CATransitionType.moveIn
                animation.subtype  = CATransitionSubtype.fromBottom
                self.bandeau.layer.add(animation, forKey: nil)
                self.loaded = true
            })
        }
        
        /* Pay Bar Button Item */
        if order.paid {
            
            let item = UIBarButtonItem(title: "Payée", style: .plain,
                                       target: nil, action: nil)
            item.isEnabled = false
            navigationItem.rightBarButtonItem = item
            
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func fetchDetailedOrder() {
        
        guard let order     = self.order,
              let userToken = Keychain.string(for: .token)
            else { return }
        
        let defaultMessage = "Détails de la commande indisponibles"
        
        API.request(.order, appendPath: "/" + String(order.ID),
                    authentication: userToken, completed: { data in
                        
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = CafetOrder.dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
                        
            guard let result = try? decoder.decode(CafetOrdersResult.self, from: data),
                  result.success else {
                API.handleFailure(data: data, mode: .presentFetchedMessage(self),
                                  defaultMessage: defaultMessage)
                return
            }
            
            DispatchQueue.main.async {
                self.order = result.orders[0]
                self.showOrder()
            }
                        
        }, failure: { _, data in
            
            API.handleFailure(data: data, mode: .presentFetchedMessage(self),
                              defaultMessage: defaultMessage)
        })
    }
    
    func payOrder() {
        
        guard let order = self.order,
              DataStore.isUserLogged else {
                
            let alert = UIAlertController(title: "Vous devez être connecté pour payer",
                                          message: "Connectez-vous grâce à votre adresse mail ESEO.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
            return
        }
        
        Lydia.startRequest(for: order.ID, type: .cafet,
                           viewController: self)
    }
    
}
