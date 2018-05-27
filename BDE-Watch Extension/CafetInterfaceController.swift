//
//  InterfaceController.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 11/11/2017.
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

import WatchKit
import WatchConnectivity

fileprivate extension Selector {
    /// Timer for regular updates on order status
    static let triggerUpdate = #selector(CafetInterfaceController.triggerUpdate)
}

/// Displays a list of the user's orders
class CafetInterfaceController: WKInterfaceController {
    
    /// Storyboard cell ID
    static let rowIdentifier            = "watchCafetCell"
    static let rowIdentifierPlaceholder = "watchCafetCellPlaceholder"
    
    /// Time between two remote data fetch call
    static let updateInterval: TimeInterval = 5
    
    
    /// Table view
    @IBOutlet var table: WKInterfaceTable!
    
    /// Timer triggering regular updates
    var updateTimer: Timer?
    
    /// Copy of all orders displayed on-screen
    var displayedOrders = [CafetOrder]()
    
    /// Eventual connectivity session with iPhone to fetch API token
    var session: WCSession?
    
    
    // MARK: - Init
    
    /// Called at app start
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        setPlaceholder(using: "Chargement…")
        
        if Keychain.hasValue(for: .token) {
            /* We already have fetched the API token from iPhone, use it */
            
            // Fetch first batch of orders
            fetchRemote()
            
        } else {
            /* Start connectivity with iPhone to get token */
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    /// Called just before appearing (horizontal swipe), begin updating content
    override func willActivate() {
        super.willActivate()
        
        // Start auto-updating
        startUpdates()
        
        /* Broadcast Handoff */
        let handoffInfo = ActivityType.cafet
        updateUserActivity(handoffInfo.type, userInfo: nil, webpageURL: handoffInfo.url)
    }
    
    /// Called when view disappeared (swipe out)
    override func didDeactivate() {
        super.didDeactivate()
        
        stopUpdates()
    }
    
    
    // MARK: - Content
    
    /// Fetch orders
    private func fetchRemote() {
        
        guard let token = Keychain.string(for: .token) else {
            setPlaceholder(using: "Connectez-vous à votre compte ESEO sur iPhone pour afficher vos commandes")
            return
        }
        
        API.request(.orders, get: ["all": "1"], authentication: token,
                    completed: { data in
            
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = CafetOrder.dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            guard let result = try? decoder.decode(CafetOrdersResult.self, from: data),
                  result.success else {
                
                // In case token is not valid anymore
                let error = API.handleFailure(data: data)
                if error.code == CafetOrdersResult.wrongTokenErrorCode {
                    Keychain.deleteValue(for: .token)
                    self.setPlaceholder(using: "Reconnectez-vous à votre compte ESEO sur iPhone pour afficher vos commandes")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.load(orders: result.orders)
            }
                        
        }, failure: { _, _ in
            self.setPlaceholder(using: "Impossible de récupérer vos commandes")
        })
    }
    
    /// Display fetched orders
    private func load(orders: [CafetOrder]) {
        
        let groupedOrdersByStatus = Dictionary(grouping: orders,
                                               by: { order in order.status })
        
        var sortedOrders = [CafetOrder]()
        let sortedKeys = Array(groupedOrdersByStatus.keys).sorted {
            $0.rawValue < $1.rawValue
        }
        if let notPaid = groupedOrdersByStatus[.notPaid] {
            // Added first since their rawValue is 3 (> 0, 1, 2)
            // but we need them on top
            sortedOrders += notPaid
        }
        for key in sortedKeys where key != .notPaid {
            let orders = groupedOrdersByStatus[key]!
            if key != .done {
                sortedOrders += orders
            } else {
                let notLongAgo = Date().addingTimeInterval(-86400)  // 24h ago
                sortedOrders += orders.filter { order in
                    order.datetime > notLongAgo
                }
            }
        }
        
        /* Don't refresh if data is the same */
        guard sortedOrders != displayedOrders
            else { return }
        displayedOrders = sortedOrders
        
        guard !displayedOrders.isEmpty else {
            setPlaceholder(using: "Vous n'avez aucune commande.\nUtilisez votre iPhone pour commander à la cafet.")
            return
        }
        
        table.setNumberOfRows(displayedOrders.count,
                              withRowType: CafetInterfaceController.rowIdentifier)
        
        for (index, order) in displayedOrders.enumerated() {
            
            let row = table.rowController(at: index) as! CafetRowController
            
            row.number.setText(order.number)
            row.number.setTextColor(order.status.color)
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale      = Locale(identifier: "fr_FR")
            row.price.setText(formatter.string(from: NSNumber(value: order.price)))
            
            row.content.setText(order.resume.replacingOccurrences(of: "<br>", with: ", "))
            
            switch order.status
            {
            case .preparing:
                row.icon.setImage(#imageLiteral(resourceName: "cafetPreparing"))
                
            case .ready:
                row.icon.setImage(#imageLiteral(resourceName: "cafetReady"))
                
            case .done:
                row.icon.setImage(#imageLiteral(resourceName: "cafetDone"))
                
            case .notPaid:
                row.icon.setImage(#imageLiteral(resourceName: "cafetNotPaid"))
            }
        }
        
        if !displayedOrders.isEmpty {
            WKInterfaceDevice().play(.click)
        }
    }
    
    /// Display message instead of content
    private func setPlaceholder(using text: String) {
        
        DispatchQueue.main.async {
            self.table.setNumberOfRows(1,
                                       withRowType: CafetInterfaceController.rowIdentifierPlaceholder)
            let row = self.table.rowController(at: 0) as! PlaceholderRowController
            row.placeholderLabel.setText(text)
        }
    }
    
    
    // MARK: - Timer Updates
    
    /// Begin regular data updates
    private func startUpdates() {
        
        updateTimer = Timer.scheduledTimer(timeInterval: CafetInterfaceController.updateInterval,
                                           target: self, selector: .triggerUpdate,
                                           userInfo: nil, repeats: true)
    }
    
    /// Stop automatic orders updates
    private func stopUpdates() {
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Called when a regular update is requested
    @objc func triggerUpdate() {
        
        if Keychain.hasValue(for: .token) {
            fetchRemote()
        } else {
            requestAPIToken()
        }
    }

}


// MARK: - Session Delegate
extension CafetInterfaceController: WCSessionDelegate {
    
    /// Called when connectivity session activation completed
    ///
    /// - Parameters:
    ///   - session: Connectivity session with iPhone
    ///   - activationState: Current state of the session
    ///   - error: Eventual error when activating
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        
        guard error == nil else {
            setPlaceholder(using: "Impossible de récupérer vos identifiants ESEO sur votre iPhone")
            return
        }
        
        // Connection established, begin communication with iPhone
        requestAPIToken()
    }
    
    /// Get token from iPhone to be able to communicate with API
    func requestAPIToken() {
        
        guard session?.activationState == .activated else {
            return
        }
        
        session?.sendMessage(["get" : "token"],
                             replyHandler: { response in
        
            // Called when Apple Watch receives a message from connectivity with iPhone
            if let token = response["token"] as? String,
               token != "" {
            
                // Save token
                Keychain.save(value: token, for: .token)
                
                // Instantly get list of orders (don't wait for auto-update loop)
                self.fetchRemote()
                
            } else {
                self.setPlaceholder(using: "Connectez-vous à votre compte ESEO sur iPhone pour afficher vos commandes")
            }
                                
        }, errorHandler: { _ in
            self.setPlaceholder(using: "Erreur lors de la récupération de vos identifiants ESEO sur votre iPhone")
        })
    }
    
}


// MARK: - Row Controllers
class CafetRowController: NSObject {
    
    @IBOutlet var icon: WKInterfaceImage!
    @IBOutlet var number: WKInterfaceLabel!
    @IBOutlet var price: WKInterfaceLabel!
    @IBOutlet var content: WKInterfaceLabel!
    
}

class PlaceholderRowController: NSObject {
    
    @IBOutlet var placeholderLabel: WKInterfaceLabel!
    
}
