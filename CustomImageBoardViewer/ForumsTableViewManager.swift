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
        static let pickedForum = NSNotification.Name.forumPicked.rawValue
        static let forum = kPickedForum
        static let timeline = kPickedTimeline
    }
    
    private enum ExtraSection: Int {
        case advertisement = 0
        case timeline
        
        var title: String {
            switch self {
            case .advertisement: return "广告"
            case .timeline: return "最新回复"
            }
        }
        
        var count: Int {
            switch self {
            case .advertisement: return 0
            case .timeline: return czzSettingsCentre.sharedInstance().timeline_url.isEmpty ? 0 : 1
            }
        }
        
        static var count: Int {
            return 2
        }
        
        static func adjustedSection(for section: Int) -> Int {
            return section - ExtraSection.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let forumCell: UITableViewCell;
        if indexPath.section < ExtraSection.count {
            // For extra sections.
            // TODO: return appropriate cells.
            switch ExtraSection(rawValue: indexPath.section)! {
            case .timeline:
                forumCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.forum, for: indexPath)
                forumCell.textLabel?.text = ExtraSection.timeline.title
            default: forumCell = UITableViewCell()
            }
        } else {
            forumCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.forum, for: indexPath)
            let adjustedSection = ExtraSection.adjustedSection(for: indexPath.section)
            if let forum = forumGroups[adjustedSection].forums[indexPath.row] as? czzForum {
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
        }
        forumCell.textLabel?.textColor = czzSettingsCentre.sharedInstance().contentTextColour()
        forumCell.contentView.backgroundColor = czzSettingsCentre.sharedInstance().viewBackgroundColour();
        return forumCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let adjustedSection = ExtraSection.adjustedSection(for: section)
        guard adjustedSection >= 0 else {
            return ExtraSection(rawValue: section)?.count ?? 0
        }
        return forumGroups[adjustedSection].forums.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return forumGroups.count + ExtraSection.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let adjustedSection = ExtraSection.adjustedSection(for: section)
        guard adjustedSection >= 0 else {
            if let extraSection = ExtraSection(rawValue: section) {
                return extraSection.count > 0 ? extraSection.title : nil
            }
            return nil
        }
        return forumGroups[adjustedSection].area
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SlideNavigationController.sharedInstance().closeMenu(completion: nil)
        let adjustedSection = ExtraSection.adjustedSection(for: indexPath.section)
        guard adjustedSection >= 0 else {
            switch ExtraSection(rawValue: indexPath.section) {
            case .timeline?:
                // Inform the timeline has been picked, at the moment I am just passing an empty NSObject around.
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notification.pickedForum),
                                                object: nil,
                                                userInfo: [Notification.timeline: NSObject()])
            default: break
            }
            return
        }
        if let forum = forumGroups[adjustedSection].forums[indexPath.row] as? czzForum {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notification.pickedForum),
                                            object: nil,
                                            userInfo: [Notification.forum: forum])
        }
    }
}
