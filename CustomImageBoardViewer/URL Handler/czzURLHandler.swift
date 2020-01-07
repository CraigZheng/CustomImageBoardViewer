//
//  czzURLHandler.swift
//  CustomImageBoardViewer
//
//  Created by Craig on 30/9/19.
//  Copyright © 2019 Craig. All rights reserved.
//

import Foundation

extension czzURLHandler {
    private enum CustomURL {
        case thread(Int), forum(Int)
    }

    @objc class func handleCustomURL(_ url: URL) -> Bool {
        let pathComponent = url.lastPathComponent
        guard let scheme = url.scheme, let host = url.host, !pathComponent.isEmpty, let pathID = Int(pathComponent) else {
            return false
        }
            
        switch (scheme, host) {
        case ("adnmb", "t"):
            processCustomURL(.thread(pathID), host: .AC)
        case ("adnmb", "f"):
            processCustomURL(.forum(pathID), host: .AC)
        case ("tnmb", "t"):
            processCustomURL(.thread(pathID), host: .BT)
        case ("tnmb", "t"):
            processCustomURL(.forum(pathID), host: .BT)
        default:
            return false
        }
        return true
    }
    
    private class func processCustomURL(_ customURL: CustomURL, host: SettingsHost) {
        guard let navigationController = (czzAppDelegate.shared()?.window.rootViewController as? UINavigationController) else {
            return
        }
        navigationController.popToRootViewController(animated: false)
        navigationController.dismiss(animated: false)

        if czzSettingsCentre.sharedInstance()?.userDefActiveHost != host {
            czzSettingsCentre.sharedInstance()?.userDefActiveHost = host
            czzSettingsCentre.sharedInstance()?.saveSettings()
            czzForumManager.shared()?.resetForums()
        }
        
        switch customURL {
        case .forum(let forumID):
            if let forum = czzForumManager.shared()?.forums.first(where: { $0.forumID == forumID }) {
                NotificationCenter.default.post(name: NSNotification.Name.forumPicked,
                object: nil,
                userInfo: [kPickedForum: forum])
            } else {
                // Cannot find a forum with selected ID, show timeline instead.
                NotificationCenter.default.post(name: NSNotification.Name.forumPicked,
                                                object: nil,
                                                userInfo: [kPickedTimeline: NSObject()])
            }
        case .thread(let threadID):
            guard let threadViewController = UIStoryboard(name: THREAD_VIEW_CONTROLLER_STORYBOARD_NAME, bundle: nil).instantiateViewController(withIdentifier: THREAD_VIEW_CONTROLLER_ID) as? czzThreadViewController else {
                return
            }
            threadViewController.thread = czzThread(threadID: threadID)
            navigationController.pushViewController(threadViewController, animated: true)
        }
    }
}
