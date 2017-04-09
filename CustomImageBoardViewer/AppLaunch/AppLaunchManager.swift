//
//  AppLaunchManager.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 12/3/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import Foundation

import SwiftMessages

class AppLaunchManager: NSObject {
    static var shared = AppLaunchManager()
    static let eventCompleted = "AppLaunchManagerEventCompleted"
    
    fileprivate var isRemoteSettingsUpdated = false {
        didSet {
            if isRemoteSettingsUpdated && !czzSettingsCentre.sharedInstance().popup_notification_link.isEmpty,
                let notificationURL = URL(string: czzSettingsCentre.sharedInstance().popup_notification_link) {
                NSURLConnection.sendAsynchronousRequest(URLRequest(url: notificationURL), queue: .main, completionHandler: { (response, data, error) in
                    if (response as? HTTPURLResponse)?.statusCode == 200,
                        let data = data,
                        let jsonString = String(data: data, encoding: .utf8),
                        let popupNotification = czzLaunchPopUpNotification(json: jsonString)
                    {
                        popupNotification.tryShow()
                    }
                })
            }
        }
    }
    
    override init() {
        super.init()
        // Refresh watched threads immediately.
        czzWatchListManager.shared().lastActiveRefreshTime = Date()
        czzWatchListManager.shared().refreshWatchedThreads { [weak self] updatedThreads in
            guard let strongSelf = self else { return }
            // If the newly refreshed watched threads are not empty.
            if !(updatedThreads ?? []).isEmpty {
                
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.remoteSettingUpdated, object: nil, queue: OperationQueue.main, using: { [weak self] _ in
            self?.isRemoteSettingsUpdated = true
        })
        // Handle event completed notifications.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppLaunchManager.handleEventCompleted(notification:)),
                                               name: NSNotification.Name(rawValue: AppLaunchManager.eventCompleted),
                                               object: nil)
    }
    
    @objc fileprivate func handleEventCompleted(notification: NSNotification) {
        
    }
}
