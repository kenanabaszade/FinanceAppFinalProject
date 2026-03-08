//
//  CardDetailViewController.swift
//  FinanceApp
//
//  Created by Macbook on 24.02.26.
//

import UIKit
import SnapKit

final class CardDetailViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    
    private let card: Card
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    private let cardGradientLayer = CAGradientLayer()
    
    private lazy var backButton: UIButton = {
        let b = AppConstants.makeBackButton()
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()
    
    private let screenTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Card Details"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()
    
    private let cardContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = AppConstants.Dashboard.cardCellCornerRadius
        v.clipsToBounds = true
        return v
    }()
    
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
    
    private let cardTypeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.7)
        return l
    }()
    
    private let cardNumberLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        l.textColor = AppConstants.Colors.balanceCardText
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()
    
    private let expiryTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "EXPIRES"
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.5)
        return l
    }()
    
    private let expiryValueLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.85)
        return l
    }()
    
    private let cvvTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "CVV"
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.5)
        return l
    }()
    
    private let cvvValueLabel: UILabel = {
        let l = UILabel()
        l.text = "•••"
        l.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.85)
        return l
    }()
    
    private let detailsCard: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = AppConstants.Dashboard.balanceCardCornerRadius
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 10
        return v
    }()
    
    private lazy var removeCardButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Remove Card", for: .normal)
        b.setTitleColor(.systemRed, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.addTarget(self, action: #selector(removeCardTapped), for: .touchUpInside)
        return b
    }()
    
    private let detailsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        return s
    }()
    
    init(card: Card, authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.card = card
        self.authService = authService
        self.firestoreService = firestoreService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardGradientLayer.frame = cardContainer.bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyGradient()
            detailsCard.layer.shadowColor = UIColor.black.withAlphaComponent(0.04)
                .resolvedColor(with: traitCollection).cgColor
        }
    }
    
    private func setupUI() {
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        applyGradient()
        cardContainer.layer.insertSublayer(cardGradientLayer, at: 0)
        
        configureCard()
        buildDetailsRows()
        addSubviews()
    }
    
    private func applyGradient() {
        if card.type == .physical {
            cardGradientLayer.colors = [
                AppConstants.Colors.mandarinLight.resolvedColor(with: traitCollection).cgColor,
                AppConstants.Colors.mandarinOrange.resolvedColor(with: traitCollection).cgColor,
                AppConstants.Colors.mandarinDeep.resolvedColor(with: traitCollection).cgColor
            ]
        } else {
            cardGradientLayer.colors = [
                AppConstants.Colors.dashboardCardDark.resolvedColor(with: traitCollection).cgColor,
                AppConstants.Colors.dashboardCardDark.resolvedColor(with: traitCollection).cgColor
            ]
        }
        cardGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        cardGradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }
    
    private func configureCard() {
        cardTypeLabel.text = card.type == .physical ? "PHYSICAL CARD" : "VIRTUAL CARD"
        
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
    }
    
    private func buildDetailsRows() {
        let rows: [(String, String)] = [
            ("Card Name", card.name),
            ("Card Type", card.type == .physical ? "Physical" : "Virtual"),
            ("Last 4 Digits", card.lastFourDigits),
            ("Currency", card.currency ?? "AZN"),
            ("Expires", card.expiryDate ?? "—")
        ]
        
        for (index, row) in rows.enumerated() {
            let rowView = makeDetailRow(title: row.0, value: row.1)
            detailsStack.addArrangedSubview(rowView)
            if index < rows.count - 1 {
                let separator = UIView()
                separator.backgroundColor = AppConstants.Colors.authInputBorder
                separator.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                }
                detailsStack.addArrangedSubview(separator)
            }
        }
    }
    
    private func addSubviews() {
        view.addSubview(backButton)
        view.addSubview(screenTitleLabel)
        view.addSubview(cardContainer)
        view.addSubview(removeCardButton)
        cardContainer.addSubview(brandLogoCircle)
        brandLogoCircle.addSubview(brandLogoIcon)
        cardContainer.addSubview(brandNameLabel)
        cardContainer.addSubview(cardTypeLabel)
        cardContainer.addSubview(cardNumberLabel)
        cardContainer.addSubview(expiryTitleLabel)
        cardContainer.addSubview(expiryValueLabel)
        cardContainer.addSubview(cvvTitleLabel)
        cardContainer.addSubview(cvvValueLabel)
        view.addSubview(detailsCard)
        detailsCard.addSubview(detailsStack)
    }
    
    private func setupConstraints() {
        let h = AppConstants.Auth.horizontalPadding
        let pad = AppConstants.Dashboard.balanceCardPadding
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppConstants.Spacing.small)
            make.leading.equalToSuperview().inset(h)
            make.width.height.equalTo(AppConstants.Auth.iconButtonSize)
        }
        screenTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.centerX.equalToSuperview()
        }
        
        cardContainer.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(200)
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
        cardTypeLabel.snp.makeConstraints { make in
            make.leading.equalTo(brandNameLabel)
            make.top.equalTo(brandNameLabel.snp.bottom).offset(1)
        }
        cardNumberLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(AppConstants.Spacing.small)
        }
        expiryTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(pad)
            make.bottom.equalTo(expiryValueLabel.snp.top).offset(-2)
        }
        expiryValueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(pad)
            make.bottom.equalToSuperview().inset(pad)
        }
        cvvTitleLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(pad)
            make.bottom.equalTo(cvvValueLabel.snp.top).offset(-2)
        }
        cvvValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(pad)
            make.bottom.equalToSuperview().inset(pad)
        }
        
        detailsCard.snp.makeConstraints { make in
            make.top.equalTo(cardContainer.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(h)
        }
        detailsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppConstants.Spacing.medium)
        }
        
        removeCardButton.snp.makeConstraints { make in
            make.top.equalTo(detailsCard.snp.bottom).offset(AppConstants.Spacing.large)
            make.centerX.equalToSuperview()
        }
    }
    
    private func makeDetailRow(title: String, value: String) -> UIView {
        let row = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = AppConstants.Colors.authSubtitle
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = AppConstants.Colors.authTitle
        valueLabel.textAlignment = .right
        
        row.addSubview(titleLabel)
        row.addSubview(valueLabel)
        
        row.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.Dashboard.transactionRowHeight * 0.7)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(AppConstants.Spacing.small)
        }
        
        return row
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func removeCardTapped() {
        let alert = UIAlertController(
            title: "Remove Card",
            message: "Are you sure you want to remove this card? The linked account and balance will remain.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.performRemoveCard()
        })
        present(alert, animated: true)
    }
    
    private func performRemoveCard() {
        guard let userId = authService.currentUserId() else { return }
        Task {
            do {
                try await firestoreService.deleteCard(cardId: card.id, userId: userId)
                await MainActor.run {
                    navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    let errAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    errAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(errAlert, animated: true)
                }
            }
        }
    }
}
