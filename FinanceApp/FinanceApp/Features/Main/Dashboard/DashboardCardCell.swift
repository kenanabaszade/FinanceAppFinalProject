//
//  DashboardCardCell.swift
//  FinanceApp
//
//  Created by Macbook on 2.03.26.
//

import UIKit
import SnapKit

struct DashboardCardData {
    let card: Card
    let balance: Double
    let currency: String 
    let isPrimary: Bool
}

final class DashboardCardCell: UICollectionViewCell {
    static let reuseId = "DashboardCardCell"

    private let shadowContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private let cardFaceView = CardFaceView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        shadowContainer.layer.shadowRadius = 14
        shadowContainer.layer.cornerRadius = AppConstants.Dashboard.cardCellCornerRadius

        contentView.addSubview(shadowContainer)
        shadowContainer.addSubview(cardFaceView)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyShadow()
        }
    }

    private func setupConstraints() {
        let h = AppConstants.Auth.horizontalPadding

        shadowContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(h)
        }
        cardFaceView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with data: DashboardCardData) {
        cardFaceView.configure(
            card: data.card,
            balance: data.balance,
            currency: data.currency,
            showBalance: true,
            isPrimary: data.isPrimary
        )
        applyShadow()
    }

    private func applyShadow() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = isDark ? 0.45 : 0.18
    }
}
