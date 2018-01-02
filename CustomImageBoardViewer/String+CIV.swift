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
