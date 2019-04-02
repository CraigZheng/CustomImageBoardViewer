//
//  czzSettingsCentre+ImageCDN.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 20/7/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import Foundation

extension czzSettingsCentre {
    @objc func validateImageCDN() {
        guard let imageCDNConfigurationHost = imageCDNConfigurationHost,
            !imageCDNConfigurationHost.isEmpty,
            let cdnConfigurationURL = URL(string: imageCDNConfigurationHost) else {
                return
        }
        URLSession(configuration: .default).dataTask(with: cdnConfigurationURL) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            if let cdnConfigurations = try? JSONDecoder().decode([ImageCDNConfiguration].self, from: data).sorted(by: { configuration1, configuration2 in
                return configuration1.rate < configuration2.rate
            }),
                !cdnConfigurations.isEmpty,
                let percentageUpperBound = cdnConfigurations.last?.rate {
                var random: Double
                repeat {
                    random = drand48()
                } while random > percentageUpperBound
                
                for configuration in cdnConfigurations {
                    if random < configuration.rate {
                        self.image_host = configuration.imageURL?.absoluteString
                        self.thumbnail_host = configuration.thumbnailURL?.absoluteString
                        break
                    }
                }
            }
        }.resume()
    }
}

extension ImageCDNConfiguration {
    var imageURL: URL? {
        return url?.appendingPathComponent("image")
    }
    
    var thumbnailURL: URL? {
        return url?.appendingPathComponent("thumb")
    }
}
