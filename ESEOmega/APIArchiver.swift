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
    
    func reloadData()
    
}

/// Cache
class APIArchiver {
    
    private static let cache = EGOCache.global()
    
    
    static func save<T: Encodable>(data: T,
                     for apiPath: API.Path) {
        
        let encoder = JSONEncoder()
        
        switch apiPath {
        case .news:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = NewsArticle.dateFormat
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
        case .orders:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = CafetOrder.dateFormat
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
        default:
            break
        }
        
        guard let encodedData = try? encoder.encode(data)
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
    
    static func removeCache(for apiPath: API.Path) {
        
        cache.remove(forKey: apiPath.rawValue)
    }
    
    static func clearCache() {
        
        cache.clear()
    }
    
}

