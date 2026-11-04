//
//  UIDColourPairCellTableViewCell.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

class UIDColourPairCellTableViewCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    private let nicknameLabel = UILabel()
    private let showsDetail: Bool

    override var imageView: UIImageView? { return iconView }

    override var textLabel: UILabel? { return titleLabel }

    override var detailTextLabel: UILabel? { return showsDetail ? nicknameLabel : nil }

    init(reuseIdentifier: String, showsDetail: Bool) {
        self.showsDetail = showsDetail
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator

        let brown = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = brown

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleToFill
        iconView.image = UIImage(named: showsDetail ? "flag" : "poison")

        contentView.addSubview(titleLabel)
        contentView.addSubview(iconView)

        var constraints = [
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor)
        ]
        if showsDetail {
            nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
            nicknameLabel.font = .systemFont(ofSize: 15)
            nicknameLabel.textColor = UIColor(red: 0.7137254902, green: 0.3058823529, blue: 0.01568627451, alpha: 1)
            nicknameLabel.textAlignment = .right
            nicknameLabel.numberOfLines = 2
            contentView.addSubview(nicknameLabel)
            constraints.append(contentsOf: [
                nicknameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
                nicknameLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
                iconView.leadingAnchor.constraint(equalTo: nicknameLabel.trailingAnchor, constant: 8)
            ])
        }
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder: NSCoder) {
        showsDetail = false
        super.init(coder: coder)
    }
}
