//
//  DraftSelectorTableViewController.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 13/5/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import UIKit

@objc protocol DraftSelectorTableViewControllerDelegate {
    func draftSelector(_ viewController: DraftSelectorTableViewController, selectedContent: String?)
}

class DraftSelectorTableViewController: UITableViewController {
    @objc var delegate: DraftSelectorTableViewControllerDelegate?
    
    private var drafts: [(String, Date)] = DraftManager.drafts.reversed()
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm ddMMM"
        return dateFormatter
    }()
    
    private struct CellIdentifier {
        static let draft = "draftCell"
        static let clear = "clearCell"
    }
    private enum Section: Int {
        case drafts = 0
        case clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .drafts: return drafts.count
        case .clear: return drafts.count > 0 ? 1 : 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .drafts: return "草稿"
        case .clear: return " "
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .drafts:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.draft, for: indexPath)
            cell.textLabel?.text = drafts[indexPath.row].0
            cell.detailTextLabel?.text = dateFormatter.string(from: drafts[indexPath.row].1)
            return cell
        case .clear: return tableView.dequeueReusableCell(withIdentifier: CellIdentifier.clear, for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .drafts:
            delegate?.draftSelector(self, selectedContent: drafts[indexPath.row].0)
        case .clear:
            drafts = []
            DraftManager.clear()
            tableView.reloadData()
        }
    }
}
