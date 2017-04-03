//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Tomn on 28/09/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    var stickerBrowserViewController: StickerBrowserViewController!
    var label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = #colorLiteral(red: 0.4509803922, green: 0.8039215686, blue: 1, alpha: 1)
        
        stickerBrowserViewController = StickerBrowserViewController(stickerSize: .small)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showStickers), name: .stickersReloaded, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        stickerBrowserViewController.getStickersFromCache()
        stickerBrowserViewController.getStickersFromServer()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        label.removeFromSuperview()
        if stickerBrowserViewController.stickers.count == 0 {
            label.frame = view.bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            label.text = "Récupération des stickers…"
            label.textAlignment = .center
            label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            label.backgroundColor = #colorLiteral(red: 0.4509803922, green: 0.8039215686, blue: 1, alpha: 1)
            self.view.addSubview(label)
        }
    }
    
    func showStickers() {
        if stickerBrowserViewController.stickers.count > 0 {
            label.removeFromSuperview()
        }
        
        stickerBrowserViewController.view.frame = self.view.frame
        stickerBrowserViewController.stickerBrowserView.backgroundColor = #colorLiteral(red: 0.4509803922, green: 0.8039215686, blue: 1, alpha: 1)
        addChildViewController(stickerBrowserViewController)
        
        stickerBrowserViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stickerBrowserViewController.view)
        stickerBrowserViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        stickerBrowserViewController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        stickerBrowserViewController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        stickerBrowserViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        stickerBrowserViewController.didMove(toParentViewController: self)
    }
}

extension Notification.Name {
    static let stickersReloaded = Notification.Name(rawValue: "stickersReloaded")
}
