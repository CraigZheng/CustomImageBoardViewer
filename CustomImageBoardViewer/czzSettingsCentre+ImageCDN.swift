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
        guard let imageCDNConfigurationHost = imageCDNConfigurationHost,
            !imageCDNConfigurationHost.isEmpty,
            let cdnConfigurationURL = URL(string: imageCDNConfigurationHost) else {
                return
        }
        URLSession(configuration: .default).dataTask(with: cdnConfigurationURL) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            if let cdnConfigurations = try? JSONDecoder().decode([ImageCDNConfiguration].self, from: data) {
                
            }
        }
    }
}
