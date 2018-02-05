//
//  CookieDetailTableViewController.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 3/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import UIKit

class CookieDetailTableViewController: UITableViewController {
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    originalCookieValue = cookieValue
    if let cookieValue = cookieValue {
      cookieValueLabel.text = cookieValue
    }
    hostPickerView.selectRow(activeHost.rawValue, inComponent: 0, animated: false)
  }
  
  @IBAction func resetAction(_ sender: Any) {
    cookieValue = originalCookieValue
  }
  
  @IBAction func addAction(_ sender: Any) {
    if let cookieValue = cookieValue, !cookieValue.isEmpty {
      let cookie = czzACTokenUtil.createCookie(withValue: cookieValue,
                                               for: URL(string: hostPickerView.selectedRow(inComponent: 0) == 0 ? czzSettingsCentre.sharedInstance().ac_isle_host : czzSettingsCentre.sharedInstance().bt_isle_host))
      czzCookieManager.sharedInstance().setACCookie(cookie, for: nil)
      navigationController?.popToRootViewController(animated: true)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let textInputViewController = segue.destination as? CookieTextInputViewController {
      textInputViewController.prefilledString = cookieValue
      textInputViewController.delegate = self
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
}

extension CookieDetailTableViewController: CookieTextInputViewControllerDelegate {
  func textDetailEntered(_ inputViewController: CookieTextInputViewController, enteredDetails: String) {
    cookieValue = enteredDetails
  }
}
