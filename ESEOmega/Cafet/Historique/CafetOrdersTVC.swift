//
//  CafetOrdersTVC.swift
//  BDE-ESEO
//
//  Created by Thomas Naudet on 08/10/2017.
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

import UIKit


/// Lists user's orders at the cafétéria
class CafetOrdersTVC: UITableViewController {
    
    private let reuseIdentifier = "commandeCell"
    
    
    /// User's orders, split by status
    var orders = [[CafetOrder]]()
    
    var updateTimer: Timer?
    
    @IBOutlet weak var userButton: UIBarButtonItem!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Load local data and ask for updates */
        loadFromCache()
        fetchRemote()
        
        /* Refresh control */
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            refreshControl?.tintColor = .white
        } else {
            refreshControl?.tintColor = UINavigationBar.appearance().barTintColor ?? .blue
        }
        
        /* Handoff */
        let info = ActivityType.cafet
        let activity = NSUserActivity(activityType: info.type)
        activity.title = info.title
        activity.webpageURL = info.url
        activity.isEligibleForSearch = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        self.userActivity = activity
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        if let selection = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selection, animated: true)
        }
        
        userActivity?.becomeCurrent()
    }
    
    
    // MARK: Actions
    
    @IBAction func refresh() {
        
        fetchRemote()
    }
    
    func order() {
        
    }
    
    func dismissDetail() {
        
        dismiss(animated: true)
    }
}


extension CafetOrdersTVC: APIViewer {
    
    typealias T = [CafetOrder]
    
    
    func loadFromCache() {
    }
    
    func fetchRemote() {
    }
    
    func loadData(_ data: [CafetOrder]) {
    }
    
    func reloadData() {
    }
    
}


// MARK: - Table View Data Source
extension CafetOrdersTVC {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return orders.count
    }
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return orders[section].count
    }
    
    override func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        
        let nbrOrdersInSection     = orders[section].count
        guard let firstOrderStatus = orders[section].first?.status
            else { return nil }
        
        if nbrOrdersInSection > 1 {
            return firstOrderStatus.pluralName
        }
        else if nbrOrdersInSection == 1 {
            return firstOrderStatus.singularName
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForFooterInSection section: Int) -> String? {
        
        let nbrOrdersInSection     = orders[section].count
        guard orders[nbrOrdersInSection].count > 0,
              let firstOrderStatus = orders[section].first?.status
            else { return nil }
        
        switch firstOrderStatus {
        case .preparing:
            return ""
        case .ready:
            return "Merci de venir à la cafet chercher votre repas."
        case .done:
            return ""
        case .notPaid:
            return "Merci de venir à la cafet ou au BDE régler au plus vite, sinon contactez-nous.\nVous ne pouvez pas commander sans régler ceci au préalable."
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell  = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                  for: indexPath) as! CommandesCell
        let order = orders[indexPath.section][indexPath.row]
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 79, bottom: 0, right: 0)
        
        cell.nomLabel.font       = UIFont.systemFont(ofSize: 16)
        cell.prixLabel.font      = UIFont.systemFont(ofSize: 16)
        cell.dateLabel.textColor = .darkGray
        cell.numLabel.textColor  = .darkGray
        
        switch order.status
        {
        case .preparing:
            cell.imgView.image = #imageLiteral(resourceName: "cafetPreparing")
                
        case .ready:
            cell.nomLabel.font  = UIFont.boldSystemFont(ofSize: 16)
            cell.prixLabel.font = UIFont.boldSystemFont(ofSize: 16)
            cell.imgView.image  = #imageLiteral(resourceName: "cafetReady")
                
        case .done:
            cell.dateLabel.textColor = .lightGray
            cell.numLabel.textColor  = .lightGray
            cell.imgView.image       = #imageLiteral(resourceName: "cafetDone")
            
        case .notPaid:
            cell.nomLabel.font  = UIFont.boldSystemFont(ofSize: 16)
            cell.prixLabel.font = UIFont.boldSystemFont(ofSize: 16)
            cell.imgView.image  = #imageLiteral(resourceName: "cafetNotPaid")
        }
        
        cell.nomLabel.textColor  = order.status.color
        cell.prixLabel.textColor = order.status.color
        
        cell.color = order.status.color
        cell.imgView.layer.cornerRadius  = 24
        cell.imgView.layer.shadowColor   = UIColor.lightGray.cgColor
        cell.imgView.layer.shadowOffset  = CGSize(width: 0, height: 1)
        cell.imgView.layer.shadowOpacity = 1
        cell.imgView.layer.shadowRadius  = 1
        
        cell.nomLabel.text = order.resume.replacingOccurrences(of: "<br>", with: ", ")
        cell.dateLabel.text = DateFormatter.localizedString(from: order.datetime,
                                                            dateStyle: .full,
                                                            timeStyle: .short)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale      = Locale(identifier: "fr_FR")
        cell.prixLabel.text   = formatter.string(from: NSNumber(value: order.price))
        cell.numLabel.text    = String(format: "%@%03d", order.strcmd, order.modcmd)
        
        return cell
    }
    
    /// Selection
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard segue.identifier == "commandeDetailSegue",
              let destination  = segue.destination as? CommandesDetailVC,
              let indexPath    = tableView.indexPathForSelectedRow
            else { return }
        
//        destination.infos = orders[indexPath.section][indexPath.row]
    }
    
}


// MARK: - 3D Touch
extension CafetOrdersTVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location)
            else { return nil }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destinationViewController = storyboard.instantiateViewController(withIdentifier: "detailCmd") as! CommandesDetailVC
        
//        destinationViewController.infos = orders[indexPath.section][indexPath.row]
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        
        return destinationViewController;
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
        let segue = CommandeDetailSegue(identifier: "commandeDetailSegue",
                                        source: self,
                                        destination: viewControllerToCommit)
        segue.perform()
    }
    
    
}


// MARK: - Empty Data Set Source
extension CafetOrdersTVC: DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return DataStore.isUserLogged ? #imageLiteral(resourceName: "cafetVide1") : #imageLiteral(resourceName: "cafetVide2")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let title = DataStore.isUserLogged
                      ? "Vous n'avez encore rien commandé"
                      : "Vous n'êtes pas connecté"
        
        return NSAttributedString(string: title,
                                  attributes: [.foregroundColor : UIColor.darkGray])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let text = DataStore.isUserLogged
                     ? "Tapez sur le bouton ＋ pour commander,\nvos commandes s'afficheront ici."
                     : "Connectez-vous à votre profil ESEO pour commander à la cafet."
        
        return NSAttributedString(string: text,
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline),
                                               .foregroundColor : UIColor.lightGray])
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!,
                     for state: UIControlState) -> NSAttributedString! {
        
        let buttonTitle = DataStore.isUserLogged ? "Commander" : "Me connecter"
        return NSAttributedString(string: buttonTitle,
                                  attributes: [.font : UIFont.preferredFont(forTextStyle: .headline),
                                               .foregroundColor : UINavigationBar.appearance().barTintColor ?? .blue])
    }
    
    func offset(forEmptyDataSet scrollView: UIScrollView!) -> CGPoint {
        
        return CGPoint(x: 0, y: -(tableView.tableHeaderView?.frame.size.height ?? 0) / 2)
    }
    
}


// MARK: - Empty Data Set Delegate
extension CafetOrdersTVC: DZNEmptyDataSetDelegate {
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        
        guard DataStore.isUserLogged else {
            
            guard let action = userButton.action,
                  let target = userButton.target
                else { return }
            
            UIApplication.shared.sendAction(action, to: target,
                                            from: nil, for: nil)
            return
        }
        
        order()
    }
    
}
