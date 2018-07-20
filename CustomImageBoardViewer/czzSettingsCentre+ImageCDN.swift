//
//  czzSettingsCentre+ImageCDN.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 20/7/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import Foundation

extension czzSettingsCentre {
    func validateImageCDN() {
      guard let cdnConfigurationURL = URL(string: ImageCDNConfiguration) {
        return
      }
    }
}
