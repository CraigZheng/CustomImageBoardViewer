//
//  czzCookieManager.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 3/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import Foundation

extension czzCookieManager {
  func cookie(from json: String) -> String? {
    guard let jsonData = json.data(using: String.Encoding.utf8),
      let jsonDictionary = (try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)) as? [String: String] else {
        return nil
    }
    return jsonDictionary["cookie"]
  }
  
  func cookieJSON(from cookieValue: String) -> String? {
    var dictionary: [String: String] = [:]
    dictionary["cookie"] = cookieValue
    guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) else {
      return nil
    }
    return String(data: jsonData, encoding: .utf8)
  }
}
