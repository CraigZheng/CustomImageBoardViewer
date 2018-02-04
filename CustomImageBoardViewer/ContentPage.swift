//
//  ContentPage.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 5/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import Foundation

class ContentPage: NSObject {
  var threads: [czzThread] = []
  var pageNumber: Int = 0
  var forum: czzForum?
  var count: Int {
    return threads.count
  }
}
