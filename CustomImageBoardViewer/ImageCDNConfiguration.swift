//
//  ImageCDNConfiguration.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 20/7/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import Foundation

@objc class ImageCDNConfiguration: NSObject, Codable {
    var url: URL?
    var rate: Double = 0
}
