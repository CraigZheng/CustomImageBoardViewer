//
//  UITableView+IndexPath.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 5/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import Foundation

extension UITableView {
  @objc var lastSection: Int {
    return numberOfSections - 1
  }
  @objc var lastRow: Int {
    return numberOfRows(inSection: lastSection) - 1
  }
  @objc var lastIndexPath: IndexPath {
    return IndexPath(row: lastRow, section: lastSection)
  }
}
