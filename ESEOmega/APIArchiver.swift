//
//  API.swift
//  ESEOmega
//
//  Created by Tomn on 09/09/2017.
//  Copyright © 2017 Tomn. All rights reserved.
//

import UIKit

/// Usually applied to View Controllers handling fetched & cached API data
protocol APIViewer {
    
    associatedtype T
    
    
    func loadFromCache()
    
    func fetchRemote()
    
    func loadData(_ data: T)
    
}

/// Cache
class APIArchiver {
    
    private static let cache = EGOCache.global()
    
    
    static func save<T: Encodable>(data: T,
                     for apiPath: API.Path) {
        
        guard let encodedData = try? JSONEncoder().encode(data)
            else { return }
        
        cache.setData(encodedData,
                      forKey: apiPath.rawValue,
                      withTimeoutInterval: 31536000)  // 1 year
    }
    
    static func hasCache(for apiPath: API.Path) -> Bool {
        
        return cache.hasCache(forKey: apiPath.rawValue)
    }
    
    static func getCache(for apiPath: API.Path) -> Foundation.Data? {
        
        return cache.data(forKey: apiPath.rawValue)
    }
    
    static func clearCache() {
        
        cache.clear()
    }
    
}

