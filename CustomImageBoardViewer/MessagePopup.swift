//
//  MessagePopup.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 9/11/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import Foundation

import SwiftMessages

class MessagePopup: NSObject {
    
    class func showMessage(title: String?, message: String?) {
        showMessage(title: title, message: message, layout: .CardView)
    }
    
    class func showMessage(title: String?, message: String?, layout: MessageView.Layout = .CardView, theme: Theme = .info, position: SwiftMessages.PresentationStyle = .top, buttonTitle: String? = nil, buttonActionHandler: ((_ button: UIButton) -> Void)? = nil) {
        let messageView = MessageView.viewFromNib(layout: layout)
        messageView.configureTheme(theme)
        messageView.configureContent(title: title ?? "", body: message ?? "")
        if let buttonTitle = buttonTitle, !buttonTitle.isEmpty {
            messageView.button?.isHidden = false
            messageView.button?.setTitle(buttonTitle, for: .normal)
            messageView.buttonTapHandler = buttonActionHandler
        } else {
            messageView.button?.isHidden = true
        }
        // Show with default config.
        var config = SwiftMessages.Config()
        config.presentationStyle = position
        SwiftMessages.show(config: config, view: messageView)
    }
    
}
