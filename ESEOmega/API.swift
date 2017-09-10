//
//  API.swift
//  ESEOmega
//
//  Created by Tomn on 09/09/2017.
//  Copyright © 2017 Thomas NAUDET

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

/// Describes *any* JSON message from API
protocol APIResult: Decodable {
    
    /// Whether API request was valid
    var success: Bool { get }
    
}

/// Tools to contact the server
class API {
    
    /// Common URL for all API requests
    static private let url     = "https://api.bdeeseo.fr/"
    static private let version = "1"
    
    
    /// Available API endpoints
    enum Path: String {
        
        /// Connect user
        case userLogin    = "me/login"
        
        /// Get news articles
        case news         = "news"
        
        /// List of IngeNews editions
        case ingenews     = "ingenews"
        
        /// List of rooms
        case rooms        = "rooms"
        
        /// Information about a family
        case family       = "family"
        
        /// Search a student name for their family
        case familySearch = "family/search"
        
        /// MessagesExtension, list of stickers
        case stickers     = "stickers"
        
    }
    
    
    /// Describes a JSON error message from API
    struct ErrorResult: APIResult, Decodable {
        
        /// Whether API request was valid
        let success: Bool
        
        /// Failure info if request was not valid
        let error: Error?
        
        /// Inner error info
        struct Error: Decodable {
            
            /// Type of error
            let uid: Int?
            
            /// Detailed message
            let devMessage: String?
            
            /// Message to be displayed
            let userMessage: String?
            
        }
        
    }
    
    typealias APIError = (message: String, code: Int?)
    
    
    /// Contacts the API
    ///
    /// - Parameters:
    ///   - apiPath: Requested component
    ///   - getParameters:  List of GET  parameters that will get encoded and packed
    ///   - postParameters: List of POST parameters that will get encoded and packed
    ///   - completed: Called when request got data and no error
    ///   - failure: Called when request failed, no data or error
    ///   - noCache: Ignore local cache when making the request
    static func request(_ apiPath: API.Path,
                        get  getParameters:  [String : String] = [:],
                        post postParameters: [String : String] = [:],
                        completed: @escaping (Foundation.Data) -> (),
                        failure: ((Error?, Foundation.Data?) -> ())? = nil,
                        noCache: Bool = false) {
        
        let cachePolicy: NSURLRequest.CachePolicy = noCache ? .reloadIgnoringLocalCacheData
                                                            : .useProtocolCachePolicy
        
        /* URL + GET */
        var urlComponents = URLComponents(string: url + apiPath.rawValue)!
        urlComponents.queryItems = getParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url ?? URL(string: url + apiPath.rawValue)!,
                                 cachePolicy: cachePolicy,
                                 timeoutInterval: 60)
        request.setValue(key,     forHTTPHeaderField: "API-key")
        request.setValue(version, forHTTPHeaderField: "API-version")
        
        /* POST */
        if !postParameters.isEmpty {
            request.httpMethod       = "POST"
            urlComponents.queryItems = postParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            let postString           = urlComponents.query ?? ""
            request.httpBody         = postString.data(using: .utf8)
        }
        
        /* Configure completion */
        let defaultSession = URLSession(configuration: .default,
                                        delegate: nil,
                                        delegateQueue: nil)  // create new queue
        let dataTask = defaultSession.dataTask(with: request) { data, _, error in
            
            Utils.requiresActivityIndicator(false)
            
            guard let d = data, error == nil else {
                failure?(error, data)
                return
            }
            
            completed(d)
        }
        
        /* Fire! */
        Utils.requiresActivityIndicator(true)
        dataTask.resume()
    }
    
    
    enum HandleFailureMode {
        /// Only get error info (default)
        case onlyFetchMessage
        /// Present alert from decoded error info
        case presentFetchedMessage(UIViewController)
    }
    
    /// Tries to analyse bad API response data to at least get an error message.
    static func handleFailure(data: Foundation.Data,
                              mode: HandleFailureMode = .onlyFetchMessage) -> APIError {
        
        var result = APIError(message: "Appelez Champollion, impossible de déchiffrer la réponse du serveur.",
                          code: nil)
        
        if let baseError = try? JSONDecoder().decode(API.ErrorResult.self, from: data),
           let error = baseError.error,
           let cause = error.userMessage {
            result = APIError(message: cause, code: error.uid)
        }
        
        if case let .presentFetchedMessage(parentVC) = mode {
            
            let alert = UIAlertController(title: "Erreur réseau inconnue",
                                          message: result.message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            parentVC.present(alert, animated: true)
        }
        
        return result
    }

}
