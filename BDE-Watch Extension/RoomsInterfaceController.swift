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
import Foundation


/// Presents a list of rooms in ESEO Angers
class RoomsInterfaceController: WKInterfaceController {
    
    /// UserDefaults cache key
    static let cacheKey      = "watchRooms"
    /// Storyboard cell ID
    static let rowIdentifier = "watchRoomCell"
    
    
    /// Table view
    @IBOutlet var table: WKInterfaceTable!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        loadCache()
        loadRemote()
    }
    
    
    private func loadCache() {
        
        guard let roomData    = UserDefaults.standard.data(forKey: RoomsInterfaceController.cacheKey),
              let cachedRooms = try? JSONDecoder().decode([Room].self, from: roomData)
            else { return }
        
        load(rooms: cachedRooms)
    }
    
    private func loadRemote() {
        
        API.request(.rooms, completed: { data in
            
            guard let result = try? JSONDecoder().decode(RoomsResult.self, from: data),
                  result.success
                else { return }
            
            if let roomData = try? JSONEncoder().encode(result.rooms) {
                /* Save result in cache */
                UserDefaults.standard.set(roomData, forKey: RoomsInterfaceController.cacheKey)
            }
            self.load(rooms: result.rooms)
        })
    }
    
    private func load(rooms: [Room]) {
        
        let sortedRooms = rooms.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        
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

}


/// Describes a cell in the list of rooms
class RoomRowController: NSObject {
    
    @IBOutlet var roomTitle: WKInterfaceLabel!
    @IBOutlet var subtitle: WKInterfaceLabel!
    
}

