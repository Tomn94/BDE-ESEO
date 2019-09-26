//
//  Genealogy.swift
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

class GenealogyCell: UITableViewCell {
    
    /// Student names
    @IBOutlet weak var stackView: UIStackView!
    
    /// Promotion info
    @IBOutlet weak var infoLabel: UILabel!
    
}


class Genealogy: UITableViewController {
    
    private let reuseIdentifier = "genealogyCell"
    
    
    var search: UISearchController!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var family: [[FamilyMember]] = []
    
    /// Highlighted student
    var query: FamilyMember?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UITableViewHeaderFooterView()
        tableView.backgroundColor = .groupTableViewBackground
        
        /* Configure Search Bar and Search Display Controller */
        let storyboard = UIStoryboard(name: "GenealogySearch", bundle: nil)
        if let searchDisplay = storyboard.instantiateInitialViewController() as? GenealogySearch {
            searchDisplay.familyScreen = self  // Set search callback
            search = UISearchController(searchResultsController: searchDisplay)
            search.searchResultsUpdater = searchDisplay
            search.obscuresBackgroundDuringPresentation = false
            search.searchBar.placeholder = "Rechercher un étudiant"
            search.searchBar.sizeToFit()
            self.tableView.tableHeaderView = search.searchBar
        }
        
        // Directly show user's family at launch
        loadUserFamily()
        
        /* Handoff */
        let info = ActivityType.families
        let activity = NSUserActivity(activityType: info.type)
        activity.title = info.title
        activity.webpageURL = info.url
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true
        activity.isEligibleForPublicIndexing = true
        self.userActivity = activity
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userActivity?.becomeCurrent()
    }
    
    /// Redraw connections when orientation changes
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        self.tableView.reloadData()
    }
    
    /// Display user family according to stored username.
    /// First result is used, so it might not work for people with the same name.
    func loadUserFamily() {
        
        guard let username = Keychain.string(for: .name)
            else { return }
        
        /* Ask students results */
        API.request(.familySearch, get: ["name" : username], completed: { data in
            
            guard let result = try? JSONDecoder().decode(StudentSearchResult.self,
                                                         from: data),
                  result.success
                else { return }
            
            /* Select first exact match */
            guard let familyMember = result.users.sorted(by: { user, _ in
                user.fullname.localizedStandardCompare(username) == .orderedAscending
            }).first else { return }
            
            DispatchQueue.main.async {
                self.setUpFamily(for: familyMember,
                                 dismissSearch: false)
            }
        })
    }
    
    /// Get family for student previously searched
    ///
    /// - Parameters:
    ///   - student: The student whose family is requested by its ID number
    ///   - dismissSearch: Wether search results view controller should be dismissed first
    func setUpFamily(for student: FamilyMember, dismissSearch: Bool = true) {
        
        /* Dismiss search */
        if dismissSearch {
            search.isActive = false
        }
        
        loadingIndicator.startAnimating()
        
        /* Ask family members for the student */
        let familyID = String(student.familyID)
        API.request(.family, appendPath: familyID, completed: { data in
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
            }
            
            /* Parse the new data */
            guard let result = try? JSONDecoder().decode(FamilyResult.self,
                                                         from: data),
                  result.success
                else { return }
            
            let familyMembers = result.familyMembers
            
            familyMembers.forEach { familyMember in
                if familyMember.ID == student.ID {
                    self.query = familyMember
                }
            }
            
            self.arrangeFamily(members: familyMembers)
            
        }, failure: { _, _ in
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
            }
        })
    }
    
    /**
     Sort the array of students received into one family tree
     - Parameter members: Students to be organized
     */
    func arrangeFamily(members: [FamilyMember]) {
        
        var tree: [[FamilyMember]] = []
        
        /* 1: Split students by rank and Weight them */
        // Prepare: sort students by rank
        let students = members.sorted { $0.rank < $1.rank }
        var currentRank = 0
        var currentRankMembers: [FamilyMember]?
        
        // Attribute weight to each student to later sort the whole tree
        var studentWeight = [StudentID : Int]()
        var firstRankWeights = [Int]()
        
        // Allocate each rank
        for student in students {
            if currentRank == student.rank {
                // If still the same rank
                if currentRankMembers == nil {
                    currentRankMembers = [student]
                } else {
                    currentRankMembers!.append(student)
                }
            } else {
                // If changed rank, save previous and start a new one
                if let previousRankMembers = currentRankMembers {
                    tree.append(previousRankMembers)
                }
                currentRank = student.rank
                currentRankMembers = [student]
            }
            
            if currentRank == 0 {
                // For first rank, weight is decreasing the more children the student has
                // Checks we don't have the same weight twice, otherwise children could then have the same too.
                // If it's the case, we must decrease with a counter, otherwise we might interfer with the previous substraction and then find again the same weight.
                // PLEASE Check changes with Alessandro MOSCA, Alexandre JULIEN and Thibaud AUBERT
                var counter = 0
                var weight  = 1000
                repeat {
                    weight   = 1000 - (student.childIDs?.count ?? 0) - counter
                    counter += 1
                } while firstRankWeights.contains(weight)
                firstRankWeights.append(weight)
                studentWeight[student.ID] = weight
                
            } else {
                // For other ranks, compute parents weight for each member
                var weight = 0
                for parentID in student.parentIDs ?? [] {
                    weight += studentWeight[parentID] ?? 0
                }
                studentWeight[student.ID] = weight == 0 ? 1 : weight
            }
        }
        // Fill last rank
        if let previousRankMembers = currentRankMembers {
            tree.append(previousRankMembers)
        }
        
        /* 2: Order ranks by same parent and parent position */
        for (index, rank) in tree.enumerated() {
            // We'll order children according to each parent from current rank
            tree[index] = rank.sorted { student1, student2 in
                studentWeight[student1.ID] ?? 0 < studentWeight[student2.ID] ?? 0
            }
        }
        
        family = tree
        
        DispatchQueue.main.async {
            /* Reload data, display No Results accordingly and animate */
            let animation = CATransition()
            animation.duration = 0.45
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            self.tableView.layer.add(animation, forKey: nil)
            
            self.tableView.reloadData()
        }
    }

}


// MARK: - Table view data source
extension Genealogy {

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        return family.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                 for: indexPath) as! GenealogyCell
        
        /* Remove labels from previous search */
        cell.stackView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let studentsForRank = family[indexPath.row]
        
        /* Fill with students */
        for student in studentsForRank {
            /* Setup a label per name */
            let nameBox = UILabel()
            nameBox.text = student.fullname
            nameBox.numberOfLines = 0
            nameBox.textAlignment = .center
            nameBox.textColor     = .white
            
            /* Highlight requested student */
            if let q = query, q == student {
                nameBox.font = UIFont.preferredFont(forTextStyle: .caption1).bold()
                var hue: CGFloat = 0;   var saturation: CGFloat = 0
                var brightness: CGFloat = 0; var alpha: CGFloat = 0
                if self.tableView.tintColor.getHue(&hue, saturation: &saturation,
                                                   brightness: &brightness, alpha: &alpha) {
                    nameBox.backgroundColor = UIColor(hue: hue,
                                                      saturation: saturation - 0.15,
                                                      brightness: brightness + 0.15,
                                                      alpha: alpha)
                } else {
                    nameBox.backgroundColor = self.tableView.tintColor
                }
            } else {
                nameBox.font = UIFont.preferredFont(forTextStyle: .caption1)
                nameBox.backgroundColor = self.tableView.tintColor
            }
            
            /* Fancy stuff and add to the stack view */
            nameBox.layer.cornerRadius = 4
            nameBox.clipsToBounds = true
            nameBox.adjustsFontSizeToFitWidth = true
            nameBox.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(>=35)]",
                                                                  options: [], metrics: nil,
                                                                  views: ["view": nameBox]))
            
            cell.stackView.addArrangedSubview(nameBox)
        }
        
        /* Promotion setup */
        if let firstStudent = studentsForRank.first {
            cell.infoLabel.text = firstStudent.promo
        }
        
        /* Draw links between rows */
        let pathsView = GenealogyPathsView(frame: cell.frame)
        pathsView.family      = self.family
        pathsView.currentRank = indexPath.row
        
        /* Alternate rows and setup background */
        pathsView.backgroundColor = indexPath.row & 1 == 0 ? #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.9882352941, alpha: 1) : .white
        cell.backgroundView       = pathsView

        return cell
    }
    
}


// MARK: - Empty Data Set Source
extension Genealogy: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "genealogyEmpty")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
    
        return NSAttributedString(string: "Retrouvez ici les familles de parrainage à l'ESEO",
                                  attributes: [.foregroundColor: UIColor.darkGray])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {

        return NSAttributedString(string: "Commencez par rechercher un nom !",
                                  attributes: [.font: UIFont.preferredFont(forTextStyle: .subheadline),
                                               .foregroundColor: UIColor.lightGray])
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        
        return .groupTableViewBackground
    }

}
