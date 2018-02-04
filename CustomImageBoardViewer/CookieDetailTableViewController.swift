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
  
  var cookieValue: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let cookieValue = cookieValue {
      cookieValueLabel.text = cookieValue
    }
  }
  
  @IBAction func resetAction(_ sender: Any) {
  }
  
  @IBAction func addAction(_ sender: Any) {
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
    cookieValueLabel.text = cookieValue
  }
}
