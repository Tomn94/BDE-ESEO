//
//  NotificationService.swift
//  NotificationService
//
//  Created by Tomn on 24/09/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification
            
            if let attachmentID = request.content.userInfo["attchmt"] as? String,
               attachmentID != "" {
                
                var attachment: UNNotificationAttachment?
                
                // CHECK IMAGE TYPE
                if attachmentID == "cafetDone"    || attachmentID == "cafetReady" ||
                   attachmentID == "cafetNotPaid" || attachmentID == "cafetPreparing" ||
                   attachmentID == "spaceship",
                   let path = Bundle.main.resourcePath {
                    // Common Images
                    let attachmentURL = URL(fileURLWithPath: path + "/" + attachmentID + ".png")
                    attachment = try! UNNotificationAttachment(identifier: "image",
                                                               url: attachmentURL,
                                                               options: nil)
                } else if let url = URL(string: attachmentID),
                   let imageData = NSData(contentsOf: url) {
                    // Other URL, download file
                    attachment = UNNotificationAttachment.create(imageFileIdentifier: "image",
                                                                 data: imageData,
                                                                 options: nil)
                }
                
                // ADD IMAGE TO NOTIFICATION
                if attachment != nil {
                    bestAttemptContent.attachments = [attachment!]
                }
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

extension UNNotificationAttachment {
    
    /// Save the image to disk
    static func create(imageFileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = tmpSubFolderURL?.appendingPathComponent(imageFileIdentifier)
            try data.write(to: fileURL!, options: [])
            let imageAttachment = try UNNotificationAttachment(identifier: imageFileIdentifier, url: fileURL!, options: options)
            return imageAttachment
        } catch {}
        
        return nil
    }
}
