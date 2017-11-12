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
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        fetchRemote()
    }
    
    override func willActivate() {
        super.willActivate()
        
        startUpdates()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        
        stopUpdates()
    }
    
    
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
                  result.success
                else { return }
            
            self.load(orders: result.orders)
                        
        }, failure: { _, _ in
            self.setPlaceholder(using: "Impossible de récupérer vos commandes")
        })
    }
    
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
    
    private func setPlaceholder(using text: String) {
        
        table.setNumberOfRows(1,
                              withRowType: CafetInterfaceController.rowIdentifierPlaceholder)
        let row = table.rowController(at: 0) as! PlaceholderRowController
        row.placeholderLabel.setText(text)
    }
    
    
    private func startUpdates() {
        
        updateTimer = Timer.scheduledTimer(timeInterval: CafetInterfaceController.updateInterval,
                                           target: self, selector: .triggerUpdate,
                                           userInfo: nil, repeats: true)
    }
    
    private func stopUpdates() {
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc func triggerUpdate() {
        
        fetchRemote()
    }

}


class CafetRowController: NSObject {
    
    @IBOutlet var icon: WKInterfaceImage!
    @IBOutlet var number: WKInterfaceLabel!
    @IBOutlet var price: WKInterfaceLabel!
    @IBOutlet var content: WKInterfaceLabel!
    
}

class PlaceholderRowController: NSObject {
    
    @IBOutlet var placeholderLabel: WKInterfaceLabel!
    
}
