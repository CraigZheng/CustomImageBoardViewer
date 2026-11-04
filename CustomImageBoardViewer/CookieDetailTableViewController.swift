//
//  CookieDetailTableViewController.swift
//  CustomImageBoardViewer
//
//  Created by Haozheng Zheng on 3/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import UIKit

@objcMembers class CookieDetailTableViewController: UITableViewController {
  private var addButton: UIButton!
  private var deleteButton: UIButton!
  private var hostPickerView: UIPickerView!
  private var cookieValueLabel: UILabel!
  private var cookieValueCell: UITableViewCell!
  private var rows: [UITableViewCell] = []
  
  var originalCookie: HTTPCookie?
  var isOriginalCookieFromArchive = false
  var activeHost = SettingsHost.AC
  var cookieValue: String? {
    didSet {
      if let cookieValue = cookieValue {
        cookieValueLabel?.text = cookieValue
      }
    }
  }
  var isEditable = false
  private var originalCookieValue: String?
  private var originalHost = SettingsHost.AC
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "饼干"
    tableView.backgroundColor = .white
    let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 5))
    footer.backgroundColor = .white
    tableView.tableFooterView = footer
    rows = [cookieValueRow(), hostPickerRow(), actionRow(), deleteRow(), shareRow()]
    originalCookieValue = cookieValue
    originalHost = activeHost
    if let cookieValue = cookieValue {
      cookieValueLabel.text = cookieValue
    }
    cookieValueCell.isUserInteractionEnabled = isEditable
    hostPickerView.selectRow(activeHost.rawValue, inComponent: 0, animated: false)
    deleteButton.isEnabled = originalCookie != nil
  }

  @objc func resetAction(_ sender: Any) {
    cookieValue = originalCookieValue
    activeHost = originalHost
    hostPickerView.selectRow(activeHost.rawValue, inComponent: 0, animated: false)
  }
  
  @objc func addAction(_ sender: Any) {
    if let cookieValue = cookieValue, !cookieValue.isEmpty, let hostURL = URL(string: activeHost == .AC ? czzSettingsCentre.sharedInstance().ac_isle_host : czzSettingsCentre.sharedInstance().bt_isle_host) {
      let cookie = czzACTokenUtil.createCookie(withValue: cookieValue,
                                               for: hostURL)
      czzCookieManager.sharedInstance().setACCookie(cookie, for: hostURL)
      if !isOriginalCookieFromArchive {
        czzCookieManager.sharedInstance().archiveCookie(cookie)
      }
      DispatchQueue.main.async {
        czzBannerNotificationUtil.displayMessage("饼干已启用", position: .top)
      }
    }
    returnToCookieManager()
  }
  
  @objc func deleteAction(_ sender: Any) {
    if let cookie = originalCookie {
      let alertController = UIAlertController(title: "删除?", message: "\(cookie.domain): \(cookie.value)", preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "确认", style: .destructive, handler: { [weak self] _ in
        guard let strongSelf = self else {
          return
        }
        if strongSelf.isOriginalCookieFromArchive {
          czzCookieManager.sharedInstance().deleteArchiveCookie(cookie)
        } else {
          czzCookieManager.sharedInstance().delete(cookie)
        }
        strongSelf.returnToCookieManager()
        DispatchQueue.main.async {
          czzBannerNotificationUtil.displayMessage("这个饼干已经被删除了", position: .top)
        }
      }))
      alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
      present(alertController, animated: true, completion: nil)
    }
  }
  
  @objc func shareAction() {
    let shareViewController = CookieQRCodeShareViewController()
    if let cookieValue = cookieValue,
      let cookieJson = czzCookieManager.sharedInstance().cookieJSON(from: cookieValue) {
      shareViewController.cookieJson = cookieJson
    }
    navigationController?.pushViewController(shareViewController, animated: true)
  }

  private func returnToCookieManager() {
    guard let navigationController = navigationController else {
      dismiss(animated: true)
      return
    }
    if let manager = navigationController.viewControllers.last(where: { $0 is czzCookieManagerViewController }) {
      navigationController.popToViewController(manager, animated: true)
    } else {
      navigationController.popViewController(animated: true)
    }
  }

  private func cookieValueRow() -> UITableViewCell {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.textLabel?.text = "饼干数值"
    cell.textLabel?.font = .systemFont(ofSize: 16)
    let valueLabel = UILabel()
    valueLabel.text = "点击输入..."
    valueLabel.font = .systemFont(ofSize: 16)
    valueLabel.textColor = UIColor(red: 0.5568627451, green: 0.5568627451, blue: 0.5764705882, alpha: 1)
    valueLabel.textAlignment = .right
    valueLabel.numberOfLines = 0
    cell.detailTextLabel?.isHidden = true
    cell.contentView.addSubview(valueLabel)
    valueLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cell.textLabel!.trailingAnchor, constant: 8),
      valueLabel.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
      valueLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
    ])
    cookieValueLabel = valueLabel
    cookieValueCell = cell
    return cell
  }

  private func hostPickerRow() -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "岛"
    titleLabel.font = .systemFont(ofSize: 17)
    let picker = UIPickerView()
    picker.translatesAutoresizingMaskIntoConstraints = false
    picker.dataSource = self
    picker.delegate = self
    cell.contentView.addSubview(titleLabel)
    cell.contentView.addSubview(picker)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
      titleLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
      cell.contentView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),
      picker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      picker.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20),
      cell.contentView.trailingAnchor.constraint(equalTo: picker.trailingAnchor, constant: 20),
      cell.contentView.bottomAnchor.constraint(equalTo: picker.bottomAnchor, constant: 20),
      picker.heightAnchor.constraint(equalToConstant: 92)
    ])
    hostPickerView = picker
    return cell
  }

  private func actionRow() -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    let resetButton = borderedButton(title: "重置", background: UIColor(red: 0.937254902, green: 0.937254902, blue: 0.9568627451, alpha: 1))
    resetButton.addTarget(self, action: #selector(resetAction), for: .touchUpInside)
    let saveButton = borderedButton(title: "启用并保存", background: UIColor(red: 1, green: 0.6778507134, blue: 0.171082537, alpha: 1))
    saveButton.addTarget(self, action: #selector(addAction), for: .touchUpInside)
    cell.contentView.addSubview(resetButton)
    cell.contentView.addSubview(saveButton)
    NSLayoutConstraint.activate([
      resetButton.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 8),
      resetButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
      cell.contentView.bottomAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 8),
      saveButton.leadingAnchor.constraint(equalTo: resetButton.trailingAnchor, constant: 8),
      saveButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
      cell.contentView.trailingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 8),
      cell.contentView.bottomAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 8),
      saveButton.widthAnchor.constraint(equalTo: resetButton.widthAnchor)
    ])
    addButton = saveButton
    return cell
  }

  private func deleteRow() -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    let button = borderedButton(title: "删除饼干", background: .red)
    button.setTitleColor(.white, for: .normal)
    button.setTitleColor(UIColor(white: 1, alpha: 0.6), for: .disabled)
    button.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
    pin(button, to: cell, horizontalInset: 20)
    deleteButton = button
    return cell
  }

  private func shareRow() -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    let button = borderedButton(title: "分享饼干二维码", background: UIColor(red: 1, green: 0.6778507134, blue: 0.171082537, alpha: 1))
    button.addTarget(self, action: #selector(shareAction), for: .touchUpInside)
    pin(button, to: cell, horizontalInset: 20)
    return cell
  }

  private func borderedButton(title: String, background: UIColor) -> RoundCornerBorderedButton {
    let button = RoundCornerBorderedButton(frame: .zero)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(title, for: .normal)
    button.setTitleColor(UIColor(white: 0.3333333433, alpha: 1), for: .normal)
    button.tintColor = button.titleColor(for: .normal)
    button.layer.borderColor = button.tintColor.cgColor
    button.backgroundColor = background
    return button
  }

  private func pin(_ button: UIButton, to cell: UITableViewCell, horizontalInset: CGFloat) {
    cell.contentView.addSubview(button)
    NSLayoutConstraint.activate([
      button.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
      cell.contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 8),
      button.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: horizontalInset),
      cell.contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: horizontalInset)
    ])
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return rows[indexPath.row]
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return [90, 149, 60, 60, 60][indexPath.row]
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
