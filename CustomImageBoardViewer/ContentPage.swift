//
//  ContentPage.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 5/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import Foundation

@objcMembers class ContentPage: NSObject {
  var threads: [czzThread] {
    get {
      guard !(showOnlyUserID ?? "").isEmpty else {
        return _threads;
      }
      let threads = _threads.filter { $0.uid == showOnlyUserID }
      return threads;
    }
    
    set {
      _threads = newValue
    }
  }
  private var _threads: [czzThread] = []
  var showOnlyUserID: String?
  var pageNumber: Int = 0
  var forum: czzForum?
  var displayableThreadCount: Int {
    return threads.count
  }
  var realThreadCount: Int { _threads.count }
}
