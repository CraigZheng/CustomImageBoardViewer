//
//  ThemeSelectorViewController.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 10/7/2022.
//  Copyright © 2022 Craig. All rights reserved.
//

import UIKit

class ThemeSelectorViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
  private var picker: UIPickerView?
  let options = ["跟随iOS系统设定", "黑夜模式", "普通模式"]
  
  override func loadView() {
    let rootView = UIView(frame: UIScreen.main.bounds)
    rootView.backgroundColor = .systemBackground
    view = rootView

    let picker = UIPickerView()
    picker.translatesAutoresizingMaskIntoConstraints = false
    picker.dataSource = self
    picker.delegate = self
    rootView.addSubview(picker)
    self.picker = picker

    let toolbar = UIToolbar()
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    toolbar.items = [
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      UIBarButtonItem(title: "OK", style: .plain, target: self, action: #selector(didTapOK(_:)))
    ]
    rootView.addSubview(toolbar)

    let safeArea = rootView.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      toolbar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
      toolbar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
      toolbar.heightAnchor.constraint(equalToConstant: 44),
      picker.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
      picker.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
      picker.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
      picker.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
    ])
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if czzSettingsCentre.sharedInstance().userDefUseSystemNightMode {
      picker?.selectRow(0, inComponent: 0, animated: false)
    } else if czzSettingsCentre.sharedInstance().userDefNightyMode {
      picker?.selectRow(1, inComponent: 0, animated: false)
    } else {
      picker?.selectRow(2, inComponent: 0, animated: false)
    }
  }
  
  @IBAction func didTapOK(_ sender: UIBarButtonItem) {
    switch picker?.selectedRow(inComponent: 0) {
    case 1:
      czzSettingsCentre.sharedInstance().userDefUseSystemNightMode = false
      czzSettingsCentre.sharedInstance().userDefNightyMode = true
    case 2:
      czzSettingsCentre.sharedInstance().userDefUseSystemNightMode = false
      czzSettingsCentre.sharedInstance().userDefNightyMode = false
    default:
      czzSettingsCentre.sharedInstance().userDefUseSystemNightMode = true
    }
    czzSettingsCentre.sharedInstance().saveSettings()
    self.dismiss(animated: true)
  }
  
  // MARK: - UIPickerViewDataSource & UIPickerViewDelegate
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return options.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return options[row]
  }
}
