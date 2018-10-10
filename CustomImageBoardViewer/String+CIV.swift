//
//  String+CIV.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 16/5/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import Foundation

extension String {
    /// Copied from https://stackoverflow.com/questions/30757193/find-out-if-character-in-string-is-emoji/39425959
    /// Detect if the string contains emoji.
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
            0x1F300...0x1F5FF, // Misc Symbols and Pictographs
            0x1F680...0x1F6FF, // Transport and Map
            0x2600...0x26FF,   // Misc symbols
            0x2700...0x27BF,   // Dingbats
            0xFE00...0xFE0F,   // Variation Selectors
            0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
            0x1F1E6...0x1F1FF: // Flags
                return true
            default:
                continue
            }
        }
        return false
    }
}

extension NSString {
    @objc var containsEmoji: Bool {
        return (self as String).containsEmoji
    }
    
    var numericString: String {
        let components = self.components(separatedBy: CharacterSet.decimalDigits.inverted)
        return components.joined(separator: "")
    }
    
    @objc func rangesOf(_ searchString: String) -> [NSRange] {
        var searchRange = NSMakeRange(0, length)
        var foundRange: NSRange
        var foundRanges: [NSRange] = []
        while searchRange.location < length {
            searchRange.length = length - searchRange.location
            foundRange = self.range(of: searchString, options: .caseInsensitive, range: searchRange)
            if foundRange.location != NSNotFound {
                searchRange.location = foundRange.location + foundRange.length
                foundRanges.append(foundRange)
            } else {
                searchRange.location = NSIntegerMax
            }
        }
        return foundRanges
    }
    
    /*
     // Copied from http://stackoverflow.com/questions/7033574/find-all-locations-of-substring-in-nsstring-not-just-first
     NSRange searchRange = NSMakeRange(0,string.length);
     NSRange foundRange;
     while (searchRange.location < string.length) {
     searchRange.length = string.length-searchRange.location;
     foundRange = [string rangeOfString:substring options:nil range:searchRange];
     if (foundRange.location != NSNotFound) {
     // found an occurrence of the substring! do stuff here
     searchRange.location = foundRange.location+foundRange.length;
     } else {
     // no more substring to find
     break;
     }
     }
 */
    
}
