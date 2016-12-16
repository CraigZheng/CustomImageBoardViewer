//
//  czzCacheCleanerTableViewController.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 14/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class czzCacheCleanerTableViewController: UITableViewController {

    @IBOutlet weak var fileDetailsLabel: UILabel!
    @IBOutlet weak var imageDetailsLabel: UILabel!
    @IBOutlet weak var expiryDetailsLabel: UILabel! {
        didSet {
            if let periodTitles = czzSettingsCentre.periodSettingTitle() as? [String] {
                expiryDetailsLabel.text = periodTitles[czzSettingsCentre.sharedInstance().cacheExpiry.rawValue]
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let expiredFiles = czzCacheCleaner.sharedInstance().expiredFiles(inFolder: czzAppDelegate.threadCacheFolder()).flatMap({ $0 })
        let expiredImages = czzCacheCleaner.sharedInstance().expiredFiles(inFolder: czzAppDelegate.imageFolder()).flatMap({ $0 })
        fileDetailsLabel.text = "\(expiredFiles.count) files"
        imageDetailsLabel.text = "\(expiredImages.count) images"
    }

    // MARK: - Segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? czzSelectionSelectorViewController {
            destinationViewController.selections = czzSettingsCentre.periodSettingTitle() as? [String]
            destinationViewController.preSelectedIndex = czzSettingsCentre.sharedInstance().cacheExpiry.rawValue
            destinationViewController.delegate = self
        }
    }
    
    // MARK: - UI actions.
    
    @IBAction func cancelAction(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
}

extension czzCacheCleanerTableViewController: czzSelectionSelectorViewControllerProtocol {
    
    func selectorViewController(_ viewController: czzSelectionSelectorViewController!, selectedIndex index: Int) {
        czzSettingsCentre.sharedInstance().cacheExpiry = CacheExpiry(rawValue: index)
        if let periodTitles = czzSettingsCentre.periodSettingTitle() as? [String] {
            expiryDetailsLabel.text = periodTitles[czzSettingsCentre.sharedInstance().cacheExpiry.rawValue]
        }
        // TODO: reload.
    }
    
}
