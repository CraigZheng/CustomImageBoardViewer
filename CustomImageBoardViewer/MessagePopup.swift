//
//  MessagePopup.swift
//  CustomImageBoardViewer
//
//  Native banner popup replacing SwiftMessages.
//

import UIKit

@objc enum MessagePopupLayout: Int {
    case MessageView
    case CardView
    case TabView
    case StatusLine
    case MessageViewIOS8
}

@objc enum MessagePopupTheme: Int {
    case info
    case success
    case warning
    case error
}

@objc enum MessagePopupPresentationStyle: Int {
    case top
    case bottom
}

@MainActor
class MessagePopup: NSObject {
    private static var currentBanner: UIView?
    private static var hideWorkItem: DispatchWorkItem?
    private static var currentButtonHandler: ((UIButton) -> Void)?

    @objc class func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        guard let banner = currentBanner else { return }
        currentBanner = nil
        currentButtonHandler = nil
        UIView.animate(withDuration: 0.2, animations: {
            banner.alpha = 0
            banner.transform = CGAffineTransform(translationX: 0, y: banner.frame.minY < UIScreen.main.bounds.midY ? -20 : 20)
        }, completion: { _ in
            banner.removeFromSuperview()
        })
    }

    class func showMessage(title: String?, message: String?) {
        showMessagePopup(title: title, message: message, layout: .CardView, theme: .info, position: .top, buttonTitle: nil, buttonActionHandler: nil)
    }

    @objc class func showStatusBarMessage(message: String?) {
        showMessagePopup(title: nil, message: message, layout: .StatusLine, theme: .info, position: .top, buttonTitle: nil, buttonActionHandler: nil)
    }

    @objc class func showMessagePopup(title: String?, message: String?, layout: MessagePopupLayout, theme: MessagePopupTheme, position: MessagePopupPresentationStyle, buttonTitle: String?, buttonActionHandler: ((UIButton) -> Void)?) {
        hide()

        guard let window = keyWindow() else { return }

        let banner = UIView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.backgroundColor = backgroundColor(for: theme)
        banner.layer.cornerRadius = layout == .StatusLine ? 0 : 12
        banner.clipsToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(stack)

        if let title, !title.isEmpty {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: layout == .StatusLine ? 12 : 15, weight: .semibold)
            titleLabel.textColor = .white
            titleLabel.numberOfLines = 2
            stack.addArrangedSubview(titleLabel)
        }

        if let message, !message.isEmpty {
            let bodyLabel = UILabel()
            bodyLabel.text = message
            bodyLabel.font = .systemFont(ofSize: layout == .StatusLine ? 12 : 14)
            bodyLabel.textColor = .white
            bodyLabel.numberOfLines = layout == .StatusLine ? 1 : 0
            stack.addArrangedSubview(bodyLabel)
        }

        var button: UIButton?
        if let buttonTitle, !buttonTitle.isEmpty {
            let actionButton = UIButton(type: .system)
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            actionButton.addTarget(self, action: #selector(bannerButtonTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(actionButton)
            button = actionButton
            currentButtonHandler = buttonActionHandler
        }

        window.addSubview(banner)
        currentBanner = banner

        let guide = window.safeAreaLayoutGuide
        let horizontalInset: CGFloat = layout == .StatusLine ? 0 : 12
        var constraints: [NSLayoutConstraint] = [
            banner.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: horizontalInset),
            banner.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -horizontalInset),
            stack.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: banner.topAnchor, constant: layout == .StatusLine ? 4 : 12),
            stack.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: layout == .StatusLine ? -4 : -12)
        ]

        if position == .bottom {
            constraints.append(banner.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -12))
        } else {
            constraints.append(banner.topAnchor.constraint(equalTo: guide.topAnchor, constant: layout == .StatusLine ? 0 : 8))
        }
        NSLayoutConstraint.activate(constraints)

        banner.alpha = 0
        banner.transform = CGAffineTransform(translationX: 0, y: position == .top ? -24 : 24)
        UIView.animate(withDuration: 0.25) {
            banner.alpha = 1
            banner.transform = .identity
        }

        let duration: TimeInterval = button == nil ? 10 : 15
        let work = DispatchWorkItem {
            hide()
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    @objc private class func bannerButtonTapped(_ sender: UIButton) {
        let handler = currentButtonHandler
        hide()
        handler?(sender)
    }

    private class func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    private class func backgroundColor(for theme: MessagePopupTheme) -> UIColor {
        switch theme {
        case .info:
            return UIColor(red: 0.20, green: 0.45, blue: 0.80, alpha: 0.95)
        case .success:
            return UIColor(red: 0.15, green: 0.60, blue: 0.30, alpha: 0.95)
        case .warning:
            return UIColor(red: 0.85, green: 0.55, blue: 0.10, alpha: 0.95)
        case .error:
            return UIColor(red: 0.80, green: 0.20, blue: 0.20, alpha: 0.95)
        }
    }
}
