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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drafts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.draft, for: indexPath)
        cell.textLabel?.text = drafts[indexPath.row].0
        cell.detailTextLabel?.text = dateFormatter.string(from: drafts[indexPath.row].1)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.draftSelector(self, selectedContent: drafts[indexPath.row].0)
    }
}
