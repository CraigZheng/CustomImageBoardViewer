//
//  AddMarkerViewController.swift
//  CustomImageBoardViewer
//
//  Created by Craig on 19/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

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

extension AddMarkerViewController {
    
}
