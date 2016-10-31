//
//  GenealogySearch.swift
//  ESEOmega
//
//  Created by Tomn on 31/10/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

struct GenealogySearchResult {
    let id: Int
    let name: String
    let rank: StudentRank
    let promotion: String
}

class GenealogySearch: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    var results = [GenealogySearchResult]()

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        
        guard query.characters.count >= 3 else {
            results.removeAll()
            return
        }
        
        let urlString = URL_FML_SRCH + Data.encoderPourURL(query.trimmingCharacters(in: CharacterSet.whitespaces))

        let defaultSession = URLSession(configuration: URLSessionConfiguration.default,
                                          delegate: nil, delegateQueue: OperationQueue.main)
        let dataTask = defaultSession.dataTask(with: URL(string: urlString)!, completionHandler: { (data, resp, error) in
            Data.shared().updLoadingActivity(false)
            guard let data = data, error == nil else { return }
            do {
                if let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: AnyObject]] {
                    self.results.removeAll()
                    for result in JSON {
                        if let id = result["id"] as? Int,
                           let name = result["name"] as? String,
                           let rank = result["rank"] as? Int,
                           let promotion = result["promo"] as? String {
                            let student = GenealogySearchResult(id: id, name: name, rank: StudentRank.parse(rank), promotion: promotion)
                            self.results.append(student)
                        }
                    }
                    self.tableView.reloadData()
                }
            } catch {}
        })
        Data.shared().updLoadingActivity(false)
        dataTask.resume()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "genealogySearchCell", for: indexPath)

        let student = results[indexPath.row]
        cell.textLabel?.text = student.name
        cell.detailTextLabel?.text = student.rank.rawValue + " · Promotion " + student.promotion

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
