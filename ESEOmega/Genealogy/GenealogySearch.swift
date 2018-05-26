//
//  GenealogySearch.swift
//  ESEOmega
//
//  Created by Thomas Naudet on 31/10/2016.
//  Copyright © 2016 Thomas Naudet

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

class GenealogySearch: UITableViewController {
    
    private let reuseIdentifier = "genealogySearchCell"
    
    
    var familyScreen: Genealogy?
    
    private var shouldDisplayEmptyDataPane = true
    
    private var results = [FamilyMember]()
    
}


// MARK: - Table View Data Source
extension GenealogySearch {

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        return results.count
    }
    
    // Fill cell content with data
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                 for: indexPath)

        let student = results[indexPath.row]
        cell.textLabel?.text = student.fullname
        cell.detailTextLabel?.text = "Promotion " + student.promo

        return cell
    }
    
}


// MARK: - Table View Delegate
extension GenealogySearch {
    
    // Show family tree for this search result
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let familyScreen = familyScreen else { return }
            
        let student = results[indexPath.row]
        familyScreen.setUpFamily(for: student)
    }
}


// MARK: - Search Results Updating
extension GenealogySearch: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        /* Get Search Bar text typed */
        var query = searchController.searchBar.text ?? ""
        // Accept accents and spaces but not trailing ones
        query = query.folding(options: .diacriticInsensitive,
                              locale:  .current).trimmingCharacters(in: .whitespaces)
        
        /* Don't overload servers, let's assume everyone has at least 3 letters in their name */
        guard query.characters.count >= 3 else {
            /* Make sure nothing is displayed */
            results.removeAll()
            shouldDisplayEmptyDataPane = false
            tableView.tableFooterView = nil
            self.tableView.reloadData()
            return
        }
        
        /* Allows No Results message if no data */
        self.shouldDisplayEmptyDataPane = true
        self.tableView.tableFooterView = self.results.count > 0
                                       ? nil : UITableViewHeaderFooterView()
        self.tableView.reloadData()

        /* Ask students results */
        API.request(.familySearch, get: ["name" : query], completed: { data in
            
            guard let result = try? JSONDecoder().decode(StudentSearchResult.self,
                                                         from: data),
                  result.success
                else { return }
            
            /* Store sorted alphabetically */
            self.results = result.users.sorted {
                $0.fullname.localizedStandardCompare($1.fullname) == .orderedAscending
            }
            
            /* Reload data and display No Results accordingly */
            DispatchQueue.main.async {
                self.tableView.tableFooterView = self.results.count > 0
                                               ? nil : UITableViewHeaderFooterView()
                self.tableView.reloadData()
            }
        })
    }
    
}


// MARK: - Empty Data Set Source
extension GenealogySearch: DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "genealogyEmpty")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return NSAttributedString(string: "Aucun résultat\nvérifiez l'orthographe du nom",
                                  attributes: [.font: UIFont.preferredFont(forTextStyle: .title3),
                                               .foregroundColor: UIColor.darkGray])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        return NSAttributedString(string: "Venez vous présenter au module RCII du BDE si vous n'êtes pas dans la liste !",
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline),
                                               .foregroundColor : UIColor.lightGray])
    }
    
}


// MARK: - Empty Data Set Delegate
extension GenealogySearch: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        
        return shouldDisplayEmptyDataPane
    }
    
}
