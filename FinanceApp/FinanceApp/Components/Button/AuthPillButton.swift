//
//  AuthPillButton.swift
//  FinanceApp
//
//  Created by Macbook on 06.02.26.
//

import UIKit
import SnapKit

class AuthPillButton: UIButton {

    enum Style {
        case filledDark
        case filledPrimary
        case outlineLight
    }

    private let style: Style

    init(style: Style, title: String) {
        self.style = style
        super.init(frame: .zero)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = title
            config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
            configuration = config
        } else {
            setTitle(title, for: .normal)
            contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        }
        clipsToBounds = false
        applyStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2

        if style == .filledPrimary {
            layer.shadowColor = AppConstants.Colors.mandarinOrange
                .resolvedColor(with: traitCollection).cgColor
            layer.shadowOpacity = 0.45
            layer.shadowOffset = CGSize(width: 0, height: 6)
            layer.shadowRadius = 16
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            resolveCGColors()
        }
    }

    private func resolveCGColors() {
        switch style {
        case .filledPrimary:
            layer.shadowColor = AppConstants.Colors.mandarinOrange
                .resolvedColor(with: traitCollection).cgColor
        case .outlineLight:
            layer.borderColor = AppConstants.Colors.authTitle.withAlphaComponent(0.35)
                .resolvedColor(with: traitCollection).cgColor
        case .filledDark:
            break
        }
    }

    private func applyStyle() {
        switch style {
        case .filledDark:
            backgroundColor = AppConstants.Colors.authBackButtonBackground
            setTitleColor(AppConstants.Colors.authTitle, for: .normal)
            if #available(iOS 15.0, *) {
                var config = configuration ?? .plain()
                config.baseForegroundColor = AppConstants.Colors.authTitle
                configuration = config
            }

        case .filledPrimary:
            backgroundColor = AppConstants.Colors.mandarinOrange
            setTitleColor(.white, for: .normal)
            if #available(iOS 15.0, *) {
                var config = configuration ?? .plain()
                config.baseForegroundColor = .white
                configuration = config
            }

        case .outlineLight:
            backgroundColor = .clear
            layer.borderWidth = 1.5
            layer.borderColor = AppConstants.Colors.authTitle.withAlphaComponent(0.35).cgColor
            setTitleColor(AppConstants.Colors.authTitle, for: .normal)
            if #available(iOS 15.0, *) {
                var config = configuration ?? .plain()
                config.baseForegroundColor = AppConstants.Colors.authTitle
                configuration = config
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.7 : 1.0
        }
    }
}
