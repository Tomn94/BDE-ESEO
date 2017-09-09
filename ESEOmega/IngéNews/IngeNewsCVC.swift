//
//  IngeNewsCVC.swift
//  ESEOmega
//
//  Created by Thomas Naudet on 10/07/2017 (Objective-C original on 22/12/2015).
//  Copyright © 2017 Thomas Naudet. All rights reserved.
//

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
import WebKit


fileprivate extension Selector {
    /// Refresh control triggered
    static let refresh = #selector(IngeNewsCVC.refresh)
}


/// Cell displaying an IngéNews document
class IngeNewsCell: UICollectionViewCell {
    
    /// Icon, preview for the document
    @IBOutlet weak var iconView: UIImageView!
    
    /// Title of the document, under the icon
    @IBOutlet weak var titleLabel: UILabel!
    
    /// Subtitle, info about the document
    @IBOutlet weak var subtitleLabel: UILabel!
    
}


/// Collection view of all the available IngéNews documents
class IngeNewsCVC: UICollectionViewController {
    
    /// Unique cell reuse identifier
    private let reuseIdentifier = "ingenewsFilesCell"
    
    
    /// IngéNews files displayed
    var files = [IngeNews]()
    
    /// Refresh control on top of the colelction view
    let refreshControl = UIRefreshControl()
    
    
    /// Whether a Print Warning has already been seen by the user
    var printWarning: PrintWarningStatus {
        get {
            let settings = UserDefaults.standard.integer(forKey: UserDefaultsKey.printWarning)
            return PrintWarningStatus(rawValue: settings) ?? .neverSeen
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKey.printWarning)
        }
    }
    
    /// Describes available status for the Print Warning
    enum PrintWarningStatus: Int {
        /// The user has never seen this alert yet
        case neverSeen
        /// The user has already seen the alert once or more
        case alreadySeen
        /// The user pressed do not remind me
        case dontShow
    }
    
    /// Whether a Print Warning has already been seen by the user
    /// during this app launch session. Avoids presenting it twice.
    var alreadyPresentedWarningInSession = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Load local data and ask for updates */
        loadFromCache()
        fetchRemote()
        
        /* Add refresh control */
        refreshControl.tintColor = UINavigationBar.appearance().barTintColor
        refreshControl.addTarget(self,
                                 action: .refresh,
                                 for: .valueChanged)
        self.collectionView?.addSubview(refreshControl)
        NotificationCenter.default.addObserver(refreshControl,
                                               selector: #selector(UIRefreshControl.endRefreshing),
                                               name: .debugRefresh,
                                               object: nil)
        
        /* Customized < Back button title */
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Liste",
                                                                style: .plain,
                                                                target: nil,
                                                                action: nil)
        
        /* Allow 3D Touch on cells */
        if let collection = self.collectionView,
           self.traitCollection.forceTouchCapability == .available {
            self.registerForPreviewing(with: self,
                                       sourceView: collection)
        }
        
        /* Allow faster content prefetching */
        if #available(iOS 10.0, *) {
            self.collectionView?.prefetchDataSource = self
        }
    }
    
    
    // MARK: - Actions
    
    /// Refresh control triggered
    @objc func refresh() {
        
        fetchRemote()
    }
    
}


// MARK: - API Viewer
extension IngeNewsCVC: APIViewer {
    
    typealias T = [IngeNews]
    
    
    func loadFromCache() {
        
        guard let data   = APIArchiver.getCache(for: .ingenews),
              let result = try? JSONDecoder().decode(IngeNewsResult.self, from: data)
            else { return }
        
        self.loadData(result.files)
    }
    
    func fetchRemote() {
        
        API.request(.ingenews, completed: { data in
            
            self.refreshControl.endRefreshing()
            
            guard let result = try? JSONDecoder().decode(IngeNewsResult.self, from: data),
                  result.success
                else { return }
            
            self.loadData(result.files)
            APIArchiver.save(data: result.files, for: .ingenews)
            
        }, failure: { (_, _) in
            self.refreshControl.endRefreshing()
        })
    }
    
    func loadData(_ data: [IngeNews]) {
        
        /* Update model */
        files = data
        
        self.collectionView?.backgroundColor = files.isEmpty ? .groupTableViewBackground : .white
        self.collectionView?.reloadData()
    }
    
}


// MARK: - Collection View Data Source
extension IngeNewsCVC {
    
    /// Defines how many IngéNews editions are presented
    ///
    /// - Parameters:
    ///   - collectionView: This collection view
    ///   - section: The one and only section
    /// - Returns: The number of files to display
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        
        return files.count
    }

    /// Defines how IngéNews editions are presented
    ///
    /// - Parameters:
    ///   - collectionView: This collection view
    ///   - indexPath: Position of the cell to populate
    /// - Returns: A cell configured for its IngéNews edition
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        /* Get data */
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! IngeNewsCell
        let file = files[indexPath.item]
        
        /* Set up title */
        cell.titleLabel.text = file.name
        
        /* Set up subtitle */
        let fileDate = DateFormatter.localizedString(from:      file.date,
                                                     dateStyle: .medium,
                                                     timeStyle: .short)
        let fileSize = ByteCountFormatter.string(fromByteCount: file.size,
                                                 countStyle:    .file)
        cell.subtitleLabel.text = fileDate + " · " + fileSize
        cell.subtitleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: cell.subtitleLabel.font.pointSize,
                                                                   weight: .medium)
        
        /* Set up icon */
        if let fileImage = file.img {
            cell.iconView.sd_setImage(with: fileImage,
                                      placeholderImage: #imageLiteral(resourceName: "doc"))
        } else {
            cell.iconView.image = #imageLiteral(resourceName: "doc")
        }
        
        /* Set up view */
        cell.contentView.layer.cornerRadius = 6
        cell.contentView.clipsToBounds = true
    
        return cell
    }
    
}


// MARK: - Collection View Data Source Prefetching
extension IngeNewsCVC: UICollectionViewDataSourcePrefetching {
    
    /// Prepare data (file thumbnail) at specified index paths
    ///
    /// - Parameters:
    ///   - collectionView: This collection view
    ///   - indexPaths: Position of the cells to preload
    @available(iOS 10.0, *)
    func collectionView(_ collectionView: UICollectionView,
                        prefetchItemsAt indexPaths: [IndexPath]) {
        
        /* Get every image URL to fetch */
        var thumbnails = [URL]()
        for indexPath in indexPaths {
            if let thumbnailURL = files[indexPath.item].img {
                thumbnails.append(thumbnailURL)
            }
        }
        
        SDWebImagePrefetcher.shared().prefetchURLs(thumbnails)
    }
    
}


// MARK: - Collection View Delegate
extension IngeNewsCVC {
    
    /// Called when an IngéNews edition got selected
    ///
    /// - Parameters:
    ///   - collectionView: This collection view
    ///   - indexPath: Position of the selected cell
    override func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        let selectedFile = files[indexPath.item]
        let fileURL      = selectedFile.file
        
        /* Present file as web content (browser can open PDFs, docs…) */
        let safari = SFSafariViewController(url: fileURL)
        if #available(iOS 10.0, *) {
            safari.preferredBarTintColor = UINavigationBar.appearance().barTintColor
            safari.preferredControlTintColor = UINavigationBar.appearance().tintColor
        }
        
        self.present(safari, animated: true, completion: {
            
            /* There's no Print icon in Safari View Controller Share Sheet,
               so let's present a dialog (once during app launch) */
            if self.printWarning != .dontShow &&
               !self.alreadyPresentedWarningInSession {
                
                /* Mark as already seen once, and present alert */
                self.printWarning = .alreadySeen
                self.alreadyPresentedWarningInSession = true
                
                let alert = UIAlertController(title: "Vous désirez partager le document, l'imprimer ou effectuer une recherche ?",
                                              message: "Pour rechercher dans le document ou le transférer vers n'importe quelle app, tapez sur l'icône de partage en bas.\n\nPour l'imprimer, tapez d'abord sur l'icône Ouvrir dans Safari en bas à droite, puis sur l'icône de partage.\n\nBonne lecture !",
                                              preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Merci", style: .cancel))
                
                if self.printWarning != .neverSeen {
                    /* Allow to stop presenting this warning if the user has already seen one */
                    alert.addAction(UIAlertAction(title: "Ne plus me le rappeler",
                                                  style: .destructive,
                                                  handler: { _ in
                                                    self.printWarning = .dontShow
                    }))
                }
                
                safari.present(alert, animated: true)
            }
            
        })
        
        self.collectionView?.deselectItem(at: indexPath, animated: true)
    }
    
    /// Specifies if the given item should be highlighted during tracking
    ///
    /// - Parameters:
    ///   - collectionView: This collection view
    ///   - indexPath: Position of the item to configure
    override func collectionView(_ collectionView: UICollectionView,
                        didHighlightItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = UIColor(white: 0.9, alpha: 1)
    }
    
    /// Specifies how the given item should be unhighlighted after tracking
    ///
    /// - Parameters:
    ///   - collectionView: This collection view
    ///   - indexPath: Position of the item to configure
    override func collectionView(_ collectionView: UICollectionView,
                                 didUnhighlightItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = .white
    }
    
}


// MARK: - Collection View Delegate Flow Layout
extension IngeNewsCVC: UICollectionViewDelegateFlowLayout {
    
    /// Customizes the size of a given cell for an IngéNews edition
    ///
    /// - Parameters:
    ///   - collectionView: This collection view
    ///   - collectionViewLayout: Layout object requesting the size
    ///   - indexPath: Position of the item to configure
    /// - Returns: Size of the cell
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            
            let width = collectionView.frame.size.width
            
            if width > 410 {            // iPhone Plus
                return CGSize(width: 192, height: 192)
            } else if width > 370 {     // iPhone
                return CGSize(width: 172, height: 172)
            }
        }
        
        return CGSize(width: 140, height: 140)
    }
    
}


// MARK: - View Controller Previewing Delegate
extension IngeNewsCVC: UIViewControllerPreviewingDelegate {
    
    /// Called when a 3D-Touch Peek gesture begins
    ///
    /// - Parameters:
    ///   - previewingContext: Context obejct for the previewing view controller
    ///   - location: Position of the touch in the source view's coordinate system
    /// - Returns: The view controller to preview
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        /* Get which IngéNews edition has been hard-pressed */
        guard let index = self.collectionView?.indexPathForItem(at: location) else {
            return nil
        }
        let fileURL = files[index.item].file
        
        /* Get its frame */
        if let originatingFrame = self.collectionView?.layoutAttributesForItem(at: index)?.frame {
            previewingContext.sourceRect = originatingFrame
        }
        
        /* Peek at it */
        let safari = SFSafariViewController(url: fileURL)
        if #available(iOS 10.0, *) {
            safari.preferredBarTintColor = UINavigationBar.appearance().barTintColor
            safari.preferredControlTintColor = UINavigationBar.appearance().tintColor
        }
        
        return safari
    }
    
    /// Called when a 3D-Touch Pop gesture begins
    ///
    /// - Parameters:
    ///   - previewingContext: Context obejct for the previewing view controller
    ///   - viewControllerToCommit: View controller to display full-screen
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
        present(viewControllerToCommit, animated: true)
    }
    
}


// MARK: - Empty Data Set Source
extension IngeNewsCVC: DZNEmptyDataSetSource {
    
    /// Configures the icon presented when there're no files
    ///
    /// - Parameter scrollView: This collection view
    /// - Returns: Empty data icon
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return #imageLiteral(resourceName: "autreVide")
    }
    
    /// Configures the title presented when there're no files
    ///
    /// - Parameter scrollView: This collection view
    /// - Returns: Attributed empty data text
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let text = "Aucun fichier"
        return NSAttributedString(string: text,
                                  attributes: [.foregroundColor : UIColor.darkGray])
    }
    
    /// Configures the subtitle presented when there're no files
    ///
    /// - Parameter scrollView: This collection view
    /// - Returns: Attributed empty data text
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let text = "Vérifiez votre connexion et tirez pour rafraîchir."
        return NSAttributedString(string: text,
                           attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline),
                                        .foregroundColor : UIColor.lightGray])
    }
    
    /// Changes the offset for the empty data view
    ///
    /// - Parameter scrollView: This collection view
    /// - Returns: Empty data view offset
    func offset(forEmptyDataSet scrollView: UIScrollView!) -> CGPoint {
        
        return CGPoint(x: 0, y: -80)
    }
    
    /// Returns which background color will be displayed if there're no files
    ///
    /// - Parameter scrollView: This collection view
    /// - Returns: Background color for the empty collection view
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        
        return .groupTableViewBackground
    }
    
}
