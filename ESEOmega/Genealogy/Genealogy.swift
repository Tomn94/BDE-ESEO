//
//  Genealogy.swift
//  ESEOmega
//
//  Created by Tomn on 31/10/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class Genealogy: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var search: UISearchController!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    var family: [[Student]] = []
    var query: Student?             // Highlighted student
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Configure Search Bar and Search Display Controller */
        let storyboard = UIStoryboard(name: "GenealogySearch", bundle: nil)
        if let searchDisplay = storyboard.instantiateInitialViewController() as? GenealogySearch {
            searchDisplay.familyScreen = self   // Set search callback
            search = UISearchController(searchResultsController: searchDisplay)
            search.searchResultsUpdater = searchDisplay;
            search.dimsBackgroundDuringPresentation = false;
            search.searchBar.delegate = searchDisplay;
            search.searchBar.sizeToFit()
            search.searchBar.placeholder = "Rechercher un étudiant";
            self.tableView.tableHeaderView = search.searchBar;
        }
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = self.family.count > 0 ? nil : UIView()
    }
    
    func setUpFamily(for student: GenealogySearchResult) {
        /* Dismiss search */
        search.isActive = false
        
        /* Ask family members for the student */
        let defaultSession = URLSession(configuration: URLSessionConfiguration.default,
                                        delegate: nil, delegateQueue: OperationQueue.main)
        let dataTask = defaultSession.dataTask(with: URL(string: URL_FML_INFO + String(student.id))!,
                                               completionHandler: { (data, resp, error) in
            Data.shared().updLoadingActivity(false)
            self.loadingIndicator.stopAnimating()
            guard let data = data, error == nil else { return }
            do {
                if let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: AnyObject]] {
                    // Fill with the new data
                    var familyMembers = [Student]()
                    for result in JSON {
                        if let id        = result["id"]       as? StudentID,
                           let name      = result["name"]     as? String,
                           let rank      = result["rank"]     as? StudentRankRaw,
                           let children  = result["children"] as? [StudentID],
                           let parents   = result["parents"]  as? [StudentID],
                           let family    = result["family"]   as? Int,
                           let promotion = result["promo"]    as? String {
                            // Add this student to the family
                            let student = Student(id: id, familyID: family, name: name,
                                                  promotion: promotion, rank: StudentRank.parse(rank),
                                                  parents: parents, children: children)
                            familyMembers.append(student)
                        }
                    }
                    self.arrangeFamily(members: familyMembers)
                }
            } catch {}
        })
        Data.shared().updLoadingActivity(true)
        self.loadingIndicator.startAnimating()
        dataTask.resume()
    }
    
    func arrangeFamily(members: [Student]) {
        self.family.removeAll()
        
        // Reload data and display No Results accordingly
        self.tableView.tableFooterView = self.family.count > 0 ? nil : UIView()
        self.tableView.reloadData()
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return family.count
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gnealogyCell", for: indexPath)

        // Alternate rows
        cell.backgroundColor = indexPath.row & 1 == 0 ? UIColor.groupTableViewBackground : UIColor.white

        return cell
    }
    
    
    // MARK: - DZNEmptyDataSet
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "genealogyEmpty")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
                     NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: "Retrouvez ici les familles de parrainage à l'ESEO", attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                     NSForegroundColorAttributeName: UIColor.lightGray]
        return NSAttributedString(string: "Commencez par rechercher un nom !", attributes: attrs)
    }

}
