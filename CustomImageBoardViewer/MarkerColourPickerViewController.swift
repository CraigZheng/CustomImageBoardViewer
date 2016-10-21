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
    var selectedColour: UIColor? {
        didSet {
            flagImageView?.tintColor = selectedColour
        }
    }
    
    // RRGGBB hex colors in the same order as the image
    private let colorArray = [ 0x000000, 0xfe0000, 0xff7900, 0xffb900, 0xffde00, 0xfcff00, 0xd2ff00, 0x05c000, 0x00c0a7, 0x0600ff, 0x6700bf, 0x9500c0, 0xbf0199, 0xffffff ]
    private let lastColour = MarkerColourPickerViewController.uiColorFromHex(rgbValue:0xffffff)
    
    @IBOutlet private weak var uidLabel: UILabel?
    @IBOutlet weak var skeletonImageView: UIImageView! {
        didSet {
            skeletonImageView.isHidden = true
        }
    }
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
        skeletonImageView.isHidden = !(selectedColour == lastColour)
        flagImageView?.isHidden = !skeletonImageView.isHidden
    }
    
    @IBAction func tapOnBackgroundView(_ sender: AnyObject) {
        if let UID = self.UID,
            let selectedColour = self.selectedColour {
            if selectedColour == lastColour {
                czzMarkerManager.sharedInstance().pendingHighlightUIDs.remove(UID)
                czzMarkerManager.sharedInstance().unHighlightUID(UID)
                czzMarkerManager.sharedInstance().blockUID(UID)
            } else {
                czzMarkerManager.sharedInstance().unBlockUID(UID)
                czzMarkerManager.sharedInstance().highlightUID(UID, withColour: selectedColour)
            }
        }
        _ = navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uidLabel?.text = UID
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
