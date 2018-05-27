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

/// Presents a list of rooms in ESEO Angers
class RoomsInterfaceController: WKInterfaceController {
    
    /// Storyboard cell ID
    static let rowIdentifier            = "watchRoomCell"
    static let rowIdentifierPlaceholder = "watchRoomCellPlaceholder"
    
    
    /// Table view
    @IBOutlet var table: WKInterfaceTable!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        loadCache()
        fetchRemote()
    }
    
    
    private func loadCache() {
        
        guard let roomData    = UserDefaults.standard.data(forKey: UserDefaultsKey.watchRooms),
              let cachedRooms = try? JSONDecoder().decode([Room].self, from: roomData)
            else { return }
        
        load(rooms: cachedRooms)
    }
    
    private func fetchRemote() {
        
        API.request(.rooms, completed: { data in
            
            guard let result = try? JSONDecoder().decode(RoomsResult.self, from: data),
                  result.success
                else { return }
            
            if let roomData = try? JSONEncoder().encode(result.rooms) {
                /* Save result in cache */
                UserDefaults.standard.set(roomData, forKey: UserDefaultsKey.watchRooms)
            }
            self.load(rooms: result.rooms)
            
        }, failure: { _, _ in
            if self.table.numberOfRows == 0 {  // don't show if we have cache
                self.setPlaceholder(using: "Aucune salle trouvée.\nVérifiez votre connexion.")
            }
        })
    }
    
    private func load(rooms: [Room]) {
        
        let sortedRooms = rooms.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        
        guard !sortedRooms.isEmpty else {
            setPlaceholder(using: "Aucune salle trouvée.\nVérifiez que l'ESEO existe encore 🤷‍♂️")
            return
        }
        
        table.setNumberOfRows(sortedRooms.count,
                              withRowType: RoomsInterfaceController.rowIdentifier)
        
        for (index, room) in sortedRooms.enumerated() {
            
            let row = table.rowController(at: index) as! RoomRowController
            
            var subtitle = ""
            if let number = room.number, number != "" {
                subtitle += number + " · "
            }
            subtitle += "Bât " + room.building + " · "
            if room.floor < 0 {
                subtitle += "Étage \(room.floor)"
            } else if room.floor == 0 {
                subtitle += "RdC"
            } else if room.floor == 1 {
                subtitle += "1er"
            } else {
                subtitle += "\(room.floor)e"
            }
            
            row.roomTitle.setText(room.name)
            row.subtitle.setText(subtitle)
        }
    }
    
    private func setPlaceholder(using text: String) {
        
        table.setNumberOfRows(1,
                              withRowType: RoomsInterfaceController.rowIdentifierPlaceholder)
        let row = table.rowController(at: 0) as! PlaceholderRowController
        row.placeholderLabel.setText(text)
    }

}


/// Describes a cell in the list of rooms
class RoomRowController: NSObject {
    
    @IBOutlet var roomTitle: WKInterfaceLabel!
    @IBOutlet var subtitle: WKInterfaceLabel!
    
}

