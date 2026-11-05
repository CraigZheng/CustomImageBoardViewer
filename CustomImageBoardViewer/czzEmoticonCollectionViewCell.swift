//
//  czzEmoticonCollectionViewCell.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 17/3/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import UIKit

class czzEmoticonCollectionViewCell: UICollectionViewCell {

    /// Insets between the icon and the cell edges, matching the original nib.
    private static let iconInset: CGFloat = 0
    private static let iconContentMode: UIView.ContentMode = .scaleAspectFit

    @objc let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = iconContentMode
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .white
        contentView.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.iconInset),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.iconInset),
            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.iconInset),
            iconView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.iconInset)
        ])
    }
}
