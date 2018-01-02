//
//  NSUserDefaults+UIColor.swift
//  CustomImageBoardViewer
//
//  Created by Craig on 19/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    func colorForKey(_ key: String) -> UIColor? {
        var color: UIColor?
        if let colorData = data(forKey: key) {
            color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor
        }
        return color
    }
    
    func setColor(_ color: UIColor?, forKey key: String) {
        var colorData: Data?
        if let color = color {
            colorData = NSKeyedArchiver.archivedData(withRootObject: color)
        }
        set(colorData, forKey: key)
        synchronize()
    }
    
}
