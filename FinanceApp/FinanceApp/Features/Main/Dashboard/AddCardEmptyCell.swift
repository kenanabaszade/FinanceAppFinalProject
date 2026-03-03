//
//  AddCardEmptyCell.swift
//  FinanceApp
//

import UIKit
import SnapKit

final class AddCardEmptyCell: UICollectionViewCell {
    static let reuseId = "AddCardEmptyCell"

    var onAddTapped: (() -> Void)?

    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = AppConstants.Dashboard.balanceCardCornerRadius
        v.layer.borderWidth = 1
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = AppConstants.Colors.authSubtitle
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private lazy var addButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        b.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(addButton)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-AppConstants.Spacing.extraLarge)
            make.leading.greaterThanOrEqualToSuperview().offset(AppConstants.Spacing.large)
            make.trailing.lessThanOrEqualToSuperview().offset(-AppConstants.Spacing.large)
        }
        addButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(AppConstants.Sizes.addCardButtonMinWidth)
            make.height.equalTo(AppConstants.Sizes.buttonHeight)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            container.layer.borderColor = AppConstants.Colors.authInputBorder
                .resolvedColor(with: traitCollection).cgColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if container.layer.borderColor == nil {
            container.layer.borderColor = AppConstants.Colors.authInputBorder
                .resolvedColor(with: traitCollection).cgColor
        }
    }

    func configure(isFirstCard: Bool) {
        titleLabel.text = isFirstCard ? "Add your first card" : "Add card"
        addButton.setTitle("Add card", for: .normal)
    }

    @objc private func addTapped() {
        onAddTapped?()
    }
}
