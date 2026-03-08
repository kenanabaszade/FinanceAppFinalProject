//
//  CardFaceView.swift
//  FinanceApp
//
//  Created by Macbook on 2.03.26.
//

import UIKit
import SnapKit

final class CardFaceView: UIView {
    
    var card: Card?
    var showBalance: Bool = true
    var isPrimaryStyle: Bool = true
    
    private let cardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = AppConstants.Dashboard.cardCellCornerRadius
        v.clipsToBounds = true
        v.layer.borderWidth = 1
        return v
    }()
    
    private let cardGradientLayer = CAGradientLayer()
    
    private let brandLogoCircle: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.2)
        v.layer.cornerRadius = AppConstants.Dashboard.brandCircleCornerRadius
        return v
    }()
    
    private let brandLogoIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let iv = UIImageView(image: UIImage(systemName: "building.columns", withConfiguration: config))
        iv.tintColor = AppConstants.Colors.balanceCardText
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let brandNameLabel: UILabel = {
        let l = UILabel()
        l.text = "Mandarin"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = AppConstants.Colors.balanceCardText
        return l
    }()
    
    private let premiumLabel: UILabel = {
        let l = UILabel()
        l.text = "PREMIUM"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.7)
        return l
    }()
    
    private let networkBrandLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = AppConstants.Colors.balanceCardText
        return l
    }()
    
    private let totalBalanceLabel: UILabel = {
        let l = UILabel()
        l.text = "TOTAL BALANCE"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.7)
        return l
    }()
    
    private let balanceAmountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.textColor = AppConstants.Colors.balanceCardText
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.6
        return l
    }()
    
    private let cardNumberLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: AppConstants.Dashboard.cardNumberFontSize, weight: .semibold)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.75)
        return l
    }()
    
    private let expiryTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "EXPIRES"
        l.font = .systemFont(ofSize: 9, weight: .medium)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.5)
        return l
    }()
    
    private let expiryValueLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: AppConstants.Dashboard.expiryFontSize, weight: .semibold)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.75)
        return l
    }()
    
    private let blurOverlay: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let v = UIVisualEffectView(effect: blur)
        v.layer.cornerRadius = AppConstants.Dashboard.cardCellCornerRadius
        v.clipsToBounds = true
        v.isUserInteractionEnabled = true
        v.isHidden = true
        return v
    }()
    
    private let deactiveBadge: UILabel = {
        let l = UILabel()
        l.text = "DEACTIVE"
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        cardGradientLayer.cornerRadius = AppConstants.Dashboard.cardCellCornerRadius
        cardView.layer.insertSublayer(cardGradientLayer, at: 0)
        cardView.layer.borderWidth = 1.5
        addSubview(cardView)
        cardView.addSubview(brandLogoCircle)
        brandLogoCircle.addSubview(brandLogoIcon)
        cardView.addSubview(brandNameLabel)
        cardView.addSubview(premiumLabel)
        cardView.addSubview(networkBrandLabel)
        cardView.addSubview(totalBalanceLabel)
        cardView.addSubview(balanceAmountLabel)
        cardView.addSubview(cardNumberLabel)
        cardView.addSubview(expiryTitleLabel)
        cardView.addSubview(expiryValueLabel)
        cardView.addSubview(blurOverlay)
        cardView.addSubview(deactiveBadge)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cardGradientLayer.frame = cardView.bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyCardAppearance()
            applyCardTextColors()
        }
    }
    
    func configure(card: Card, balance: Double? = nil, currency: String? = nil, showBalance: Bool = true, isPrimary: Bool = true) {
        self.card = card
        self.showBalance = showBalance
        self.isPrimaryStyle = isPrimary
        
        let cur = currency ?? card.currency ?? "AZN"
        let symbol: String
        switch cur {
        case "AZN": symbol = "₼"
        case "USD": symbol = "$"
        default: symbol = cur
        }
        if showBalance, let bal = balance {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            balanceAmountLabel.text = symbol + " " + (formatter.string(from: NSNumber(value: bal)) ?? "0.00")
        } else {
            balanceAmountLabel.text = "—"
        }
        totalBalanceLabel.isHidden = !showBalance
        balanceAmountLabel.isHidden = !showBalance
        
        if let full = card.fullNumber, full.count >= 16 {
            let spaced = stride(from: 0, to: full.count, by: 4).map { i in
                let start = full.index(full.startIndex, offsetBy: i)
                let end = full.index(start, offsetBy: min(4, full.count - i))
                return String(full[start..<end])
            }.joined(separator: "  ")
            cardNumberLabel.text = spaced
        } else {
            cardNumberLabel.text = "••••  ••••  ••••  " + card.lastFourDigits
        }
        expiryValueLabel.text = card.expiryDate ?? "—/—"
        
        let brand = card.brand ?? Self.brandFromNumber(card.fullNumber ?? "")
        networkBrandLabel.text = brand == .visa ? "Visa" : (brand == .mastercard ? "Mastercard" : nil)
        networkBrandLabel.isHidden = (brand != .visa && brand != .mastercard)
        
        let isDeactive = card.isBlocked
        blurOverlay.isHidden = !isDeactive
        deactiveBadge.isHidden = !isDeactive
        
        cardGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        cardGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        applyCardAppearance()
        applyCardTextColors()
    }
    
    private func setupConstraints() {
        let pad = AppConstants.Dashboard.balanceCardPadding
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        brandLogoCircle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(pad)
            make.leading.equalToSuperview().offset(pad)
            make.width.height.equalTo(AppConstants.Dashboard.brandCircleSize)
        }
        brandLogoIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(AppConstants.Dashboard.brandCircleSize / 2)
        }
        brandNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(brandLogoCircle.snp.trailing).offset(AppConstants.Spacing.small + 2)
            make.top.equalTo(brandLogoCircle).offset(-1)
        }
        premiumLabel.snp.makeConstraints { make in
            make.leading.equalTo(brandNameLabel)
            make.top.equalTo(brandNameLabel.snp.bottom).offset(1)
        }
        networkBrandLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(pad)
        }
        totalBalanceLabel.snp.makeConstraints { make in
            make.top.equalTo(brandLogoCircle.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.equalToSuperview().offset(pad)
        }
        balanceAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(totalBalanceLabel.snp.bottom).offset(AppConstants.Spacing.small - 2)
            make.leading.equalToSuperview().offset(pad)
            make.trailing.lessThanOrEqualToSuperview().inset(pad)
        }
        cardNumberLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(pad)
            make.bottom.equalToSuperview().inset(pad)
        }
        expiryTitleLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(pad)
            make.bottom.equalTo(expiryValueLabel.snp.top).offset(-2)
        }
        expiryValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(pad)
            make.bottom.equalToSuperview().inset(pad)
        }
        blurOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        deactiveBadge.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(36)
            make.width.greaterThanOrEqualTo(120)
        }
    }
    
    private func applyCardAppearance() {
        guard let card = card else { return }
        let isDark = traitCollection.userInterfaceStyle == .dark
        if isDark {
            let darkBg = UIColor.black
            cardGradientLayer.colors = [darkBg.cgColor, darkBg.cgColor]
            cardView.layer.borderColor = UIColor(white: 0.25, alpha: 1).cgColor
        } else {
            let whiteBg = UIColor.white
            cardGradientLayer.colors = [whiteBg.cgColor, whiteBg.cgColor]
            cardView.layer.borderColor = UIColor.black.cgColor
        }
    }
    
    private static func brandFromNumber(_ fullNumber: String) -> CardBrand? {
        let digits = fullNumber.prefix(4)
        guard !digits.isEmpty else { return nil }
        if digits.hasPrefix("4") { return .visa }
        if digits.hasPrefix("51") || digits.hasPrefix("52") || digits.hasPrefix("53") || digits.hasPrefix("54") || digits.hasPrefix("55") { return .mastercard }
        if digits.count >= 4 {
            let n = Int(digits) ?? 0
            if n >= 2221 && n <= 2720 { return .mastercard }
        }
        return nil
    }
    
    private func applyCardTextColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let text = isDark ? UIColor.white : UIColor.black
        brandLogoCircle.backgroundColor = text.withAlphaComponent(0.2)
        brandNameLabel.textColor = text
        networkBrandLabel.textColor = text
        premiumLabel.textColor = text.withAlphaComponent(0.7)
        totalBalanceLabel.textColor = text.withAlphaComponent(0.7)
        balanceAmountLabel.textColor = text
        cardNumberLabel.textColor = text.withAlphaComponent(0.75)
        expiryTitleLabel.textColor = text.withAlphaComponent(0.5)
        expiryValueLabel.textColor = text.withAlphaComponent(0.75)
        brandLogoIcon.tintColor = text
        deactiveBadge.textColor = .white
        deactiveBadge.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
}
