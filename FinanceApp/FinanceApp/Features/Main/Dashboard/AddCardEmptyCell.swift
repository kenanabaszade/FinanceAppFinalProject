//
//  AddCardEmptyCell.swift
//  FinanceApp
//
//  Created by Macbook on 2.03.26.
//

import UIKit
import SnapKit

final class AddCardEmptyCell: UICollectionViewCell {
    static let reuseId = "AddCardEmptyCell"
    
    var onAddTapped: (() -> Void)?
    
    private let shadowContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    
    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = AppConstants.Dashboard.cardCellCornerRadius
        v.layer.borderWidth = 1.5
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
        contentView.addSubview(shadowContainer)
        shadowContainer.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(addButton)
        let h = AppConstants.Auth.horizontalPadding
        shadowContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(h)
        }
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-AppConstants.Spacing.extraLarge)
            make.leading.greaterThanOrEqualToSuperview().offset(h)
            make.trailing.lessThanOrEqualToSuperview().offset(-h)
        }
        addButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(AppConstants.Sizes.addCardButtonMinWidth)
            make.height.equalTo(AppConstants.Sizes.buttonHeight)
        }
        applyCardAppearance()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyCardAppearance()
        }
    }
    
    private func applyCardAppearance() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        shadowContainer.layer.shadowRadius = 14
        shadowContainer.layer.cornerRadius = AppConstants.Dashboard.cardCellCornerRadius
        if isDark {
            container.backgroundColor = .black
            container.layer.borderColor = UIColor(white: 0.25, alpha: 1).cgColor
            shadowContainer.layer.shadowColor = UIColor.black.cgColor
            shadowContainer.layer.shadowOpacity = 0.45
            titleLabel.textColor = .white
        } else {
            container.backgroundColor = .white
            container.layer.borderColor = UIColor.black.cgColor
            shadowContainer.layer.shadowColor = UIColor.black.cgColor
            shadowContainer.layer.shadowOpacity = 0.18
            titleLabel.textColor = .black
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
