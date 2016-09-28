//
//  StickerBrowserViewController.swift
//  ESEOmega
//
//  Created by Tomn on 28/09/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import Foundation
import UIKit
import Messages

class StickerBrowserViewController: MSStickerBrowserViewController {
    
    let stickerListURL = "https://web59.secure-secure.co.uk/francoisle.fr/lacommande/api/stickers/stickers.json"
    var stickers = [MSSticker]()
    
    // MARK: Delegates
    
    override func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        return stickers.count
    }
    
    override func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
        return stickers[index]
    }
    
    /// Fetch cached stickers
    func getStickersFromCache() {
        if let cache = UserDefaults.standard.object(forKey: "stickerList") as? [[String]] {
            let fileManager = FileManager.default
            let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
            let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
            
            for cachedSticker in cache where cachedSticker.count > 1 {
                if let imageURL = URL(string: cachedSticker[0]),
                   let imageName = imageURL.pathComponents.last,
                   let fileURL = tmpSubFolderURL?.appendingPathComponent(imageName),
                    fileManager.fileExists(atPath: fileURL.absoluteString) {
                    let sticker: MSSticker
                    do {
                        try sticker = MSSticker(contentsOfFileURL: fileURL, localizedDescription: cachedSticker[1])
                        stickers.append(sticker)
                    } catch { }
                }
            }
        }
        
        NotificationCenter.default.post(name: .stickersReloaded, object: nil)
        self.stickerBrowserView.reloadData()
    }
    
    /// Fetch all stickers from the web
    func getStickersFromServer() {
        let queue = DispatchQueue(label: "downloadStickers")
        queue.async {
            let request = URLRequest(url: URL(string: self.stickerListURL)!)
            let defaultSession = URLSession(configuration: .default, delegate: nil, delegateQueue: .current)
            // Get JSON
            let dataTask = defaultSession.dataTask(with: request) { (data, resp, error) in
                do {
                    if error == nil,
                       let d = data {
                        if let JSON = try JSONSerialization.jsonObject(with: d, options: []) as? [[String]],
                           !JSON.isEmpty {
                            UserDefaults.standard.set(JSON, forKey: "stickerList")
                            self.stickers.removeAll()
                            
                            for sticker in JSON where sticker.count > 1 {
                                self.fetchSticker(at: URL(string: sticker[0])!, description: sticker[1])
                            }
                            
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .stickersReloaded, object: nil)
                                self.stickerBrowserView.reloadData()
                            }
                        }
                    }
                } catch {}
            }
            dataTask.resume()
        }
    }
    
    /// Get sticker image and data
    func fetchSticker(at url: URL, description: String) {
        if let imageData = NSData(contentsOf: url),
           let imageName = url.pathComponents.last,
           let path = save(imageNamed: imageName, data: imageData) {
            
            let sticker: MSSticker
            do {
                try sticker = MSSticker(contentsOfFileURL: path, localizedDescription: description)
                stickers.append(sticker)
            } catch {}
        }
    }
    
    /// Save sticker on disk
    func save(imageNamed imageName: String, data: NSData) -> URL? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = tmpSubFolderURL?.appendingPathComponent(imageName)
            try data.write(to: fileURL!, options: [.atomicWrite])
            return fileURL!
        } catch { }
        
        return nil
    }
}
