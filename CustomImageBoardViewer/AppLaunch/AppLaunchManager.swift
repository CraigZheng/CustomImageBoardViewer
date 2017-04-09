//
//  AppLaunchManager.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 12/3/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import Foundation

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
    fileprivate var updatedThreads: [czzThread]? {
        didSet {
            if let updatedThreads = updatedThreads, !updatedThreads.isEmpty {
                // TODO: display a popup?
            }
        }
    }
    
    override init() {
        super.init()
        // Refresh watched threads immediately.
        czzWatchListManager.shared().lastActiveRefreshTime = Date()
        czzWatchListManager.shared().refreshWatchedThreads { [weak self] updatedThreads in
            if let updatedThreads = updatedThreads as? [czzThread] {
                self?.updatedThreads = updatedThreads
            }
        }
        NotificationCenter.default.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { _ in
            czzWatchListManager.shared().activeRefresh()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.remoteSettingUpdated, object: nil, queue: OperationQueue.main, using: { [weak self] _ in
            self?.isRemoteSettingsUpdated = true
        })
    }
}
