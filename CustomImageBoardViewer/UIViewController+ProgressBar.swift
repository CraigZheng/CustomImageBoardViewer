//
//  UIViewController+ProgressBar.swift
//  Exellency
//
//  Created by Craig Zheng on 5/04/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import Foundation

extension UIViewController {
    func showLoading() {
        hideLoading()
        print("showLoading()")
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicator.startAnimating()
        let indicatorBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        if var rightBarButtonItems = navigationItem.rightBarButtonItems {
            rightBarButtonItems.append(indicatorBarButtonItem)
            navigationItem.rightBarButtonItems = rightBarButtonItems
        } else {
            navigationItem.rightBarButtonItem = indicatorBarButtonItem
        }
    }
    
    func hideLoading() {
        print("hideLoading()")
        if let rightBarButtonItems = navigationItem.rightBarButtonItems {
            var BarButtonItemsWithoutActivityIndicator = rightBarButtonItems
            for button in rightBarButtonItems {
                if let customView = button.customView {
                    if customView.isKindOfClass(UIActivityIndicatorView) {
                        // Remove the bar button with an activity indicator as the custom view.
                        BarButtonItemsWithoutActivityIndicator.removeObject(button)
                    }
                }
            }
            // At the end, if the count of the array without activity indicator is different than the original array,
            // then assign the modified array to the menu bar.
            if BarButtonItemsWithoutActivityIndicator.count != rightBarButtonItems.count {
                navigationItem.rightBarButtonItems = BarButtonItemsWithoutActivityIndicator
            }
        }
    }
}

extension RangeReplaceableCollectionType where Generator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}
