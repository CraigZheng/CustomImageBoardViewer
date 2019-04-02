//
//  DraftManager.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 13/5/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import UIKit

@objcMembers class DraftManager: NSObject {
  
  private struct Key {
    static let drafts = "Key.drafts"
    static let dates = "Key.dates"
    static let maximum = 10
  }
  
  class var count: Int {
    return drafts.count
  }
  
  class var drafts: [(String, Date)] {
    get {
      guard let drafts = UserDefaults.standard.array(forKey: Key.drafts) as? [String],
        let dates = UserDefaults.standard.array(forKey: Key.dates) as? [Date] else {
          return []
      }
      return Array(zip(drafts, dates))
    }
  }
  
  @objc class func save(_ draft: String) {
    guard !draft.isEmpty else {
      return
    }
    var draftsToSave = drafts
    // Ensure the drafts array contain no more than the maximum number of elements.
    if (draftsToSave.count >= Key.maximum) {
      draftsToSave.removeFirst()
    }
    if let previousSavedIndex = draftsToSave.firstIndex(where: { (string, Date) -> Bool in
      return string == draft
    }) {
      draftsToSave.remove(at: previousSavedIndex)
    }
    draftsToSave.append((draft, Date()))
    save(draftsToSave)
  }
  
  class func delete(_ draft: String) {
    guard !draft.isEmpty else {
      return
    }
    var draftsToSave = drafts
    // Ensure the drafts array contain no more than the maximum number of elements.
    if (draftsToSave.count >= Key.maximum) {
      draftsToSave.removeFirst()
    }
    if let previousSavedIndex = draftsToSave.firstIndex(where: { (string, Date) -> Bool in
      return string == draft
    }) {
      draftsToSave.remove(at: previousSavedIndex)
    }
    save(draftsToSave)
  }
  
  private class func save(_ drafts: [(String, Date)]) {
    UserDefaults.standard.set(drafts.flatMap({ (string, _) -> String in
      return string
    }), forKey: Key.drafts)
    UserDefaults.standard.set(drafts.compactMap({ (_, date) -> Date in
      return date
    }), forKey: Key.dates)
  }
  
  class func clear() {
    save([])
  }
  
}
