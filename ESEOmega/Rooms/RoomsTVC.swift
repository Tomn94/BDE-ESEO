//
//  RoomsTVC.swift
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


/// Lists rooms in ESEO Angers
class RoomsTVC: UITableViewController {
    
    /// Unique cell reuse identifier
    private let reuseIdentifier = "roomsCell"
    
    /// Displayed rooms
    private var rooms         = [[Room]]()
    
    /// Rooms filtered by search query
    private var filteredRooms = [[Room]]()
    
    /// Current sort mode for rooms
    var sortMode = Room.SortMode(rawValue: UserDefaults.standard.integer(forKey: UserDefaultsKey.roomsSortMode)) ?? .byName {
        didSet {
            UserDefaults.standard.set(sortMode.rawValue, forKey: UserDefaultsKey.roomsSortMode)
        }
    }
    
    /// Handles searching with its search bar
    private let searchController = UISearchController(searchResultsController: nil)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Load local data and ask for updates */
        loadFromCache()
        fetchRemote()
        
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
        if let refresh = self.refreshControl {
            NotificationCenter.default.addObserver(refresh,
                                                   selector: #selector(UIRefreshControl.endRefreshing),
                                                   name: .debugRefresh,
                                                   object: nil)
        }
    }
    
    
    // MARK: - Actions
    
    /// Refresh control triggered
    @IBAction func refresh() {
        
        fetchRemote()
    }
    
    /// Display a full-screen map
    @IBAction func showMap() {
        
        /* Load image */
        let imageInfo = JTSImageInfo()
        imageInfo.image = #imageLiteral(resourceName: "plan")
        
        /* View controller handling display */
        let imageViewer = JTSImageViewController(imageInfo: imageInfo,
                                                 mode: .image,
                                                 backgroundStyle: [.blurred, .scaled])
        imageViewer?.show(from: self,
                          transition: .fromOffscreen)
    }
    
    /// Loops through search modes
    @IBAction func changeSortMode() {
        
        /* Update model */
        switch sortMode {
        case .byName:
            sortMode = .byBuilding
        case .byBuilding:
            sortMode = .byFloor
        case .byFloor:
            sortMode = .byName
        }
        
        /* UI transition */
        let transition = CATransition()
        transition.duration = 0.42
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        tableView.layer.add(transition, forKey: nil)
        
        /* Update UI */
        loadFromCache()
    }
    
}


// MARK: - API Viewer
extension RoomsTVC: APIViewer {
    
    typealias T = [Room]
    
    
    func loadFromCache() {
        
        guard let data   = APIArchiver.getCache(for: .rooms),
              let result = try? JSONDecoder().decode([Room].self, from: data) else {
                reloadData()
                return
        }
        
        self.loadData(result)
    }
    
    func fetchRemote() {
        
        API.request(.rooms, completed: { data in
            
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
            
            guard let result = try? JSONDecoder().decode(RoomsResult.self, from: data),
                  result.success
                else { return }
            
            self.loadData(result.rooms)
            APIArchiver.save(data: result.rooms, for: .rooms)
            
        }, failure: { _, _ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    func loadData(_ data: [Room]) {
        
        var rooms = data

        /* Sort alphabetically or by building or by floor */
        var property: KeyPath<Room, String> = \.name
        switch sortMode {
        case .byName:
            break
        case .byBuilding:
            property = \.building
        case .byFloor:  // sort Int
            rooms.sort { room1, room2 in
                room1.floor < room2.floor
            }
        }
        if sortMode != .byFloor {  // sort String
            rooms.sort { room1, room2 in
                room1[keyPath: property].localizedStandardCompare(room2[keyPath: property]) == .orderedAscending
            }
        }
        
        /* Since it is sorted (continuous), now split rooms into building sections
           or floor sections or letter sections */
        var currentSectionId: String?
        var sortedRooms = [[Room]]()
        for room in rooms {
            
            var roomId = room[keyPath: property]
            if sortMode == .byName {  // alpha = sort by 1st letter
                roomId = String(roomId.prefix(1))
            }
            
            // Let's fill the current section if it belongs to it
            if let currentSectionId = currentSectionId,
               roomId.caseInsensitiveCompare(currentSectionId) == .orderedSame {
                sortedRooms[sortedRooms.count - 1].append(room)
            } else {  // or create a new section
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
                        // Inner-inner sort by name makes sense for the same floor
                        return room1.name.localizedStandardCompare(room2.name) == .orderedAscending
                    }
                    // Otherwise inner sort by floor
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
        reloadData()
    }
    
    func reloadData() {
        
        DispatchQueue.main.async {
            if !self.rooms.isEmpty || self.searchController.isActive {
                self.tableView.backgroundColor = .white
                self.tableView.tableFooterView = nil
            } else {
                self.tableView.backgroundColor = .groupTableViewBackground
                self.tableView.tableFooterView = UITableViewHeaderFooterView()
            }
            self.tableView.reloadData()
        }
    }
    
}


// MARK: - Table View Data Source
extension RoomsTVC {

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if searchController.isActive {
            return filteredRooms.count
        }
        return rooms.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive {
            return filteredRooms[section].count
        }
        return rooms[section].count
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        
        let currentSet = searchController.isActive ? filteredRooms : rooms
        let sectionRooms = currentSet[section]
        
        /* Uses the first room of the section to make a title */
        guard let firstRoom = sectionRooms.first
            else { return nil }
        
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
    
    /// Customizes section index titles: the vertical bar on the right side
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        guard !searchController.isActive && !rooms.isEmpty
            else { return nil }
        
        var initials: [String]
        if sortMode == .byName {
            // Use already defined set. May end with # for numbers
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
        // Add Search icon
        initials.insert(UITableViewIndexSearch, at: 0)
        
        return initials
    }
    
    /// Syncs a section index title with a section
    override func tableView(_ tableView: UITableView,
                            sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        
        guard index != 0 else {
            // Show Search
            if #available(iOS 11.0, *) {
                tableView.contentOffset = CGPoint(x: 0, y: -tableView.safeAreaInsets.top)
            } else {
                tableView.contentOffset = CGPoint(x: 0, y: -64)
            }
            return NSNotFound
        }
        
        if sortMode == .byName && title == "#" {
            // Show last section
            return rooms.count - 1
        }
        
        /* Loop through all sections */
        var sectionIndex = 0
        for section in rooms {
            /* Get the first item */
            if let firstRoom = section.first {
                
                /* Computes the associated raw title (± like section title) */
                let sectionTitle: String
                switch sortMode {
                case .byName:
                    sectionTitle = String(firstRoom.name.prefix(1))
                case .byBuilding:
                    sectionTitle = firstRoom.building
                case .byFloor:
                    sectionTitle = "\(firstRoom.floor)"
                }
                
                /* Compare the location of the title and the computed one */
                switch title.caseInsensitiveCompare(sectionTitle) {
                case .orderedSame:
                    // If we have the same, it's a perfect match
                    return sectionIndex
                case .orderedAscending:
                    // Less perfect match, we missed it (the section may not exist)
                    // We'll return the previous section
                    break
                case .orderedDescending:
                    // Continue to the next one
                    sectionIndex += 1
                }
            }
        }
        
        return sectionIndex
    }
    
    /// Populate cells
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        /* Get cell and its data from model */
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                 for: indexPath)
        let currentSet = searchController.isActive ? filteredRooms : rooms
        let room = currentSet[indexPath.section][indexPath.row]
        
        /* Associate values to make a descriptive text */
        var detailText = "Bâtiment \(room.building) · Étage \(room.floor)"
        if let roomNumber = room.number {
            detailText = "\(roomNumber) · " + detailText
        }
        if let roomInfo = room.info,
           roomInfo != "" {
            detailText += " · " + roomInfo
        }
        
        /* Apply data */
        cell.textLabel?.text       = room.name
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
    
    /// Called when user changes the text of the search bar
    func updateSearchResults(for searchController: UISearchController) {
        
        // Reset results and get what's been typed
        filteredRooms = []
        let query = searchController.searchBar.text ?? ""
        
        // Find data in each section
        for section in rooms {
            filteredRooms.append(section.filter { room in
                return room.name.localizedStandardContains(query) ||
                      (room.info   ?? "").localizedStandardContains(query) ||
                      (room.number ?? "").localizedStandardContains(query)
            })
        }
        
        reloadData()
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
    
    func offset(forEmptyDataSet scrollView: UIScrollView!) -> CGPoint {
        
        return CGPoint(x: 0, y: -searchController.searchBar.frame.height)
    }
    
}


// MARK: - Empty Data Set Delegate
extension RoomsTVC: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        
        // Don't show empty data set if user is in an empty search field
        return !searchController.isActive
    }
    
}
