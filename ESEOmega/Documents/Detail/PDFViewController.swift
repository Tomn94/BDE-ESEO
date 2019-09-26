//
//  PDFViewController.swift
//  BDE-ESEO
//
//  Created by Romain Rabouan on 15/09/2019.
//  Copyright © 2019 Romain Rabouan

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
import PDFKit

@available(iOS 11.0, *)
class PDFViewController: UIViewController, UIWebViewDelegate {
    
    let webView = UIWebView(frame: UIScreen.main.bounds)
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var pdfWebView: UIWebView!
    
    
    @IBOutlet weak var pdfView: PDFView!
    var urlString = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        pdfWebView.delegate = self
        
        
        pdfWebView.scalesPageToFit = true
        pdfWebView.loadRequest(URLRequest(url: URL(string: urlString)!))
        
        activityIndicatorView.hidesWhenStopped = true
        
        
        
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        activityIndicatorView.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicatorView.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        activityIndicatorView.stopAnimating()
        let alertController = UIAlertController(title: "Erreur", message: "Impossible de charger le document. Vérifie ta connexion ou contacte ton BDE : \(error.localizedDescription)", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    

    

}
