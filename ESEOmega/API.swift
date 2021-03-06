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
    
    /// Common URL for all API requests.
    /// TODO: Set a debug environment to automatically switch between beta & production.
    static private let url     = "https://api.bdeeseo.fr/"
    static private let version = "1"
    static private let key = "Adrl87VaVmMIPWJgiklbet2muRHTfQ"
    
    
    /// Available API endpoints
    enum Path: String {
        
        /// Connect user
        case userLogin    = "me/login"
        
        /// Get news articles
        case news         = "news"
        
        /// Get clubs list
        case clubs        = "clubs"
        /// Same as `clubs` but to be used with `APIArchiver` instead of `clubs`.
        /// Why? Because I only found this solution to fix a weirdass problem
        case clubsCache   = "clubsCache"
        
        /// Get cafet order history
        case orders       = "me/orders"
        
        /// Information about a specific cafet order. `idcmd` number must be suffixed. Also used to send order
        case order        = "cafeteria/orders"
        
        /// Begin new cafet order
        case newOrder     = "cafeteria/orders/token"
        
        /// Get available items to order
        case menus        = "cafeteria"
        
        /// Get current cafet service message
        case orderService = "cafeteria/settings/service_message"
        
        
        /// Begin Lydia payment for order
        case lydiaAsk     = "lydia/ask"
        
        /// Check Lydia payment status of a specific order
        case lydiaCheck   = "lydia/check"
        
        /// List of IngeNews editions
        case ingenews     = "ingenews"
        
        /// List of rooms
        case rooms        = "rooms"
        
        /// Information about a family. Family number must be suffixed.
        case family       = "families/"
        
        /// Search a student name for their family
        case familySearch = "families"
        
        /// MessagesExtension, list of stickers
        case stickers     = "stickers"
        
        /// Register push token
        case pushRegister = "me/devices"
        
        /// Download sponsors list
        case sponsors = "sponsors"
        
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
    ///   - appendPath: Eventual additional and dynamic Path component.
    ///                 Should not start with / if `apiPath` is already suffixed.
    ///   - getParameters:  List of GET  parameters that will get encoded and packed
    ///   - postParameters: List of POST parameters that will get encoded and packed
    ///   - authToken: Whether user's token is sent with the request.
    ///   - completed: Called when request got data and no error
    ///   - failure: Called when request failed, no data or error
    ///   - noCache: Ignore local cache when making the request
    static func request(_ apiPath: API.Path,
                        appendPath: String? = nil,
                        get  getParameters:  [String : String] = [:],
                        post postParameters: [String : String] = [:],
                        postData: Foundation.Data? = nil,
                        authentication authToken: String? = nil,
                        completed: @escaping (Foundation.Data) -> (),
                        failure: ((Error?, Foundation.Data?) -> ())? = nil,
                        noCache: Bool = false) {
        
        let cachePolicy: NSURLRequest.CachePolicy = noCache ? .reloadIgnoringLocalCacheData
                                                            : .useProtocolCachePolicy
        
        /* URL + GET */
        var rawURL = url + apiPath.rawValue
        if let suffixPath = appendPath {
            rawURL += suffixPath
        }
        NSLog(rawURL);
        guard var urlComponents = URLComponents(string: rawURL) else {
            failure?(nil, nil)
            return
        }
        urlComponents.queryItems = getParameters.map {  // GET
            URLQueryItem(name: $0.key, value: $0.value)
        }
        guard let finalURL = urlComponents.url ?? URL(string: rawURL) else {
            failure?(nil, nil)
            return
        }
        
        var request = URLRequest(url: finalURL,
                                 cachePolicy: cachePolicy,
                                 timeoutInterval: 60)
        request.setValue(key,     forHTTPHeaderField: "API-key")
        request.setValue(version, forHTTPHeaderField: "API-version")
        if let token = authToken {
            request.setValue(token, forHTTPHeaderField: "API-token")
        }
        
        /* POST */
        if !postParameters.isEmpty {
            request.httpMethod       = "POST"
            urlComponents.queryItems = postParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            let postString           = urlComponents.query ?? ""
            request.httpBody         = postString.data(using: .utf8)
        }
        
        if let data = postData {
            request.httpMethod = "POST"
            request.httpBody = data
        }
        
        /* Configure completion */
        let defaultSession = URLSession(configuration: .default,
                                        delegate: nil,
                                        delegateQueue: nil)  // create new queue
        let dataTask = defaultSession.dataTask(with: request) { data, _, error in
            
            #if os(iOS)
            Utils.requiresActivityIndicator(false)
            #endif
            
            guard let d = data, error == nil else {
                failure?(error, data)
                return
            }
            
            completed(d)
        }
        
        /* Fire! */
        #if os(iOS)
        Utils.requiresActivityIndicator(true)
        #endif
        dataTask.resume()
    }
    
    
    enum HandleFailureMode {
        /// Only get error info (default)
        case onlyFetchMessage
        #if os(iOS)
        /// Present alert from decoded error info
        case presentFetchedMessage(UIViewController)
        #endif
    }
    
    /// Tries to analyse bad API response data to at least get an error message.
    @discardableResult static func handleFailure(data: Foundation.Data?,
                                                 mode: HandleFailureMode = .onlyFetchMessage,
                                                 defaultMessage: String? = nil) -> APIError {
        
        var result = APIError(message: defaultMessage ?? "Appelez Champollion, impossible de déchiffrer la réponse du serveur.",
                          code: nil)
        
        if let d = data,
           let baseError = try? JSONDecoder().decode(API.ErrorResult.self, from: d),
           let error = baseError.error,
           let cause = error.userMessage {
            result = APIError(message: cause, code: error.uid)
        }
        
        #if os(iOS)
        if case let .presentFetchedMessage(parentVC) = mode {
            
            let alert = UIAlertController(title: "Erreur",
                                          message: result.message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            DispatchQueue.main.async {
                parentVC.present(alert, animated: true)
            }
        }
        #endif
        
        return result
    }

}
