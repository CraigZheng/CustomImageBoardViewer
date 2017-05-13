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
    private var drafts: [String] = DraftManager.drafts.reversed()
    @objc var delegate: DraftSelectorTableViewControllerDelegate?
    
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
        cell.textLabel?.text = drafts[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.draftSelector(self, selectedContent: drafts[indexPath.row])
    }
}
