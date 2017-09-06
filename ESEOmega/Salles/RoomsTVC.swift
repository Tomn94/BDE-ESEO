//
//  SallesTVC.swift
//  ESEOmega
//
//  Created by Thomas Naudet on 06/09/2017.
//  Copyright © 2017 Thomas Naudet. All rights reserved.

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
    /// New data incoming
    static let newDataRooms = #selector(RoomsTVC.loadRooms)
}


/// Lists rooms in ESEO Angers
class RoomsTVC: UITableViewController {
    
    var rooms         = [[Room]]()
    var filteredRooms = [[Room]]()
    
    var sortMode = Room.SortMode(rawValue: UserDefaults.standard.integer(forKey: UserDefaultsKey.roomsSortMode)) ?? .byName {
        didSet {
            UserDefaults.standard.set(sortMode, forKey: UserDefaultsKey.roomsSortMode)
        }
    }
    
    let reuseIdentifier = "roomsCell"
    
    let searchController = UISearchController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Load local data and ask for updates */
        Data.shared().updateJSON(Room.apiPath)
        loadRooms()
        
        /* Search */
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        let searchBar = searchController.searchBar
        searchBar.placeholder = "Rechercher une salle"
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
        
        /* Empty data set */
        refreshControl?.tintColor = UINavigationBar.appearance().barTintColor
        
        /* Data */
        NotificationCenter.default.addObserver(self,
                                               selector: .newDataRooms,
                                               name: .newDataRooms,
                                               object: nil)
        if let resfresh = self.refreshControl {
            NotificationCenter.default.addObserver(resfresh,
                                                   selector: #selector(UIRefreshControl.endRefreshing),
                                                   name: .debugRefresh,
                                                   object: nil)
        }
    }
    
    
    @IBAction func refresh() {
        
        guard Data.shared().shouldUpdateJSON("rooms") else {
            refreshControl?.endRefreshing()
            return
        }
        
        Data.shared().updateJSON("rooms")
    }
    
    @objc func loadRooms() {
        
        refreshControl?.endRefreshing()
        
        var allRooms = Data.shared().salles["rooms"] as! [Room]

        /* Sort alphabetically or by building or by floor */
        var property: KeyPath<Room, String> = \.name
        switch sortMode {
        case .byName:
            break
        case .byBuilding:
            property = \.building
        case .byFloor:
            allRooms.sort { room1, room2 in
                room1.floor < room2.floor
            }
        }
        if sortMode != .byFloor {
            allRooms.sort { room1, room2 in
                room1[keyPath: property].localizedStandardCompare(room2[keyPath: property]) == .orderedAscending
            }
        }
        
        /* Split rooms into building sections or floor sections or letter sections for alpha */
        var currentSectionId: String?
        var sortedRooms = [[Room]]()
        for room in allRooms {
            
            var roomId = room[keyPath: property]
            if sortMode == .byName {  // alpha = sort by 1st letter
                roomId = String(roomId.prefix(1))
            }
            
            // Let's fill the current section if it belongs to it
            if let currentSectionId = currentSectionId,
               roomId.caseInsensitiveCompare(currentSectionId) == .orderedSame {
                sortedRooms[sortedRooms.count - 1].append(room)
            }
            else {  // or create a new section
                sortedRooms.append([room])
            }
            
            // In any case we take the current ID for the next test
            currentSectionId = roomId
        }
        
        /* Inner sorting */
        switch sortMode {
        case .byName:
            self.rooms = sortedRooms
            
        case .byBuilding:   // by floor then name
            var resortedRooms = [[Room]]()
            for rooms in sortedRooms {
                resortedRooms.append(rooms.sorted { room1, room2 in
                    if room1.floor == room2.floor {
                        return room1.name.localizedStandardCompare(room2.name) == .orderedAscending
                    }
                    return room1.floor < room2.floor
                })
            }
            self.rooms = resortedRooms
            
        case .byFloor:      // by name
            var resortedRooms = [[Room]]()
            for rooms in sortedRooms {
                resortedRooms.append(rooms.sorted { room1, room2 in
                    room1.name.localizedStandardCompare(room2.name) == .orderedAscending
                })
            }
            self.rooms = resortedRooms
        }
        
        /* Now, present */
        if !rooms.isEmpty || searchController.isActive {
            tableView.backgroundColor = .white
            tableView.tableFooterView = nil
        } else {
            tableView.backgroundColor = .groupTableViewBackground
            tableView.tableFooterView = UIView()
        }
        tableView.reloadData()
    }
    
    @IBAction func showMap() {
        
        let imageInfo = JTSImageInfo()
        imageInfo.image = #imageLiteral(resourceName: "plan")
        
        let imageViewer = JTSImageViewController(imageInfo: imageInfo,
                                                 mode: .image, backgroundStyle: .blurred)
        imageViewer?.show(from: self, transition: .fromOffscreen)
    }
    
    @IBAction func changeSortMode() {
        
        switch sortMode {
        case .byName:
            sortMode = .byBuilding
        case .byBuilding:
            sortMode = .byFloor
        case .byFloor:
            sortMode = .byName
        }
        
        let transition = CATransition()
        transition.duration = 0.42
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        tableView.layer.add(transition, forKey: nil)
        
        loadRooms()
    }
    
}


extension RoomsTVC {

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if searchController.isActive {
            return filteredRooms.count
        }
        return rooms.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive {
            return filteredRooms[section].count
        }
        return rooms[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let currentSet = searchController.isActive ? filteredRooms : rooms
        let sectionRooms = currentSet[section]
        guard let firstRoom = sectionRooms.first else {
            return nil
        }
        
        switch sortMode {
        case .byName:
            let firstLetter = String(firstRoom.name.prefix(1))
            return firstLetter == "" ? "#" : firstLetter
            
        case .byBuilding:
            return "Bâtiment " + firstRoom.building
            
        case .byFloor:
            return "Étage \(firstRoom.floor)"
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        guard !searchController.isActive && !rooms.isEmpty
            else { return nil }
        
        var initials: [String]
        if sortMode == .byName {
            initials = UILocalizedIndexedCollation.current().sectionIndexTitles
            
        } else {
            initials = []
            
            for section in rooms {
                
                if let firstRoom = section.first {
                    
                    switch sortMode {
                    case .byBuilding:
                        initials.append(firstRoom.building)
                        
                    case .byFloor:
                        initials.append("\(firstRoom.floor)")
                        
                    case .byName:
                        break
                    }
                }
            }
        }
        
        initials.insert(UITableViewIndexSearch, at: 0)
        
        return initials
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        
        guard index != 0 else {
            if #available(iOS 11.0, *) {
                tableView.contentOffset = CGPoint(x: 0, y: -tableView.safeAreaInsets.top)
            } else {
                tableView.contentOffset = CGPoint(x: 0, y: -64)
            }
            return NSNotFound
        }
        
        guard sortMode != .byName || title != "#" else {
            return rooms.count - 1
        }
        
        var sectionIndex = 0
        for section in rooms {
            
            if let firstRoom = section.first {
                
                let sectionTitle: String
                switch sortMode {
                case .byName:
                    sectionTitle = String(firstRoom.name.prefix(1))
                case .byBuilding:
                    sectionTitle = firstRoom.building
                case .byFloor:
                    sectionTitle = "\(firstRoom.floor)"
                }
                
                switch title.caseInsensitiveCompare(sectionTitle) {
                case .orderedSame:
                    return sectionIndex
                case .orderedAscending:
                    break  // will return previous index
                case .orderedDescending:
                    sectionIndex += 1
                }
            }
        }
        
        return sectionIndex
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                 for: indexPath)
        
        let currentSet = searchController.isActive ? filteredRooms : rooms
        let room = currentSet[indexPath.section][indexPath.row]
        
        
        var detailText = "Bâtiment \(room.building) · Étage \(room.floor)"
        if let roomNumber = room.number {
            detailText = "\(roomNumber) · " + detailText
        }
        if let roomInfo = room.info,
           roomInfo != "" {
            detailText += " · " + roomInfo
        }
        
        cell.textLabel?.text = room.name
        cell.detailTextLabel?.text = detailText
        
        /* Monospaced font */
        let bodyDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let monoBodyDescriptor = bodyDescriptor.addingAttributes([
            .featureSettings : [
                // monospaced
                [UIFontDescriptor.FeatureKey.featureIdentifier : kNumberSpacingType,
                 UIFontDescriptor.FeatureKey.typeIdentifier    : kMonospacedNumbersSelector],
                // alternative 6 & 9
                [UIFontDescriptor.FeatureKey.featureIdentifier : kStylisticAlternativesType,
                 UIFontDescriptor.FeatureKey.typeIdentifier    : kStylisticAltOneOnSelector]
            ]])
        cell.textLabel?.font = UIFont(descriptor: monoBodyDescriptor, size: 0)
        
        return cell
    }

}


// MARK: - Search Results Updating
extension RoomsTVC: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredRooms = []
        
        let query = searchController.searchBar.text ?? ""
        
        let predicate = NSPredicate(format: "(%K contains[cd] %@) OR (%K contains[cd] %@) OR (%K contains[cd] %@)",
                                    "name", query,
                                    "num",  query,
                                    "info", query)
        
        for section in rooms {
            filteredRooms.append((section as NSArray).filtered(using: predicate) as! [Room])
        }
        
        tableView.reloadData()
    }
    
}


// MARK: - Empty Data Set Source
extension RoomsTVC: DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "autreVide")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let text = "Aucune salle trouvée"
        return NSAttributedString(string: text,
                                  attributes: [.foregroundColor : UIColor.darkGray])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let text = "Le bâtiment ESEO a peut-être été détruit, ou alors votre connexion Internet n'est pas au top de sa forme…"
        return NSAttributedString(string: text,
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline),
                                               .foregroundColor : UIColor.lightGray])
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        
        return .groupTableViewBackground
    }
    
}


// MARK: - Empty Data Set Delegate
extension RoomsTVC: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        
        return !searchController.isActive
    }
    
}

