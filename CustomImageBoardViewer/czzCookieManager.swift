//
//  czzCookieManager.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 3/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import Foundation

import SwiftyJSON

extension czzCookieManager {
    func parseJson(_ jsonString: String) -> String {
        return JSON(jsonString)["cookie"].stringValue
    }
}
