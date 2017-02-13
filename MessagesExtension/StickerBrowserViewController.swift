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
    
    let stickerListURL = "https://web59.secure-secure.co.uk/francoisle.fr/api/stickers"
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
            do {
                let cacheURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask,
                                                   appropriateFor: nil, create: true).appendingPathComponent("stickers", isDirectory: true)
                
                try fileManager.createDirectory(at: cacheURL,
                                                withIntermediateDirectories: true, attributes: nil)
                
                for cachedSticker in cache where cachedSticker.count > 1 {
                    if let imageURL = URL(string: cachedSticker[0]),
                       let imageName = imageURL.pathComponents.last {
                        
                        let fileURL = cacheURL.appendingPathComponent(imageName)
                        if fileManager.fileExists(atPath: fileURL.path) {
                            let sticker: MSSticker
                            try sticker = MSSticker(contentsOfFileURL: fileURL, localizedDescription: cachedSticker[1])
                            stickers.append(sticker)
                        }
                    }
                }
            } catch {}
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .stickersReloaded, object: nil)
            self.stickerBrowserView.reloadData()
        }
    }
    
    /// Fetch all stickers from the web
    func getStickersFromServer() {
        let queue = DispatchQueue(label: "downloadStickers")
        queue.async {
            let request = URLRequest(url: URL(string: self.stickerListURL)!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60)
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
                                self.cleanFolder()
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
        do {
            let cacheURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL = cacheURL.appendingPathComponent("stickers", isDirectory: true).appendingPathComponent(imageName)
            
            try data.write(to: fileURL, options: [.atomicWrite])
            
            return fileURL
        } catch {}
        
        return nil
    }
    
    /// Clear images not used anymore
    func cleanFolder() {
        guard let cache = UserDefaults.standard.object(forKey: "stickerList") as? [[String]] else { return }
        
        let fileManager = FileManager.default
        do {
            let cacheURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let files = try fileManager.contentsOfDirectory(atPath: cacheURL.appendingPathComponent("stickers", isDirectory: true).path)
            
            let cachedFileNames = cache.flatMap({ URL(string: $0[0])?.pathComponents.last })
            let filesSet = Set(files)
            let cachedSet = Set(cachedFileNames)
            
            let remainingFiles = filesSet.subtracting(cachedSet)
            
            for file in remainingFiles {
                try fileManager.removeItem(atPath: cacheURL.appendingPathComponent(file).path)
            }
        } catch {}
    }
}
