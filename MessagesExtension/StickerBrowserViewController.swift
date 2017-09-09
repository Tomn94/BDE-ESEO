//
//  StickerBrowserViewController.swift
//  ESEOmega
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

class StickerBrowserViewController: MSStickerBrowserViewController {
    
    private let folder = "stickers"
    
    var stickers = [MSSticker]()
    
    
    /// Fetch cached stickers
    func getStickersFromCache() {
        
        guard let cache = UserDefaults.standard.object(forKey: UserDefaultsKey.stickers) as? Data,
              let cachedStickers = try? JSONDecoder().decode([Sticker].self, from: cache)
            else { return }
        
        let fileManager = FileManager.default
        do {
            let cacheURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true).appendingPathComponent(folder,
                                                                                       isDirectory: true)
            try fileManager.createDirectory(at: cacheURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
                
            for cachedSticker in cachedStickers {
                
                if let imageName = cachedSticker.img.pathComponents.last {
                    let fileURL = cacheURL.appendingPathComponent(imageName)
                    
                    if fileManager.fileExists(atPath: fileURL.path),
                       let sticker = try? MSSticker(contentsOfFileURL: fileURL,
                                                    localizedDescription: cachedSticker.name) {
                        
                        stickers.append(sticker)
                    }
                }
            }
        } catch {}
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .stickersReloaded, object: nil)
            self.stickerBrowserView.reloadData()
        }
    }
    
    /// Fetch all stickers from the web
    func getStickersFromServer() {
        
        API.request(.stickers, completed: { data in
            
            guard let stickers = try? JSONDecoder().decode([Sticker].self, from: data),
                  !stickers.isEmpty
                else { return }
                
            UserDefaults.standard.set(data, forKey: UserDefaultsKey.stickers)
            self.stickers.removeAll()
    
            for sticker in stickers {
                self.fetchSticker(at: sticker.img, description: sticker.name)  // sync
            }
    
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .stickersReloaded, object: nil)
                self.stickerBrowserView.reloadData()
                self.cleanFolder()
            }
            
        }, noCache: true)
    }
    
    /// Get sticker image and data
    func fetchSticker(at url: URL, description: String) {
        
        guard let imageData = try? Data(contentsOf: url),  // sync
              let imageName = url.pathComponents.last,
              let path      = save(imageNamed: imageName, data: imageData),
              let sticker   = try? MSSticker(contentsOfFileURL: path,
                                             localizedDescription: description)
            else { return }
        
        stickers.append(sticker)
    }
    
    /// Save sticker on disk
    func save(imageNamed imageName: String, data: Data) -> URL? {
        
        guard let cacheURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,
                                                          appropriateFor: nil, create: true)
            else { return nil }
        
        let fileURL = cacheURL.appendingPathComponent(folder,
                                                      isDirectory: true).appendingPathComponent(imageName)
        
        do {
            try data.write(to: fileURL, options: [.atomicWrite])
            return fileURL
        } catch {
            return nil
        }
    }
    
    /// Clear images not used anymore (cached but not in cache list anymore)
    func cleanFolder() {
        
        let fileManager = FileManager.default
        guard let cacheURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask,
                                                          appropriateFor: nil, create: true)
            else { return }
        
        let cachePath = cacheURL.appendingPathComponent(folder, isDirectory: true).path
        guard let files = try? fileManager.contentsOfDirectory(atPath: cachePath)
            else { return }
        
        var cachedFileNames = [String]()
        if let cache = UserDefaults.standard.object(forKey: UserDefaultsKey.stickers) as? Data,
            let cachedStickers = try? JSONDecoder().decode([Sticker].self, from: cache) {
            
            cachedFileNames = cachedStickers.flatMap { sticker in
                sticker.img.pathComponents.last
            }
        }
        
        let filesSet       = Set(files)
        let cachedSet      = Set(cachedFileNames)
        let remainingFiles = filesSet.subtracting(cachedSet)
        
        for file in remainingFiles {
            try? fileManager.removeItem(atPath: cacheURL.appendingPathComponent(file).path)
        }
    }
    
}


// MARK: Sticker Browser View Data Source
extension StickerBrowserViewController {
    
    override func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        return stickers.count
    }
    
    override func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView,
                                     stickerAt index: Int) -> MSSticker {
        return stickers[index]
    }
    
}
