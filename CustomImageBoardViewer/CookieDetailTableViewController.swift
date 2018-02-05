//
//  CookieDetailTableViewController.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 3/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import UIKit

class CookieDetailTableViewController: UITableViewController {
  private enum SegueIdentifier: String {
    case unwindToCookieManager
  }
  
  @IBOutlet weak var addButton: RoundCornerBorderedButton!
  @IBOutlet weak var hostPickerView: UIPickerView!
  @IBOutlet weak var cookieValueLabel: UILabel!
  
  @objc var activeHost = SettingsHost.AC
  var cookieValue: String? {
    didSet {
      if let cookieValue = cookieValue {
        cookieValueLabel?.text = cookieValue
      }
    }
  }
  private var originalCookieValue: String?
  private var originalHost = SettingsHost.AC
  
  override func viewDidLoad() {
    super.viewDidLoad()
    originalCookieValue = cookieValue
    originalHost = activeHost
    if let cookieValue = cookieValue {
      cookieValueLabel.text = cookieValue
    }
    hostPickerView.selectRow(activeHost.rawValue, inComponent: 0, animated: false)
    addButton.setTitle(czzCookieManager.sharedInstance().currentACCookies().isEmpty ? "启用" : "保存到保鲜库",
                       for: .normal)
  }
  
  @IBAction func resetAction(_ sender: Any) {
    cookieValue = originalCookieValue
    activeHost = originalHost
    hostPickerView.selectRow(activeHost.rawValue, inComponent: 0, animated: false)
  }
  
  @IBAction func addAction(_ sender: Any) {
    if let cookieValue = cookieValue, !cookieValue.isEmpty, let hostURL = URL(string: activeHost == .AC ? czzSettingsCentre.sharedInstance().ac_isle_host : czzSettingsCentre.sharedInstance().bt_isle_host) {
      let cookie = czzACTokenUtil.createCookie(withValue: cookieValue,
                                               for: hostURL)
      let message: String
      if czzCookieManager.sharedInstance().currentACCookies().isEmpty {
        czzCookieManager.sharedInstance().setACCookie(cookie, for: hostURL)
        message = "饼干已启用"
      } else {
        message = "饼干已保存"
      }
      czzCookieManager.sharedInstance().archiveCookie(cookie)
      DispatchQueue.main.async {
        czzBannerNotificationUtil.displayMessage(message, position: .top)
      }
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let textInputViewController = segue.destination as? CookieTextInputViewController {
      textInputViewController.prefilledString = cookieValue
      textInputViewController.delegate = self
    }
    if let cookieQRCodeShareViewController = segue.destination as? CookieQRCodeShareViewController,
      let cookieValue = cookieValue,
      let cookieJson = czzCookieManager.sharedInstance().cookieJSON(from: cookieValue) {
      cookieQRCodeShareViewController.cookieJson = cookieJson
    }
  }
}

// MARK: - UIPickerViewDataSource, UIDocumentPickerDelegate
extension CookieDetailTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return 2
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return ["主岛", "备胎岛"][row]
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    activeHost = SettingsHost(rawValue: row)!
  }
}

extension CookieDetailTableViewController: CookieTextInputViewControllerDelegate {
  func textDetailEntered(_ inputViewController: CookieTextInputViewController, enteredDetails: String) {
    cookieValue = enteredDetails
  }
}
