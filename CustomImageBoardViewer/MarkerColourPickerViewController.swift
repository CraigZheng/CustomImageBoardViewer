//
//  MarkerColourPickerViewController.swift
//  CustomImageBoardViewer
//
//  Created by Craig on 19/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol MarkerColourPickerViewControllerProtocol {
    func didFinishSelecting(colour: UIColor?, for UID: String?)
}

class MarkerColourPickerViewController: UIViewController {
    var delegate: MarkerColourPickerViewControllerProtocol?
    
    var UID: String? {
        didSet {
            uidLabel?.text = UID
        }
    }
    var nickname: String? {
        didSet {
            nicknameTextField?.text = nickname
        }
    }
    var selectedColour: UIColor? {
        didSet {
            if selectedColour == lastColour {
                flagImageView?.image = UIImage.init(named: "poison")?.withRenderingMode(.alwaysTemplate)
                flagImageView?.tintColor = UIColor.black
            } else {
                flagImageView?.image = UIImage.init(named: "flag")?.withRenderingMode(.alwaysTemplate)
                flagImageView?.tintColor = selectedColour
            }
        }
    }
    
    // RRGGBB hex colors in the same order as the image
    private let colorArray = [ 0x000000, 0xfe0000, 0xff7900, 0xffb900, 0xffde00, 0xfcff00, 0xd2ff00, 0x05c000, 0x00c0a7, 0x0600ff, 0x6700bf, 0x9500c0, 0xbf0199, 0xffffff ]
    private let lastColour = MarkerColourPickerViewController.uiColorFromHex(rgbValue:0xffffff)
    
    @IBOutlet private weak var uidLabel: UILabel?
    @IBOutlet private weak var nicknameTextField: UITextField?
    @IBOutlet private weak var flagImageView: UIImageView? {
        didSet {
            flagImageView?.image = UIImage.init(named: "flag")?.withRenderingMode(.alwaysTemplate)
            // The initial colour is light gray.
            flagImageView?.tintColor = UIColor.lightGray
        }
    }
    @IBOutlet private weak var slider: UISlider!
    @IBAction func colourSliderValueChanged(_ sender: UISlider) {
        selectedColour = MarkerColourPickerViewController.uiColorFromHex(rgbValue: colorArray[Int(sender.value)])
    }
    
    @IBAction func tapOnBackgroundView(_ sender: AnyObject) {
        if let UID = self.UID {
            // Do nickname first, since selectedColour might unhighlight this UID.
            if let nickname = nickname {
                czzMarkerManager.sharedInstance().highlightUID(UID, withNickname: nickname)
                czzMarkerManager.sharedInstance().pendingHighlightUIDs.remove(UID)
            }
            if let selectedColour = self.selectedColour {
                if selectedColour == lastColour {
                    czzMarkerManager.sharedInstance().pendingHighlightUIDs.remove(UID)
                    czzMarkerManager.sharedInstance().unHighlightUID(UID)
                    czzMarkerManager.sharedInstance().blockUID(UID)
                } else {
                    czzMarkerManager.sharedInstance().unBlockUID(UID)
                    czzMarkerManager.sharedInstance().highlightUID(UID, withColour: selectedColour)
                }
            }
        }
        _ = navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion:nil)
    }
    
    @IBAction func nicknameButtonAction(_ sender: AnyObject) {
        // Show a text alertview for entering nickname.
        let textAlertView = UIAlertView(title: "",
                                        message: "自定义名称（可以留空）",
                                        delegate: self,
                                        cancelButtonTitle: "取消",
                                        otherButtonTitles: "确定")
        textAlertView.alertViewStyle = .plainTextInput
        textAlertView.textField(at: 0)?.delegate = self
        textAlertView.show()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uidLabel?.text = UID
        nicknameTextField?.text = nickname
        if let selectedColour = selectedColour {
            flagImageView?.tintColor = selectedColour
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didFinishSelecting(colour: selectedColour, for: UID)
    }

    private class func uiColorFromHex(rgbValue: Int) -> UIColor {
        
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
        let blue =  CGFloat(rgbValue & 0x0000FF) / 0xFF
        let alpha = CGFloat(1.0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

}

extension MarkerColourPickerViewController: UITextFieldDelegate, UIAlertViewDelegate {
    
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            if let textField = alertView.textField(at: 0) {
                nickname = textField.text ?? ""
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Limit the length of the string.
        var shouldChange = true
        if let originalText = textField.text {
            let combinedString = (originalText as NSString).replacingCharacters(in: range, with: string)
            // Maximum allowed characters count.
            shouldChange = combinedString.characters.count <= 50
        }
        return shouldChange
    }
    
}
