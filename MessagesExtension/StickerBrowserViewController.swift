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
    
    private let folder = "cachedStickers"
    
    var stickers = [RawSticker]()
    
    private var stickersLoaded = 0
    private var stickersToBeLoaded = 0
    
    private let stickerFetchQueue = DispatchQueue(label: "fetchStickerQueue",
                                                  qos: .userInitiated,
                                                  attributes: .concurrent)
    
    
    /// Fetch cached stickers
    func getStickersFromCache() {
        
        let fileManager = FileManager.default
        do {
            let cacheURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true).appendingPathComponent(folder,
                                                                                       isDirectory: true)
            // Create cache folder anyway
            try fileManager.createDirectory(at: cacheURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            
            guard let cache = UserDefaults.standard.object(forKey: UserDefaultsKey.stickers) as? Data,
                  let cachedStickers = try? JSONDecoder().decode(StickersResult.self, from: cache)
                else { return }
                
            for cachedSticker in cachedStickers.stickers {
                
                if let imageName = cachedSticker.img.pathComponents.last {
                    let fileURL = cacheURL.appendingPathComponent(imageName)
                    
                    if fileManager.fileExists(atPath: fileURL.path),
                       let sticker = try? RawSticker(contentsOfFileURL: fileURL,
                                                     localizedDescription: cachedSticker.name,
                                                     id: cachedSticker.id),
                       !self.stickers.contains(where: { rawSticker in
                           rawSticker.id == sticker.id
                       }) {
                        stickers.append(sticker)
                    }
                }
            }
        } catch {}
        
        NotificationCenter.default.post(name: .stickersReloaded, object: nil)
        self.stickerBrowserView.reloadData()
    }
    
    /// Fetch all stickers from the web
    func getStickersFromServer() {
        
        API.request(.stickers, completed: { data in
            
            guard let result = try? JSONDecoder().decode(StickersResult.self,
                                                         from: data),
                  result.success
                else { return }
                
            UserDefaults.standard.set(data, forKey: UserDefaultsKey.stickers)
            self.stickers.removeAll()
            self.stickersToBeLoaded = result.stickers.count
            self.stickersLoaded = 0
    
            for sticker in result.stickers {
                self.fetch(sticker: sticker)
            }
    
            self.cleanFolder()
            
        }, noCache: true)
    }
    
    /// Get sticker image and data
    func fetch(sticker remoteSticker: Sticker) {
        
        stickerFetchQueue.async {  // Data(contentsOf: url) is blocking
            guard let imageData = try? Data(contentsOf: remoteSticker.img),
                  let imageName = remoteSticker.img.pathComponents.last,
                  let path      = self.save(imageNamed: imageName, data: imageData),
                  let sticker   = try? RawSticker(contentsOfFileURL: path,
                                                  localizedDescription: remoteSticker.name,
                                                  id: remoteSticker.id),
                  !self.stickers.contains(where: { rawSticker in
                      rawSticker.id == remoteSticker.id
                  })
                else { return }
            
            self.stickers.append(sticker)
            self.stickers.sort { $0.id < $1.id }
            self.stickersLoaded += 1
            
            if self.stickersLoaded == self.stickersToBeLoaded {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .stickersReloaded, object: nil)
                    self.stickerBrowserView.reloadData()
                }
            }
        }
    }
    
    /// Save sticker on disk
    func save(imageNamed imageName: String, data: Data) -> URL? {
        
        let fileManager = FileManager.default
        guard let cacheURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true).appendingPathComponent(folder,
                                                                                       isDirectory: true)
            else { return nil }
        
        do {
            // Get sub-folder, create if doesn't exist
            try fileManager.createDirectory(at: cacheURL,
                                            withIntermediateDirectories: true)
            
            let fileURL = cacheURL.appendingPathComponent(imageName)
            if fileManager.fileExists(atPath: fileURL.absoluteString) {
                // If sticker already exists, we'll replace the file
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch {
                    return fileURL  // Old file kept
                }
            }
            
            // Finally save sticker
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
    
    func debugCache() {
        
        let keyName = "debuggedStickersV511"
        guard !UserDefaults.standard.bool(forKey: keyName)
            else { return }
        
        let fileManager = FileManager.default
        guard let cacheURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask,
                                                  appropriateFor: nil, create: true)
            else { return }
        
        let folderURL = cacheURL.appendingPathComponent(folder, isDirectory: true)
        do {
            try fileManager.removeItem(at: folderURL)
            UserDefaults.standard.set(true, forKey: keyName)
        } catch {}
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
