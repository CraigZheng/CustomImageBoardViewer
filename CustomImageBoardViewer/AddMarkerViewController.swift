//
//  AddMarkerViewController.swift
//  CustomImageBoardViewer
//
//  Created by Craig on 19/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

private enum Section: Int {
    case pending = 0
    case defined = 1
    case blocked = 2
}

private struct CellIdentifier {
    static let undefinedColourCell = "undefinedColourCell"
    static let colourPairCell = "uidColourPairCell"
    static let blockedCell = "blockedCell"
}

class AddMarkerViewController: UITableViewController {
    
    // MARK: Life cycle.

    override func viewDidLoad() {
        super.viewDidLoad()
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 10))
        footer.backgroundColor = .clear
        tableView.tableFooterView = footer
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonAction))
    }
    
    deinit {
        // Remove all pending UIDs.
        czzMarkerManager.sharedInstance().pendingHighlightUIDs.removeAllObjects();
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = czzSettingsCentre.sharedInstance().viewBackgroundColour()
    }
    
    // MARK: UI actions.
    @objc func cancelButtonAction() {
        _ = navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func editButtonAction() {
        tableView.setEditing(!tableView.isEditing, animated: true);
    }
}

extension AddMarkerViewController: MarkerColourPickerViewControllerProtocol {
    internal func didFinishSelecting(colour: UIColor?, for UID: String?) {
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension AddMarkerViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .pending: return czzMarkerManager.sharedInstance().pendingHighlightUIDs.count == 0 ? nil : "待定"
        case .defined: return czzMarkerManager.sharedInstance().highlightedUIDs.count == 0 ? nil : "标记"
        case .blocked: return czzMarkerManager.sharedInstance().blockedUIDs.count == 0 ? nil : "屏蔽"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .pending: return czzMarkerManager.sharedInstance().pendingHighlightUIDs.count
        case .defined: return czzMarkerManager.sharedInstance().highlightedUIDs.count
        case .blocked: return czzMarkerManager.sharedInstance().blockedUIDs.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let UID: String?
        switch Section(rawValue: indexPath.section)! {
        case .pending:
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.undefinedColourCell) ?? {
                let created = UITableViewCell(style: .value1, reuseIdentifier: CellIdentifier.undefinedColourCell)
                created.accessoryType = .disclosureIndicator
                created.textLabel?.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
                created.detailTextLabel?.textColor = UIColor(red: 0.7137254902, green: 0.3058823529, blue: 0.01568627451, alpha: 1)
                return created
            }()
            UID = czzMarkerManager.sharedInstance().pendingHighlightUIDs[indexPath.row] as? String
        case .defined:
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.colourPairCell) ?? UIDColourPairCellTableViewCell(reuseIdentifier: CellIdentifier.colourPairCell, showsDetail: true)
            UID = czzMarkerManager.sharedInstance().highlightedUIDs[indexPath.row] as? String
        case .blocked:
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.blockedCell) ?? UIDColourPairCellTableViewCell(reuseIdentifier: CellIdentifier.blockedCell, showsDetail: false)
            UID = czzMarkerManager.sharedInstance().blockedUIDs[indexPath.row] as? String
        }
        cell.detailTextLabel?.text = "请选择..."
        cell.contentView.backgroundColor = czzSettingsCentre.sharedInstance().viewBackgroundColour()
        cell.backgroundColor = cell.contentView.backgroundColor
        if let UID = UID {
            cell.textLabel?.text = UID
            if let cell = cell as? UIDColourPairCellTableViewCell {
                // Assign an image as the template for cell.imageView.
                cell.imageView?.image = UIImage.init(named: "flag")?.withRenderingMode(.alwaysTemplate)
                cell.imageView?.tintColor = czzMarkerManager.sharedInstance().highlightColour(forUID: UID) ?? .lightGray
                cell.detailTextLabel?.text = czzMarkerManager.sharedInstance().nickname(forUID: UID)
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let UID: String?
        switch Section(rawValue: indexPath.section)! {
        case .pending:
            UID = czzMarkerManager.sharedInstance().pendingHighlightUIDs[indexPath.row] as? String
        case .defined:
            UID = czzMarkerManager.sharedInstance().highlightedUIDs[indexPath.row] as? String
        case .blocked:
            UID = czzMarkerManager.sharedInstance().blockedUIDs[indexPath.row] as? String
        }
        if let UID = UID {
            // Remove it from every czzMarkerManager sets, then save.
            czzMarkerManager.sharedInstance().pendingHighlightUIDs.remove(UID)
            czzMarkerManager.sharedInstance().highlightedUIDs.remove(UID)
            czzMarkerManager.sharedInstance().blockedUIDs.remove(UID)
            czzMarkerManager.sharedInstance().save()
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = MarkerColourPickerViewController()
        let UID: String?
        var colour: UIColor?
        var nickname: String?
        switch Section(rawValue: indexPath.section)! {
        case .pending:
            UID = czzMarkerManager.sharedInstance().pendingHighlightUIDs[indexPath.row] as? String
            colour = czzMarkerManager.sharedInstance().highlightColour(forUID: UID ?? "")
        case .defined:
            UID = czzMarkerManager.sharedInstance().highlightedUIDs[indexPath.row] as? String
            colour = czzMarkerManager.sharedInstance().highlightColour(forUID: UID ?? "")
            nickname = czzMarkerManager.sharedInstance().nickname(forUID: UID ?? "")
        case .blocked:
            UID = czzMarkerManager.sharedInstance().blockedUIDs[indexPath.row] as? String
        }
        destination.selectedColour = colour
        destination.nickname = nickname
        destination.UID = UID
        destination.delegate = self
        destination.modalPresentationStyle = .overFullScreen
        present(destination, animated: true)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
