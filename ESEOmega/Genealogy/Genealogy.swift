//
//  Genealogy.swift
//  ESEOmega
//
//  Created by Tomn on 31/10/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class GenealogyCell: UITableViewCell {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var infoLabel: UILabel!
}

class Genealogy: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var search: UISearchController!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    var family: [[Student]] = []
    var query: Student?             // Highlighted student
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
        
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
        
        /* Need UIStackView */
        guard #available(iOS 9, *) else {
            let alert = UIAlertController(title: "Veuillez mettre à jour\nvotre appareil (iOS 8)",
                                          message: "L'arbre des parrainages n'est disponible qu'à partir d'iOS 9",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true, completion: nil)
            return
        }
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
                           let promotion = result["promo"]    as? String {
                            // Add this student to the family
                            let member = Student(id: id, name: name,
                                                  promotion: promotion, rank: StudentRank.parse(rank),
                                                  parents: parents, children: children)
                            familyMembers.append(member)
                            if member.id == student.id {
                                self.query = member
                            }
                        }
                    }
                    self.arrangeFamily(members: familyMembers)
                }
            } catch {}
        })
        Data.shared().updLoadingActivity(true)
        loadingIndicator.startAnimating()
        dataTask.resume()
    }
    
    func arrangeFamily(members: [Student]) {
        var tree: [[Student]] = []
        
        /* 1: Split students by rank */
        // Prepare: sort students by rank
        let students = members.sorted { $0.rank > $1.rank }
        var currentRank = StudentRank.Alumni
        var currentRankMembers: [Student]?
        // Allocate each rank
        for student in students {
            if currentRank == student.rank {
                // If still the same rank
                currentRankMembers?.append(student)
            } else {
                // If changed rank, save previous and start a new one
                if let previousRankMembers = currentRankMembers {
                    tree.append(previousRankMembers)
                }
                currentRank = student.rank
                currentRankMembers = [student]
            }
        }
        // Fill last rank
        if let previousRankMembers = currentRankMembers {
            tree.append(previousRankMembers)
        }
        
        /* 2: Order ranks by same parent and parent position */
        for (index, rank) in tree.enumerated() {
            // We'll order children according to each parent from current rank
            for student in rank {
                let children = student.children
                // Let's order children to be under this parent
                if !children.isEmpty && index < tree.count - 1 {
                    tree[index+1].sort(by: { (student1, student2) -> Bool in
                        return children.contains(student1.id)
                    })
                }
            }
        }
        
        family = tree
        
        // Reload data and display No Results accordingly
        self.tableView.reloadData()
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return family.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "genealogyCell", for: indexPath)
        
        if #available(iOS 9, *) {
            let famCell = cell as! GenealogyCell
            
            /* Remove labels from previous search */
            famCell.stackView.subviews.forEach {
                $0.removeFromSuperview()
            }
            
            let studentsForRank = family[indexPath.row]
            
            /* Fill with students */
            for student in studentsForRank {
                /* Setup a label per name */
                let nameBox = UILabel()
                nameBox.text = student.name
                nameBox.numberOfLines = 0
                nameBox.textAlignment = .center
                nameBox.textColor = UIColor.white
                
                /* Highlight requested student */
                if let q = query, q == student {
                    nameBox.font = UIFont.boldSystemFont(ofSize: 12)
                    var hue: CGFloat = 0.0; var saturation: CGFloat = 0.0; var brightness: CGFloat = 0.0; var alpha: CGFloat = 0.0
                    if self.tableView.tintColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
                        nameBox.backgroundColor = UIColor(hue: hue,
                                                          saturation: saturation - 0.15,
                                                          brightness: brightness + 0.15,
                                                          alpha: alpha)
                    } else {
                        nameBox.backgroundColor = self.tableView.tintColor
                    }
                } else {
                    nameBox.font = UIFont.systemFont(ofSize: 12)
                    nameBox.backgroundColor = self.tableView.tintColor
                }
                
                /* Fancy stuff and add to the stack view */
                nameBox.layer.cornerRadius = 4
                nameBox.clipsToBounds = true
                nameBox.adjustsFontSizeToFitWidth = true
                nameBox.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(>=35)]", options: [], metrics: nil, views: ["view": nameBox]))
                
                famCell.stackView.addArrangedSubview(nameBox)
            }
            
            /* Promotion setup */
            if let firstStudent = studentsForRank.first {
                famCell.infoLabel.text = firstStudent.rank.rawValue + " · " + firstStudent.promotion
            }
            
            /* Draw links between rows */
            let pathsView = GenealogyPathsView(frame: cell.frame)
            pathsView.family = self.family
            pathsView.currentRank = indexPath.row
            
            /* Alternate rows and setup background */
            pathsView.backgroundColor = indexPath.row & 1 == 0 ? #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.9882352941, alpha: 1) : .white
            cell.backgroundView = pathsView
        }

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
