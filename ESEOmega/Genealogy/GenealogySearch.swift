//
//  GenealogySearch.swift
//  ESEOmega
//
//  Created by Tomn on 31/10/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

struct GenealogySearchResult {
    let id: StudentID
    let name: String
    let rank: StudentRank
    let promotion: String
}

class GenealogySearch: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var familyScreen: Genealogy?
    var results = [GenealogySearchResult]()
    var shouldDisplayEmptyDataPane = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        /* Get Search Bar text typed */
        var query = searchController.searchBar.text ?? ""
        // Accept accents and spaces but not trailing ones
        query = query.folding(options: .diacriticInsensitive, locale: .current).trimmingCharacters(in: CharacterSet.whitespaces)
        query = Data.encoderPourURL(query)
        
        // Don't overload servers, let's assume everyone has at least 3 letters in their name
        guard query.characters.count >= 3 else {
            // Make sure nothing is displayed
            results.removeAll()
            shouldDisplayEmptyDataPane = false
            tableView.tableFooterView = nil
            self.tableView.reloadData()
            return
        }
        
        // Allows No Results message if no data
        self.shouldDisplayEmptyDataPane = true
        let urlString = URL_FML_SRCH + query

        // Ask students results
        let defaultSession = URLSession(configuration: URLSessionConfiguration.default,
                                          delegate: nil, delegateQueue: OperationQueue.main)
        let dataTask = defaultSession.dataTask(with: URL(string: urlString)!, completionHandler: { (data, resp, error) in
            Data.shared().updLoadingActivity(false)
            guard let data = data, error == nil else { return }
            do {
                if let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: AnyObject]] {
                    // Fill with the new data
                    self.results.removeAll()
                    for result in JSON {
                        if let id        = result["id"]    as? StudentID,
                           let name      = result["name"]  as? String,
                           let rank      = result["rank"]  as? StudentRankRaw,
                           let promotion = result["promo"] as? String {
                            // Create a new result entry
                            let student = GenealogySearchResult(id: id, name: name, rank: StudentRank.parse(rank), promotion: promotion)
                            self.results.append(student)
                        }
                    }
                    // Reload data and display No Results accordingly
                    self.tableView.tableFooterView = self.results.count > 0 ? nil : UIView()
                    self.tableView.reloadData()
                }
            } catch {}
        })
        Data.shared().updLoadingActivity(true)
        dataTask.resume()
    }

    // Fill cell content with data
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "genealogySearchCell", for: indexPath)

        let student = results[indexPath.row]
        cell.textLabel?.text = student.name
        cell.detailTextLabel?.text = student.rank.rawValue + " · Promotion " + student.promotion

        return cell
    }
    
    // Show family tree for this search result
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let familyScreen = familyScreen {
            let student = results[indexPath.row]
            familyScreen.setUpFamily(for: student)
        }
    }
    
    // MARK: - DZNEmptyDataSet
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return shouldDisplayEmptyDataPane
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "genealogyEmpty")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
                     NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: "Aucun résultat\nvérifiez l'orthographe du nom", attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                     NSForegroundColorAttributeName: UIColor.lightGray]
        return NSAttributedString(string: "Venez vous présenter au module RCII du BDE si vous n'êtes pas dans la liste !", attributes: attrs)
    }
    
}
