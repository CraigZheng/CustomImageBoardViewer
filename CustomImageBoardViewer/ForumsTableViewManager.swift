//
//  czzForumsTableViewManager.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 8/5/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import UIKit

import iOS_Slide_Menu

class ForumsTableViewManager: NSObject {
    var forumGroups: [czzForumGroup] = []
}

extension ForumsTableViewManager: UITableViewDelegate, UITableViewDataSource {
    
    private struct CellIdentifier {
        static let forum = "forum_cell_identifier"
    }
    
    private struct Notification {
        static let pickedForum = "ForumNamePicked"
        static let forum = "PickedForum"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let forumCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.forum, for: indexPath)
        if let forum = forumGroups[indexPath.section].forums[indexPath.row] as? czzForum {
            let displayName = !forum.screenName.isEmpty ? forum.screenName : forum.name
            forumCell.textLabel?.text = displayName
            if let displayData = displayName?.data(using: .utf8),
                let defaultFont = forumCell.textLabel?.font
                {
                if let attributedDisplayName = try? NSMutableAttributedString(data: displayData,
                                                                              options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                        NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue],
                                                                              documentAttributes: nil) {
                    attributedDisplayName.addAttributes([NSFontAttributeName: defaultFont], range: NSMakeRange(0, attributedDisplayName.length))
                    if czzSettingsCentre.sharedInstance().userDefNightyMode {
                        attributedDisplayName.addAttributes([NSForegroundColorAttributeName: czzSettingsCentre.sharedInstance().contentTextColour()],
                                                            range: NSMakeRange(0, attributedDisplayName.length))
                    }
                    forumCell.textLabel?.attributedText = attributedDisplayName
                }
            }
        }
        forumCell.contentView.backgroundColor = czzSettingsCentre.sharedInstance().viewBackgroundColour();
        return forumCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forumGroups[section].forums.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return forumGroups.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return forumGroups[section].area
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SlideNavigationController.sharedInstance().closeMenu(completion: nil)
        if let forum = forumGroups[indexPath.section].forums[indexPath.row] as? czzForum {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notification.pickedForum), object: nil, userInfo: [Notification.forum: forum])
        }
    }
}
