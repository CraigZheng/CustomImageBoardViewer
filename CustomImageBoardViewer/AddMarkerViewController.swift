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
}

private struct CellIdentifier {
    static let undefinedColourCell = "undefinedColourCell"
    static let colourPairCell = "uidColourPairCell"
}

class AddMarkerViewController: UITableViewController {
    
    // MARK: Life cycle.

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension AddMarkerViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return czzMarkerManager.sharedInstance().pendingHighlightUIDs.count == 0 ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .pending: return czzMarkerManager.sharedInstance().pendingHighlightUIDs.count
        case .defined: return czzMarkerManager.sharedInstance().highlightedUIDs.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let UID: String?
        switch Section(rawValue: indexPath.section)! {
        case .pending:
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.undefinedColourCell, for: indexPath)
            UID = czzMarkerManager.sharedInstance().pendingHighlightUIDs[indexPath.row] as? String
        case .defined: cell =
            tableView.dequeueReusableCell(withIdentifier: CellIdentifier.undefinedColourCell, for: indexPath)
            UID = czzMarkerManager.sharedInstance().highlightedUIDs[indexPath.row] as? String
        }
        cell.detailTextLabel?.text = "请选择颜色..."
        if let UID = UID {
            cell.textLabel?.text = UID
            if let cell = cell as? UIDColourPairCellTableViewCell,
                let colour = czzMarkerManager.sharedInstance().highlightColour(forUID: UID) {
                // Assign an image as the template for cell.imageView.
                cell.imageView?.image = UIImage.init(named: "flag")?.withRenderingMode(.alwaysTemplate)
                cell.imageView?.tintColor = colour
            }
        }
        return cell
    }
    
}
