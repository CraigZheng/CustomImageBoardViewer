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

        // Do any additional setup after loading the view.
    }
    
    deinit {
        // Remove all pending UIDs.
        czzMarkerManager.sharedInstance().pendingHighlightUIDs.removeAllObjects();
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Navigation bar colours.
        if let navigationController = navigationController {
            navigationController.navigationBar.barTintColor = czzSettingsCentre.sharedInstance().barTintColour()
            navigationController.navigationBar.tintColor = czzSettingsCentre.sharedInstance().tintColour()
            navigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:navigationController.navigationBar.tintColor]
        }
        view.backgroundColor = czzSettingsCentre.sharedInstance().viewBackgroundColour()
    }
    
    // MARK: UI actions.
    @IBAction func cancelButtonAction(_ sender: UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func editButtonAction(_ sender: AnyObject) {
        tableView.setEditing(!tableView.isEditing, animated: true);
    }
    
    // MARK: Segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UITableViewCell,
            let destination = segue.destination as? MarkerColourPickerViewController,
            let indexPath = tableView.indexPath(for: cell) {
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
        }
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
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.undefinedColourCell, for: indexPath)
            UID = czzMarkerManager.sharedInstance().pendingHighlightUIDs[indexPath.row] as? String
        case .defined:
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.colourPairCell, for: indexPath)
            UID = czzMarkerManager.sharedInstance().highlightedUIDs[indexPath.row] as? String
        case .blocked:
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.blockedCell, for: indexPath)
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
    
}
