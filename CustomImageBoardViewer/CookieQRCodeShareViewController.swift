//
//  CookieQRCodeShareViewController.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 5/2/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import UIKit

class CookieQRCodeShareViewController: UIViewController {
  @IBOutlet private weak var qrCodeImageView: UIImageView!
  
  var cookieJson = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if !cookieJson.isEmpty, let jsonData = cookieJson.data(using: .utf8), let image = qrForData(jsonData) {
      qrCodeImageView.image = image
    }
  }
  
  // Copied from http://stackoverflow.com/questions/12051118/is-there-a-way-to-generate-qr-code-image-on-ios and mofieid.
  fileprivate func qrForData(_ data: Data) -> UIImage? {
    let filter = CIFilter(name: "CIQRCodeGenerator")
    filter?.setValue(data, forKey: "inputMessage")
    if let rawOutput = filter?.outputImage {
      let outputImage = rawOutput.transformed(by: CGAffineTransform(scaleX: 10.0, y: 10.0))
      return UIImage(ciImage: outputImage)
    } else {
      return nil
    }
  }
}
