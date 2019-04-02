//
//  File.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

extension UINavigationController {
  
  @objc public func pushViewController(viewController: UIViewController,
                                       animated: Bool,
                                       completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    pushViewController(viewController, animated: animated)
    CATransaction.commit()
  }
  
}
