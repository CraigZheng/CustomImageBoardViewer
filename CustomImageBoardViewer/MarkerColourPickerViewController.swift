//
//  MarkerColourPickerViewController.swift
//  CustomImageBoardViewer
//
//  Created by Craig on 19/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class MarkerColourPickerViewController: UIViewController {

    var UID: String? {
        didSet {
            uidLabel.text = UID
        }
    }
    var selectedColour: UIColor? {
        didSet {
            flagImageView.tintColor = selectedColour
        }
    }
    
    // RRGGBB hex colors in the same order as the image
    private let colorArray = [ 0x000000, 0xfe0000, 0xff7900, 0xffb900, 0xffde00, 0xfcff00, 0xd2ff00, 0x05c000, 0x00c0a7, 0x0600ff, 0x6700bf, 0x9500c0, 0xbf0199, 0xffffff ]
    
    @IBOutlet private weak var uidLabel: UILabel!
    @IBOutlet private weak var flagImageView: UIImageView! {
        didSet {
            flagImageView.image = UIImage.init(named: "flag")?.withRenderingMode(.alwaysTemplate)
        }
    }
    @IBOutlet private weak var slider: UISlider!
    @IBAction func colourSliderValueChanged(_ sender: UISlider) {
        selectedColour = uiColorFromHex(rgbValue: colorArray[Int(sender.value)])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    private func uiColorFromHex(rgbValue: Int) -> UIColor {
        
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
        let blue =  CGFloat(rgbValue & 0x0000FF) / 0xFF
        let alpha = CGFloat(1.0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

}
