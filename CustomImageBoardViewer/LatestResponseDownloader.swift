//
//  LastestResponseDownloader.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/5/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import UIKit

class LatestResponseDownloader: czzThreadDownloader {

    override var targetURLString: String! {
        return czzSettingsCentre.sharedInstance().timeline_url
    }

}
