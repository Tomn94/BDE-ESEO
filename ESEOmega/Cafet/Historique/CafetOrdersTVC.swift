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

class CustomHeaderView: UIView {
    
    @IBOutlet weak var serviceLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        serviceLabel.preferredMaxLayoutWidth = serviceLabel.bounds.size.width
    }
    
}

fileprivate extension Selector {
    /// Timer for regular updates on order status
    static let triggerUpdate = #selector(CafetOrdersTVC.triggerUpdate)
    /// Called when Low Power mode toggled
    static let toggleUpdates = #selector(CafetOrdersTVC.toggleUpdates)
}


/// Lists user's orders at the cafétéria
class CafetOrdersTVC: UITableViewController {
    
    private static let versionCheckURL = "https://itunes.apple.com/fr/lookup?bundleId=com.eseomega.ESEOmega"
    
    private let reuseIdentifier = "commandeCell"
    
    
    /// User's orders, split by status
    var orders = [[CafetOrder]]()
    
    var serviceStatus = "Cafétéria en ligne non disponible"
    
    var updateTimer: Timer?
    
    static let updateInterval: TimeInterval = 10
    
    
    @IBOutlet weak var userButton: UIBarButtonItem!
    
    @IBOutlet var orderButton: UIBarButtonItem!
    
    @IBOutlet var loadingButton: UIBarButtonItem!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Refresh control */
        if #available(iOS 11.0, *) {
            tableView.separatorInsetReference = .fromAutomaticInsets
            navigationController?.navigationBar.prefersLargeTitles = true
            refreshControl?.tintColor = .white
        } else {
            refreshControl?.tintColor = UINavigationBar.appearance().barTintColor ?? .blue
        }
        
        navigationItem.leftBarButtonItems = [orderButton]
        
        /* Handoff */
        let info = ActivityType.cafet
        let activity = NSUserActivity(activityType: info.type)
        activity.title = info.title
        activity.webpageURL = info.url
        activity.isEligibleForSearch = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        self.userActivity = activity
        
        NotificationCenter.default.addObserver(self, selector: .toggleUpdates,
                                               name: .NSProcessInfoPowerStateDidChange,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* Load local data and ask for updates */
        loadFromCache()
        fetchRemote()
        fetchService()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        if let selection = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selection, animated: true)
        }
        
        userActivity?.becomeCurrent()
    }
    
    
    // MARK: - Timer
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startUpdates()
        fetchService()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopUpdates()
    }
    
    
    func startUpdates() {
        
        guard !ProcessInfo.processInfo.isLowPowerModeEnabled else {
            stopUpdates()
            return
        }
        
        updateTimer = Timer.scheduledTimer(timeInterval: CafetOrdersTVC.updateInterval,
                                           target: self, selector: .triggerUpdate,
                                           userInfo: nil, repeats: true)
    }
    
    func stopUpdates() {
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc func toggleUpdates() {
        
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            stopUpdates()
        } else if !(updateTimer?.isValid ?? false) {
            startUpdates()
        }
    }
    
    @objc func triggerUpdate() {
        
        fetchRemote()
    }
    
    
    // MARK: - Actions
    
    @IBAction func refresh() {
        
        fetchRemote()
    }
    
    @IBAction func order() {
        
        guard DataStore.isUserLogged else {
            let alert = UIAlertController(title: "Connectez-vous !",
                                          message: "Connectez-vous grâce au bouton en haut à droite pour commander à la cafet !",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
            let connectAction = UIAlertAction(title: "Me connecter", style: .default, handler: { _ in
                
                guard let action = self.userButton.action,
                      let target = self.userButton.target
                    else { return }
                
                UIApplication.shared.sendAction(action, to: target,
                                                from: nil, for: nil)
            })
            alert.addAction(connectAction)
            alert.preferredAction = connectAction
            present(alert, animated: true)
            return
        }
        
        checkVersion()
    }
    
    /// Step 1
    func checkVersion() {
        
        let session  = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        let url      = URL(string: CafetOrdersTVC.versionCheckURL)!
        let dataTask = session.dataTask(with: url) { data, _, error in
            
            Utils.requiresActivityIndicator(false)
            
            var title   = "Erreur"
            var message = "Impossible de vérifier si l'application est à jour"
            var updateAvailable = false
            
            if error == nil && data != nil,
               let JSON    = try? JSONSerialization.jsonObject(with: data!, options: []),
               let info         = JSON            as?  [String : Any],
               let results      = info["results"] as? [[String : Any]],
               let app          = results.first,
               let storeVersion = app["version"]  as?   String,
               let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                
                if storeVersion.compare(appVersion, options: .numeric) != .orderedDescending {
                    
                    self.checkTime()
                    return
                    
                } else {
                    
                    title   = NEW_UPD_TI
                    message = NEW_UPD_TE
                    updateAvailable = true
                }
                
            }
            
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: updateAvailable ? "Cancel" : "OK", style: .cancel))
            if updateAvailable {
                let updateAction = UIAlertAction(title: NEW_UPD_BT, style: .default, handler: { _ in
                    UIApplication.shared.openURL(URL(string: URL_APPSTORE)!)
                })
                alert.addAction(updateAction)
                alert.preferredAction = updateAction
            }
            DispatchQueue.main.async {
                self.present(alert, animated: true)
                self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
            }
        }
        
        loadingIndicator.startAnimating()
        navigationItem.setLeftBarButton(loadingButton, animated: true)
        Utils.requiresActivityIndicator(true)
        dataTask.resume()
    }
    
    /// Step 2
    func checkTime() {
        
        guard let token = JNKeychain.loadValue(forKey: KeychainKey.token) as? String else {
            self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
            return
        }
        
        let timeZone = TimeZone.current
        guard timeZone.identifier == "Europe/Paris" else {
            let alert = UIAlertController(title: "Erreur 🌍",
                                          message: "L'accès à la cafet ne peut se faire depuis un autre pays que la France.\nEnvoyez-nous une carte postale !",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "D'accord", style: .cancel))
            present(alert, animated: true)
            self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
            return
        }
        
        let defaultError = "Impossible de se connecter au serveur\nSi le problème persiste, vous pouvez toujours venir commander au comptoir."
        
        API.request(.newOrder, get: ["os"   : "IOS",
                                     "tstp" : String(Date().timeIntervalSince1970)],
                    authentication: token, completed: { data in
            
            guard let result = try? JSONDecoder().decode(CafetNewOrderResult.self, from: data),
                  result.success else {
                
                API.handleFailure(data: data, mode: .presentFetchedMessage(self),
                                  defaultMessage: defaultError)
                DispatchQueue.main.async {
                    self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
                }
                return
            }
                    
            self.startShopping(with: result.token)
            
        }, failure: { _, data in
            
            API.handleFailure(data: data, mode: .presentFetchedMessage(self),
                              defaultMessage: defaultError)
            DispatchQueue.main.async {
                self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
            }
        })
    }
    
    func startShopping(with token: String) {
        
        guard let userToken = JNKeychain.loadValue(forKey: KeychainKey.token) as? String else {
            self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
            return
        }
        
        let defaultError = "Impossible de récupérer les menus"
        
        API.request(.menus, authentication: userToken, completed: { data in
            
            // TODO: tester si aucun element/ingrédient/menu/categorie disponible
            guard let result = try? JSONDecoder().decode(CafetMenusResult.self, from: data),
                  result.success else {
                
                API.handleFailure(data: data, mode: .presentFetchedMessage(self),
                                  defaultMessage: defaultError)
                DispatchQueue.main.async {
                    self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
                }
                return
            }
            
            let storyboard = UIStoryboard(name: "Order", bundle: nil)
            let orderVC = storyboard.instantiateViewController(withIdentifier: "Order")
            orderVC.modalTransitionStyle = self.traitCollection.horizontalSizeClass == .regular
                                         ? .coverVertical : .flipHorizontal
            orderVC.modalPresentationStyle = .formSheet
            DispatchQueue.main.async {
                self.present(orderVC, animated: true)
                self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
            }
            // TODO: Give token + data
            
        }, failure: { _, data in
            
            API.handleFailure(data: data, mode: .presentFetchedMessage(self),
                              defaultMessage: defaultError)
            DispatchQueue.main.async {
                self.navigationItem.setLeftBarButton(self.orderButton, animated: true)
            }
        })
    }
    
    @objc func dismissDetail() {
        
        dismiss(animated: true)
    }
}


// MARK: - API Viewer
extension CafetOrdersTVC: APIViewer {
    
    typealias T = [CafetOrder]
    
    
    func loadFromCache() {
        
        guard DataStore.isUserLogged else {
            orders = []
            reloadData()
            return
        }
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = NewsArticle.dateFormat
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        guard let data   = APIArchiver.getCache(for: .orders),
              let result = try? decoder.decode([CafetOrder].self, from: data) else {
                reloadData()
                return
        }
        
        self.loadData(result)
    }
    
    func fetchRemote() {
        
        guard let token = JNKeychain.loadValue(forKey: KeychainKey.token) as? String
            else { return }
        
        API.request(.orders, get: ["all": "1"], authentication: token,
                    completed: { data in
            
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
            
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = CafetOrder.dateFormat
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            guard let result = try? decoder.decode(CafetOrdersResult.self, from: data),
                  result.success
                else { return }
            
            self.loadData(result.orders)
            APIArchiver.save(data: result.orders, for: .orders)
            
        }, failure: { _, _ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    func loadData(_ data: [CafetOrder]) {
        
        let groupedOrdersByStatus = Dictionary(grouping: data,
                                               by: { order in order.status })
        
        orders = []
        let sortedKeys = Array(groupedOrdersByStatus.keys).sorted {
            $0.rawValue < $1.rawValue
        }
        if let notPaid = groupedOrdersByStatus[.notPaid] {
            // Added first since their rawValue is 3 (> 0, 1, 2)
            // but we need them on top
            orders.append(notPaid)
        }
        for key in sortedKeys where key != .notPaid {
            orders.append(groupedOrdersByStatus[key]!)
        }
        
        self.reloadData()
    }
    
    func reloadData() {
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Service
    
    func fetchService() {
        
        guard let token = JNKeychain.loadValue(forKey: KeychainKey.token) as? String
            else { return }
        
        let unavailableStatus = "Cafétéria en ligne non disponible"
        
        API.request(.orderService, authentication: token,
                    completed: { data in
            
            guard let result = try? JSONDecoder().decode(CafetServiceResult.self, from: data),
                  result.success else {
                self.serviceStatus = unavailableStatus
                return
            }
            
            self.serviceStatus = result.message.replacingOccurrences(of: "\\n", with: "\n")
            self.updateService()

        }, failure: { error, data in
            self.serviceStatus = unavailableStatus
            self.updateService()
        })
    }
    
    func updateService() {
        
        DispatchQueue.main.async {
            
            guard let header = self.tableView.tableHeaderView as? CustomHeaderView,
                  let label  = header.serviceLabel
                else { return }
            
            label.text = self.serviceStatus
            label.sizeToFit()
            
            let constraintRect = CGSize(width: label.frame.width,
                                        height: .greatestFiniteMagnitude)
            let boundingBox = self.serviceStatus.boundingRect(with: constraintRect,
                                                              options: .usesLineFragmentOrigin,
                                                              attributes: [.font: label.font],
                                                              context: nil)
            var offset: CGFloat = 15
            if #available(iOS 11.0, *) {
                offset = UIFontMetrics.default.scaledValue(for: offset)
            }
            header.frame.size.height = boundingBox.height + offset
            
            self.tableView.tableHeaderView = header
        }
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
        
        guard let firstOrderStatus = orders[section].first?.status
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
        
        if #available(iOS 11.0, *) {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 63, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 79, bottom: 0, right: 0)
        }
        
        cell.nomLabel.font       = UIFont.systemFont(ofSize: 16)
        cell.prixLabel.font      = UIFont.systemFont(ofSize: 16)
        cell.dateLabel.textColor = .darkGray
        cell.numLabel.textColor  = .darkGray
        
        let color = order.status.color
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
        
        cell.nomLabel.textColor  = color
        cell.prixLabel.textColor = color
        
        cell.color = color
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
        
        guard segue.identifier == "cafetOrderDetailSegue",
              let destination  = segue.destination as? CafetOrderVC,
              let indexPath    = tableView.indexPathForSelectedRow
            else { return }
        
        destination.order = orders[indexPath.section][indexPath.row]
    }
    
}


// MARK: - 3D Touch
extension CafetOrdersTVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location)
            else { return nil }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destination = storyboard.instantiateViewController(withIdentifier: "detailCmd") as! CafetOrderVC
        
        destination.order = orders[indexPath.section][indexPath.row]
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
        let segue = CafetOrderDetailSegue(identifier: "cafetOrderDetailSegue",
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
        
        return CGPoint(x: 0, y: -(tableView.tableHeaderView?.frame.size.height ?? 0))
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
