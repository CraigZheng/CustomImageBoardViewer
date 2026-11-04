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
    
    private var uidLabel: UILabel?
    private var nicknameTextField: UITextField?
    private var flagImageView: UIImageView? {
        didSet {
            flagImageView?.image = UIImage.init(named: "flag")?.withRenderingMode(.alwaysTemplate)
            // The initial colour is light gray.
            flagImageView?.tintColor = UIColor.lightGray
        }
    }

    override func loadView() {
        let rootView = UIView()
        rootView.backgroundColor = UIColor(white: 0, alpha: 0.157613255)
        view = rootView

        let fillerView = UIView()
        fillerView.translatesAutoresizingMaskIntoConstraints = false
        fillerView.backgroundColor = .clear
        fillerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnBackgroundView)))
        rootView.addSubview(fillerView)

        let sheetView = UIView()
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.backgroundColor = .white
        rootView.addSubview(sheetView)

        let nicknameField = UITextField()
        nicknameField.translatesAutoresizingMaskIntoConstraints = false
        nicknameField.isUserInteractionEnabled = false
        nicknameField.borderStyle = .roundedRect
        nicknameField.placeholder = "昵称"
        nicknameField.textAlignment = .center
        nicknameField.font = .systemFont(ofSize: 14)
        sheetView.addSubview(nicknameField)
        nicknameTextField = nicknameField

        let nicknameButton = UIButton(type: .system)
        nicknameButton.translatesAutoresizingMaskIntoConstraints = false
        nicknameButton.addTarget(self, action: #selector(nicknameButtonAction), for: .touchUpInside)
        sheetView.addSubview(nicknameButton)

        let uid = UILabel()
        uid.translatesAutoresizingMaskIntoConstraints = false
        uid.font = .systemFont(ofSize: 17)
        uid.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
        sheetView.addSubview(uid)
        uidLabel = uid

        let flag = UIImageView()
        flag.translatesAutoresizingMaskIntoConstraints = false
        flag.contentMode = .scaleToFill
        sheetView.addSubview(flag)
        flagImageView = flag

        let sliderBackground = UIView()
        sliderBackground.translatesAutoresizingMaskIntoConstraints = false
        sliderBackground.backgroundColor = UIColor(white: 0.6666666667, alpha: 1)
        sheetView.addSubview(sliderBackground)

        let colorBand = UIImageView(image: UIImage(named: "colorband.png"))
        colorBand.translatesAutoresizingMaskIntoConstraints = false
        colorBand.contentMode = .scaleToFill
        sliderBackground.addSubview(colorBand)

        let poison = UIImageView(image: UIImage(named: "poison.png"))
        poison.translatesAutoresizingMaskIntoConstraints = false
        poison.contentMode = .scaleAspectFit
        sliderBackground.addSubview(poison)

        let colourSlider = UISlider()
        colourSlider.translatesAutoresizingMaskIntoConstraints = false
        colourSlider.minimumValue = 0.5
        colourSlider.maximumValue = 13.5
        colourSlider.value = 7.5
        colourSlider.tintColor = .clear
        colourSlider.minimumTrackTintColor = .clear
        colourSlider.maximumTrackTintColor = .clear
        colourSlider.addTarget(self, action: #selector(colourSliderValueChanged), for: .valueChanged)
        sliderBackground.addSubview(colourSlider)

        NSLayoutConstraint.activate([
            fillerView.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor),
            fillerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            fillerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            sheetView.topAnchor.constraint(equalTo: fillerView.bottomAnchor),
            sheetView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            rootView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor),
            sheetView.heightAnchor.constraint(equalTo: rootView.heightAnchor, multiplier: 0.5),

            nicknameField.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 20),
            nicknameField.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            nicknameField.widthAnchor.constraint(equalToConstant: 160),
            nicknameButton.topAnchor.constraint(equalTo: nicknameField.topAnchor),
            nicknameButton.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            nicknameButton.trailingAnchor.constraint(equalTo: nicknameField.trailingAnchor),
            nicknameButton.bottomAnchor.constraint(equalTo: nicknameField.bottomAnchor),

            uid.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            flag.centerYAnchor.constraint(equalTo: uid.centerYAnchor),
            flag.topAnchor.constraint(equalTo: nicknameField.bottomAnchor, constant: 8),
            flag.leadingAnchor.constraint(equalTo: uid.trailingAnchor, constant: 8),
            flag.widthAnchor.constraint(equalToConstant: 20),
            flag.heightAnchor.constraint(equalTo: flag.widthAnchor),

            sliderBackground.topAnchor.constraint(equalTo: uid.bottomAnchor, constant: 8),
            sliderBackground.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 20),
            sheetView.trailingAnchor.constraint(equalTo: sliderBackground.trailingAnchor, constant: 20),
            colorBand.leadingAnchor.constraint(equalTo: sliderBackground.leadingAnchor, constant: 4),
            sliderBackground.trailingAnchor.constraint(equalTo: colorBand.trailingAnchor, constant: 4),
            colorBand.topAnchor.constraint(equalTo: sliderBackground.topAnchor, constant: 2),
            sliderBackground.bottomAnchor.constraint(equalTo: colorBand.bottomAnchor, constant: 2),
            colorBand.heightAnchor.constraint(equalToConstant: 30),
            colourSlider.leadingAnchor.constraint(equalTo: colorBand.leadingAnchor),
            colourSlider.trailingAnchor.constraint(equalTo: colorBand.trailingAnchor),
            colourSlider.centerYAnchor.constraint(equalTo: colorBand.centerYAnchor),
            poison.topAnchor.constraint(equalTo: colorBand.topAnchor, constant: 4),
            colorBand.bottomAnchor.constraint(equalTo: poison.bottomAnchor, constant: 4),
            colorBand.trailingAnchor.constraint(equalTo: poison.trailingAnchor, constant: 2)
        ])

        let currentUID = UID
        let currentNickname = nickname
        let currentColour = selectedColour
        UID = currentUID
        nickname = currentNickname
        selectedColour = currentColour
    }

    @objc func colourSliderValueChanged(_ sender: UISlider) {
        selectedColour = MarkerColourPickerViewController.uiColorFromHex(rgbValue: colorArray[Int(sender.value)])
    }
    
    @objc func tapOnBackgroundView(_ sender: AnyObject) {
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
    
    @objc func nicknameButtonAction(_ sender: AnyObject) {
        // Show a text alertview for entering nickname.
        let textAlertView = UIAlertView(title: "",
                                        message: "自定义一个昵称（可以留空）",
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
            shouldChange = combinedString.count <= 50
        }
        return shouldChange
    }
    
}
