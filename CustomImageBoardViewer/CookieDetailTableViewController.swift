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
  var cookieValue: String?
  
  @IBAction func resetAction(_ sender: Any) {
  }
  
  @IBAction func addAction(_ sender: Any) {
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
