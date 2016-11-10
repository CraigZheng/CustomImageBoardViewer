//
//  MessagePopup.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 9/11/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import Foundation

import SwiftMessages

@objc enum MessagePopupLayout: Int {
    
    /**
     The standard message view that stretches across the full width of the
     container view.
     */
    case MessageView
    
    /**
     A floating card-style view with rounded corners.
     */
    case CardView
    
    /**
     Like `CardView` with one end attached to the super view.
     */
    case TabView
    
    /**
     A 20pt tall view that can be used to overlay the status bar.
     Note that this layout will automatically grow taller if displayed
     directly under the status bar (see the `ContentInsetting` protocol).
     */
    case StatusLine
    
    /**
     A standard message view like `MessageView`, but without
     stack views for iOS 8.
     */
    case MessageViewIOS8
    var swiftValue: MessageView.Layout {
        switch self {
        case .MessageView:
            return .MessageView
        case .CardView:
            return .CardView
        case .TabView:
            return .TabView
        case .StatusLine:
            return .StatusLine
        case .MessageViewIOS8:
            return .MessageViewIOS8
        }
    }
}

@objc enum MessagePopupTheme: Int {
    case info
    case success
    case warning
    case error
    var swiftValue: Theme {
        switch self {
        case .info:
            return .info
        case .success:
            return .success
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }
}

@objc enum MessagePopupPresentationStyle: Int {
    
    /**
     Message view slides down from the top.
     */
    case top
    
    /**
     Message view slides up from the bottom.
     */
    case bottom
    
    var swiftValue: SwiftMessages.PresentationStyle {
        switch self {
        case .top:
            return .top
        case .bottom:
            return .bottom
        }
    }
}

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
    
    /// For objective C callers.
    @objc class func showMessagePopup(title: String?, message: String?, layout: MessagePopupLayout, theme: MessagePopupTheme, position: MessagePopupPresentationStyle, buttonTitle: String, buttonActionHandler: ((_ button: UIButton) -> Void)?) {
        showMessage(title: title, message: message, layout: layout.swiftValue, theme: theme.swiftValue, position: position.swiftValue, buttonTitle: buttonTitle, buttonActionHandler: buttonActionHandler)
    }
}
