//
//  DraftManager.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 13/5/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import UIKit

class DraftManager: NSObject {
    
    private struct Key {
        static let drafts = "Key.drafts"
        static let maximum = 10
    }

    class var drafts: [String] {
        get {
            return UserDefaults.standard.array(forKey: Key.drafts) as? [String] ?? []
        }
    }
    
    class func save(_ draft: String) {
        guard !draft.isEmpty else {
            return
        }
        var draftsToSave = drafts
        // Ensure the drafts array contain no more than the maximum number of elements.
        if (draftsToSave.count >= Key.maximum) {
            draftsToSave.removeFirst()
        }
        if let previousSavedIndex = draftsToSave.index(of: draft) {
            draftsToSave.remove(at: previousSavedIndex)
        }
        draftsToSave.append(draft)
        save(draftsToSave)
    }
    
    private class func save(_ drafts: [String]) {
        UserDefaults.standard.set(drafts, forKey: Key.drafts)
    }
    
    class func clear() {
        save([])
    }
    
}
