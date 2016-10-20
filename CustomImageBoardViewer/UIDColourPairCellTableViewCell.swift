//
//  UIDColourPairCellTableViewCell.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class UIDColourPairCellTableViewCell: UITableViewCell {
    @IBOutlet private weak var _textLabel: UILabel!
    @IBOutlet private weak var _imageView: UIImageView!
    
    override var imageView: UIImageView? { return _imageView }
    
    override var textLabel: UILabel? { return _textLabel }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
