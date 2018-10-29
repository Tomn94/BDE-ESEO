//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Tomn on 28/09/2016.
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
import Messages

fileprivate extension Selector {
    static let showStickers = #selector(MessagesViewController.showStickers)
}

class MessagesViewController: MSMessagesAppViewController {
    
    var stickerBrowserViewController: StickerBrowserViewController!
    
    var label = UILabel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = #colorLiteral(red: 0.4509803922, green: 0.8039215686, blue: 1, alpha: 1)
        
        stickerBrowserViewController = StickerBrowserViewController(stickerSize: .small)
        stickerBrowserViewController.view.frame = view.bounds
        stickerBrowserViewController.stickerBrowserView.backgroundColor = #colorLiteral(red: 0.4509803922, green: 0.8039215686, blue: 1, alpha: 1)
        addChild(stickerBrowserViewController)
        
        stickerBrowserViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stickerBrowserViewController.view)
        stickerBrowserViewController.didMove(toParent: self)
        
        label.frame = view.bounds
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Récupération des stickers…"
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        label.backgroundColor = #colorLiteral(red: 0.4509803922, green: 0.8039215686, blue: 1, alpha: 1)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            stickerBrowserViewController.view.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor),
            stickerBrowserViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            stickerBrowserViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            stickerBrowserViewController.view.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor),
            label.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor),
            label.leftAnchor.constraint(equalTo: view.leftAnchor),
            label.rightAnchor.constraint(equalTo: view.rightAnchor),
            label.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor)
        ])
        
        stickerBrowserViewController.view.alpha = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(showStickers),
                                               name: .stickersReloaded, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        stickerBrowserViewController.getStickersFromCache()
        stickerBrowserViewController.getStickersFromServer()
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        
        view.setNeedsLayout()
    }
    
    @objc func showStickers() {
        
        UIView.animate(withDuration: 0.2) {
            
            let hasStickers = self.stickerBrowserViewController.stickers.count > 0
            self.label.alpha                             = hasStickers ? 0 : 1
            self.stickerBrowserViewController.view.alpha = hasStickers ? 1 : 0
        }
    }
}
