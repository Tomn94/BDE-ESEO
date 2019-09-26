//
//  OrderPVC.swift
//  BDE-ESEO
//
//  Created by Benjamin Gondange on 31/10/2018.
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

import UIKit

class OrderPVC: UIPageViewController {

    var segmentedControl: UISegmentedControl?
    var toolbar: UIToolbar?
    var messageQuitterVu: Bool = false
    var vcs: [UIViewController] = []
    var data: CafetInfo? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageQuitterVu = false
        self.delegate = self
        self.dataSource = self
        self.view.backgroundColor =  UIColor.groupTableViewBackground
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Carte", style: .plain, target: nil, action: nil)
        let vc1: UIViewController? = self.storyboard?.instantiateViewController(withIdentifier:"OrderMenu")
        let vc2 = self.storyboard?.instantiateViewController(withIdentifier: "OrderPanier")
        // TODO [[OrderMenuTVC *)vc1 setPvcHolder:self.view];
        self.vcs = [vc1, vc2].compactMap { $0 }
        self.setViewControllers([vcs[0]], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        
        data = DataStore.shared.cafetData
        segmentedControl = UISegmentedControl(items: ["Carte", String(format: "Panier (%d)", DataStore.shared.cafetPanier?.selectedItems.count ?? 0)])
        let iPAD = UIDevice.current.userInterfaceIdiom == .pad
        segmentedControl?.frame = CGRect(x: 0, y: 0, width: 300, height: (iPAD || (!iPAD && UIScreen.main.bounds.size.height >= 736)) ? 29 : 21)
        segmentedControl?.selectedSegmentIndex = 0
        segmentedControl?.addTarget(self, action:#selector(tabSelected), for: .valueChanged)
        let barItem = UIBarButtonItem(customView: segmentedControl!)
        toolbar = UIToolbar()
        toolbar?.autoresizingMask = .flexibleWidth
        toolbar?.delegate = self
        toolbar?.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), barItem, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)], animated: false)
        self.view.addSubview(toolbar!)
        self.rotateToolbar()
        
        DataStore.shared.cafetDebut = Date.timeIntervalSinceReferenceDate
        Timer.scheduledTimer(timeInterval: TimeInterval(MAX_ORDER_TIME), target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        let ctr = NotificationCenter.default
        ctr.addObserver(self, selector: #selector(rotateToolbar), name: UIDevice.orientationDidChangeNotification, object: nil)
        ctr.addObserver(self, selector: #selector(updSegTitle), name: NSNotification.Name(rawValue: "updPanier"), object: nil)
        ctr.addObserver(self, selector: #selector(fermerForcer), name: NSNotification.Name(rawValue: "cmdValide"), object: nil)
        ctr.addObserver(self, selector: #selector(fermerForcerLydia), name: NSNotification.Name(rawValue: "cmdValideLydia"), object: nil)
        ctr.addObserver(self, selector: #selector(timeout), name: NSNotification.Name(rawValue: "retourAppCafetFin"), object: nil)
        
        // Handoff
        let activity = NSUserActivity(activityType: "com.eseomega.ESEOmega.order")
        activity.title = "Commander à la cafet"
        activity.webpageURL = URL(string: URL_ACT_ORDR)
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true
        if #available(iOS 12.0, *) {
            activity.isEligibleForPrediction = true
        }
        activity.isEligibleForPublicIndexing = true
        self.userActivity = activity
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userActivity?.becomeCurrent()
    }
    
    @objc func timeout() {
        if (messageQuitterVu) {
            return
        }
        messageQuitterVu = true
        let alert = UIAlertController(title: "Votre panier a expiré", message: "Pour des raisons de sécurité, il n'est possible de passer commande que pendant 10 minutes sans valider.\nMerci de bein vouloir recommencer. 😇", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {(action: UIAlertAction) -> Void in
            self.fermerForcer();
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @objc func fermerForcer() {
        self.dismiss(animated: true, completion: {() -> Void in
            DataStore.shared.cafetPanier = nil
            DataStore.shared.cafetDebut = 0
        })
        
    }
    
    @objc func fermerForcerLydia(n: NSNotification) {
        self.dismiss(animated: true, completion: {() -> Void in
            DataStore.shared.cafetPanier = nil
            DataStore.shared.cafetDebut = 0
            
            Lydia.startRequestObjCBridge(order: n.userInfo?["ID"] as! Int, type: n.userInfo?["catOrder"] as! String)
        })
    }
    
    @objc func tabSelected() {
        let vc = vcs[segmentedControl!.selectedSegmentIndex]
        self.setViewControllers([vc], direction: (segmentedControl!.selectedSegmentIndex == 1) ? UIPageViewController.NavigationDirection.forward : UIPageViewController.NavigationDirection.reverse, animated: true, completion: nil)
        if (segmentedControl!.selectedSegmentIndex == 1 && ((DataStore.shared.cafetPanier?.selectedItems.count)! > 0)) {
            let vc = vcs[1]
            self.navigationItem.setLeftBarButtonItems([vc.editButtonItem], animated: true)
        } else {
            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
        }
        
    }
    
    @objc func updSegTitle() {
        segmentedControl!.setTitle(String(format: "Panier (%d)", DataStore.shared.cafetPanier?.selectedItems.count ?? 0), forSegmentAt: 1)
        if (segmentedControl!.selectedSegmentIndex == 1 && ((DataStore.shared.cafetPanier?.selectedItems.count) != nil)) {
            let vc = vcs[1]
            self.navigationItem.setLeftBarButtonItems([vc.editButtonItem], animated: true)
        } else {
            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
        }
    }
    
    @objc func rotateToolbar() {
        guard let navBarHeight = self.navigationController?.navigationBar.frame.size.height else { return }
        let statusBarHeight = ((UIDevice.current.userInterfaceIdiom == .pad) ? 0 : UIApplication.shared.statusBarFrame.height)
        let dec = navBarHeight + statusBarHeight
        toolbar!.frame = CGRect(x: 0, y: dec, width: self.view.frame.size.width, height: 44)
    }
    
    func viewControllerAtIndex(index: Int) -> UIViewController? {
        if ((index < 0) || index >= self.vcs.count) {
            return nil;
        }
        return self.vcs[index]
    }
    
    @IBAction func fermer() {
        if (DataStore.shared.cafetPanier?.selectedItems.count != 0) {
            let alert = UIAlertController(title: "Vous avez des éléments dans votre panier", message: "Si vous annulez, vous perdrez votre commande en cours.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Supprimer ma commande", style: .destructive, handler: {(action: UIAlertAction) -> Void in
                self.fermerForcer()
            }))
            
            alert.addAction(UIAlertAction(title: "Continuer à commander", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.fermerForcer()
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension OrderPVC: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index: Int = vcs.firstIndex(of: viewController)!
        return self.viewControllerAtIndex(index: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index: Int = vcs.firstIndex(of: viewController)!
        return self.viewControllerAtIndex(index: index + 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (finished && completed) {
            segmentedControl!.selectedSegmentIndex = vcs.firstIndex(of: (self.viewControllers?[0])!) ?? 0
            if (segmentedControl!.selectedSegmentIndex == 1 && DataStore.shared.cafetPanier?.selectedItems.count != 0 && Data.shared()?.cafetCmdEnCours ?? false) {
                self.navigationItem.setLeftBarButtonItems([vcs[1].editButtonItem], animated: true)
            } else {
                self.navigationItem.setLeftBarButtonItems(nil, animated: true)
            }
        }
    }
    
    
}

extension OrderPVC: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
}
