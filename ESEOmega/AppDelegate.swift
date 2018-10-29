//
//  AppDelegate.swift
//  BDE-ESEO
//
//  Created by Benjamin Gondange on 30/08/2018.
//  Copyright © 2018 Benjamin Gondange

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

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    var VERSION_NOTIFS_iOS = 1.2
    var NV_VERSION_TITRE = "Une nouvelle version de l'app est disponible"
    var NV_VERSION_MESSG = "Impossible de recevoir les notifications, merci de mettre l'application à jour sur l'App Store."
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if (UserDefaults.standard.bool(forKey: "alreadyLaunchedv4NewAPI")) {
            SDImageCache.shared().clearDisk(onCompletion: nil)
            SDImageCache.shared().clearMemory()
            EGOCache.global().clear()
            UserDefaults.standard.set(true, forKey: "alreadyLaunchedv4NewAPI")
        }
        if (UserDefaults.standard.bool(forKey: "alreadyLaunchedv5NewAPI")) {
            SDImageCache.shared().clearDisk(onCompletion: nil)
            SDImageCache.shared().clearMemory()
            EGOCache.global().clear()
            UserDefaults.standard.set(true, forKey: "alreadyLaunchedv5NewAPI")
        }
        
        ThemeManager.updateTheme(appIcon: false)
        
        if (DataStore.isUserLogged) {
            Data.registeriOSPush(self)
        }
        
        /* APPLE WATCH */
        ConnectivityHandler.sharedHandler.startSession()
        
        // OPENED APP FROM NOTIFICATION
        if #available(iOS 10.0, *) {
            if launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil {
                guard let userInfo = launchOptions![UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any] else { return false }
                if (userInfo["aps"] != nil) {
                    guard let version = userInfo["version"] as? Double else { return false }
                    if (version <= VERSION_NOTIFS_iOS) {
                        guard let val = userInfo["action"] as? Int else { return false }
                        if (val >= 0) {
                            openNotif(userInfo)
                        }
                    } else {
                        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(delayedAlert(_:)), userInfo: ["titre": NV_VERSION_TITRE, "message": NV_VERSION_MESSG, "upd": true], repeats: false)
                    }
                }
            }
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - 3D Touch
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        let tab: TabBarController = self.window?.rootViewController as! TabBarController
        if (shortcutItem.type == "com.eseomega.ESEOmega.order") {
            tab.selectedIndex = 3
            
            let navVC: UINavigationController = tab.viewControllers![3] as! UINavigationController
            let ordersVC: CafetOrdersTVC = navVC.viewControllers.first as! CafetOrdersTVC
            
            if (ordersVC.isKind(of: CafetOrdersTVC.self)) {
                ordersVC.order()
            }
        } else if (shortcutItem.type == "com.eseomega.ESEOmega.events") {
            tab.selectedIndex = 1
        } else if (shortcutItem.type == "com.eseomega.ESEOmega.portail") {
            Data.shared()?.openURL(LinksToolbar.portalQuickLink, currentVC: tab, title: "Portail ESEO")
        } else if (shortcutItem.type == "com.eseomega.ESEOmega.campus") {
            Data.shared()?.openURL(LinksToolbar.campusQuickLink, currentVC: tab, title: "Campus ESEO")
        } else if (shortcutItem.type == "com.eseomega.ESEOmega.salles") {
            var dontReopen = false
            
            let vc: UIViewController = (self.window?.rootViewController?.presentedViewController)!
            if (vc.isKind(of: UINavigationController.self)) {
                let nvc: UINavigationController = self.window?.rootViewController?.presentedViewController as! UINavigationController
                if (nvc.isKind(of: RoomsTVC.self)) {
                    dontReopen = true
                }
            }
            if (!dontReopen) {
                let sb: UIStoryboard = UIStoryboard.init(name: "Rooms", bundle: nil)
                let vc: UINavigationController = sb.instantiateInitialViewController() as! UINavigationController;
                vc.modalPresentationStyle = .formSheet
                self.window?.rootViewController?.present(vc, animated: true, completion: nil)
            }
        }
        completionHandler(true)
    }
    
    // MARK: - Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Foundation.Data) {
        Data.shared()?.pushToken = deviceToken
        
        guard let token = Keychain.string(for: .token)
            else { return }
        let sToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        API.request(.pushRegister, post: ["token": sToken, "os": "IOS", ], authentication: token, completed: { data in
        }, failure: nil, noCache: true)
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    // iOS 10: In-app support
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      willPresent notification: UNNotification,
                                      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo: Dictionary<String, Any> = notification.request.content.userInfo as! Dictionary<String, Any>
        
        guard let vers = userInfo["version"] as? Double else {
            return
        }

        guard let val = userInfo["action"] as? Int else {
            return
        }
        
        if (vers > VERSION_NOTIFS_iOS || val == 21) {
            let alert = UIAlertController(title: NV_VERSION_TITRE, message: NV_VERSION_MESSG, preferredStyle: .alert)
            let updateAction = UIAlertAction(title: "Mettre à jour", style: .default) { (action: UIAlertAction) in
                UIApplication.shared.openURL(URL(string: URL_APPSTORE)!)
            }
            alert.addAction(updateAction)
            alert.addAction(UIAlertAction(title: "Ignorer", style: .cancel, handler: nil))
            alert.preferredAction = updateAction
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            
            completionHandler([])
        }
        completionHandler(UNNotificationPresentationOptions(rawValue: UNNotificationPresentationOptions.alert.rawValue | UNNotificationPresentationOptions.sound.rawValue))
    }
    
    // iOS 10: Action response
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if (response.actionIdentifier != UNNotificationDismissActionIdentifier) {
            self.openNotif(response.notification.request.content.userInfo)
        }
        completionHandler()
    }
    
    // pre-iOS 10
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        guard let vers = userInfo["version"] as? Double else {
            return
        }
        
        guard let val = userInfo["action"] as? Int else {
            return
        }
        
        if (vers > VERSION_NOTIFS_iOS || val == 21) {
            let alert: UIAlertController = UIAlertController(title: NV_VERSION_TITRE, message: NV_VERSION_MESSG, preferredStyle: .alert)
            let updateAction = UIAlertAction(title: "Mettre à jour", style: .default) { (action: UIAlertAction) in
                UIApplication.shared.openURL(URL(string: URL_APPSTORE)!)
            }
            alert.addAction(updateAction)
            alert.addAction(UIAlertAction(title: "Ignorer", style: .cancel, handler: nil))
            alert.preferredAction = updateAction
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            return
        }
        
        if (application.applicationState == .active) {
            var titre = ""
            var message = ""
            let aps: Dictionary<String, Any> = userInfo["aps"] as! Dictionary<String, Any>
            if !(aps["alert"] is String || aps["body"] is String) {
                let alert: Dictionary<String, Any> = aps["alert"] as! Dictionary<String, Any>
                titre = alert["title"] as! String
                message = alert["body"] as! String
            } else if (aps["alert"] as! String).range(of: "\n") != nil {
                var sep: Array = (aps["alert"] as! String).components(separatedBy: "\n")
                titre = sep[0]
                sep.remove(at: 0)
                message = sep.joined(separator: "\n")
            } else {
                message = aps["alert"] as! String
                
            }
            let alert: UIAlertController = UIAlertController(title: titre, message: message, preferredStyle: .alert)
            if (val > 0) {
                let defaultAction: UIAlertAction = UIAlertAction(title: "Voir", style: .default) { (action: UIAlertAction) in
                    self.openNotif(userInfo)
                }
                alert.addAction(defaultAction)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.window?.rootViewController?.present(alert, animated: true, completion: nil )
            }
            
            else if (val >= 0) {
                self.openNotif(userInfo)
            }
        }
    }
    
    func openNotif(_ userInfo: [AnyHashable: Any]) {
        guard let val = userInfo["action"] as? Int else {
            return
        }
        
        let tab: TabBarController = self.window?.rootViewController as! TabBarController
        
        switch val {
            case 42:
                if (!DataStore.isUserLogged) {
                    Timer.scheduledTimer(timeInterval: 0.5, target: tab, selector: #selector(tab.ecranConnex), userInfo: nil, repeats: false)
                } else {
                    Timer.scheduledTimer(timeInterval: 0.5, target: tab, selector: #selector(tab.secret), userInfo: nil, repeats: false)
                }
                return
            case 99:
                Timer.scheduledTimer(timeInterval: 0.5, target: tab, selector: #selector(tab.ecranConnex), userInfo: nil, repeats: false)
                return
            case 21:
                UIApplication.shared.openURL(URL(string: URL_APPSTORE)!)
                return
            case 85:
                let defaults = UserDefaults.standard
                defaults.setValue(true, forKey: "GPEnabled")
                defaults.synchronize()
                return
            case 86:
                let defaults = UserDefaults.standard
                defaults.setValue(false, forKey: "GPEnabled")
                defaults.synchronize()
                return
            case 0:
                var titre = ""
                var message = ""
                let aps: Dictionary<String, Any> = userInfo["aps"] as! Dictionary<String, Any>
                if !(aps["alert"] is String || aps["body"] is String) {
                    let alert: Dictionary<String, Any> = aps["alert"] as! Dictionary<String, Any>
                    titre = alert["title"] as! String
                    message = alert["body"] as! String
                } else if (aps["alert"] as! String).range(of: "\n") != nil {
                    var sep: Array = (aps["alert"] as! String).components(separatedBy: "\n")
                    titre = sep[0]
                    sep.remove(at: 0)
                    message = sep.joined(separator: "\n")
                } else {
                    message = aps["alert"] as! String
                    
                }
                
                Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(delayedAlert(_:)), userInfo: ["titre": titre, "message": message], repeats: false)
                return
            default:
                break
        }
        var index = 0
        if (val > 0) {
            index = val - 1
        }
        if (index >= tab.viewControllers!.count) {
            index = tab.viewControllers!.count - 1
        }
        
        if (index == 1) {
            Data.shared()?.updateJSON("events")
        } else if (index == 2) {
            Data.shared()?.updateJSON("clubs")
        } else if (index == 4) {
            Data.shared()?.updateJSON("sponsors")
        }
        
        tab.selectedIndex = index
        
    }
    
    @objc func delayedAlert(_ timer:Timer) {
        let infos = timer.userInfo as! Dictionary<String, Any>
        
        let alert = UIAlertController(title: (infos["titre"] as! String), message: (infos["message"] as! String), preferredStyle: .alert)
        
        if (infos["upd"] != nil && (infos["upd"] as! Bool)) {
            let updateAction = UIAlertAction(title: "Mettre à jour", style: .default) { (action: UIAlertAction) in
                UIApplication.shared.openURL(URL(string: URL_APPSTORE)!)
            }
            alert.addAction(updateAction)
            alert.addAction(UIAlertAction(title: "Ignorer", style: .cancel, handler: nil))
            alert.preferredAction = updateAction
            
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        }
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - URL Scheme Lydia
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        let tab: TabBarController = self.window?.rootViewController as! TabBarController
        
        if (url.host == "news") {
            tab.selectedIndex = 0
        } else if (url.host == "events") {
            tab.selectedIndex = 1
        } else if (url.host == "clubs") {
            tab.selectedIndex = 2
        } else if (url.host == "cafet") {
            tab.selectedIndex = 3
        } else if (url.host == "sponsors") {
            tab.selectedIndex = 4
        } else if (url.host == "pay") { // eseomega://pay?id=4242&cat=CAFET
            if (DataStore.isUserLogged) {
                var dict: [String: String] = [:]
                let pairs = url.query?.components(separatedBy: "&")
                
                for pair in pairs! {
                    let elements = pair.components(separatedBy: "=")
                    let key = elements[0].removingPercentEncoding
                    let val = elements[1].removingPercentEncoding
                    dict[key!] = val
                }
                
                if (dict["id"] != nil && dict["cat"] != nil) {
                    if Data.shared()?.alertRedir != nil {
                        let alert: UIAlertController = (Data.shared()?.alertRedir)!
                        alert.dismiss(animated: false, completion: nil)
                        Data.shared()?.alertRedir = nil
                    }
                    if ((dict["cat"] as! String) == "CAFET") {
                        tab.selectedIndex = 3
                    } else if ((dict["cat"] as! String) == "EVENT") {
                        tab.selectedIndex = 1
                    }
                    Lydia.checkStatusObjCBridge(dict, showRating: true)
                }
                
            } else {
                let alert = UIAlertController(title: "État du paiement Lydia", message: "Erreur : impossible de vérifier le paiement, vous n'êtes pas connecté à votre compte.\nParlez-en à un membre du BDE", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                tab.present(alert, animated: true, completion: nil)
            }
        }
        return true
    }
    // MARK: - Handoff
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let tab = self.window?.rootViewController as! TabBarController
        if ((Data.shared()?.cafetCmdEnCours)!) {
            return true
        }
        if (tab.presentedViewController !=  nil) {
            tab.dismiss(animated: true, completion: nil)
        }
        
        if (userActivity.activityType == "com.eseomega.ESEOmega.news") {
            tab.selectedIndex = 0
        } else if (userActivity.activityType == "com.eseomega.ESEOmega.article") {
            tab.selectedIndex = 0
            
            let newsSplit = tab.viewControllers?.first as! NewsSplit
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let detail = storyboard.instantiateViewController(withIdentifier: "newsArticleVC") as! NewsArticleVC
            detail.continueReading(userInfo: userActivity.userInfo as! [String : Any])
            newsSplit.showDetailViewController(detail, sender: nil)
        } else if (userActivity.activityType == "com.eseomega.ESEOmega.rooms") {
            tab.selectedIndex = 0
            
            let newsSplit = tab.viewControllers!.first as! NewsSplit
            newsSplit.master?.performSegue(withIdentifier: "showFamilies", sender: newsSplit.master)
        } else if (userActivity.activityType == "com.eseomega.ESEOmega.events") {
            tab.selectedIndex = 1
        } else if (userActivity.activityType == "com.eseomega.ESEOmega.clubs") {
            tab.selectedIndex = 2
        } else if (userActivity.activityType == "com.eseomega.ESEOmega.cafet") {
            tab.selectedIndex = 3
        } else if (userActivity.activityType == "com.eseomega.ESEOmega.orders") {
            tab.selectedIndex = 3
            
            let navVC = tab.viewControllers![3] as! UINavigationController
            let ordersVC = navVC.viewControllers.first as! CafetOrdersTVC
            ordersVC.order()
        } else if (userActivity.activityType == "com.eseomega.ESEOmega.sponsors") {
            tab.selectedIndex = 4
        }
        
        return true
    }
}
