//
//  String+CIV.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 16/5/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import Foundation

extension NSString {
    
    var numericString: String {
        let components = self.components(separatedBy: CharacterSet.decimalDigits.inverted)
        return components.joined(separator: "")
    }
    
}
