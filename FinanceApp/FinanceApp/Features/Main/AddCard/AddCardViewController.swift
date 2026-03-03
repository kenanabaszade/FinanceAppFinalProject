//
//  AddCardViewController.swift
//  FinanceApp
//

import UIKit
import SnapKit
import Combine

final class AddCardViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?
    private let viewModel: AddCardViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let stepLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .label
        l.numberOfLines = 0
        return l
    }()

    private let cardTypeStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = AppConstants.Sizes.cornerRadius
        return s
    }()

    private let primaryButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        return b
    }()

    private let cardPreviewContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()

    private let previewCardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = AppConstants.Dashboard.balanceCardCornerRadius
        v.clipsToBounds = true
        return v
    }()

    private let previewBrandLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = AppConstants.Colors.balanceCardText
        return l
    }()

    private let previewNumberLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.9)
        return l
    }()

    private let previewExpiryLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.8)
        return l
    }()

    private let previewTypeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = AppConstants.Colors.balanceCardText.withAlphaComponent(0.7)
        return l
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()

    private let previewGradientLayer = CAGradientLayer()

    init(viewModel: AddCardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bind()
        viewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewGradientLayer.frame = previewCardView.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyPreviewGradientColors()
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Add card"
        navigationItem.largeTitleDisplayMode = .never
        previewCardView.layer.insertSublayer(previewGradientLayer, at: 0)
        previewGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        previewGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        addSubviews()
    }

    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stepLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(cardTypeStack)
        contentView.addSubview(primaryButton)
        contentView.addSubview(cardPreviewContainer)
        cardPreviewContainer.addSubview(previewCardView)
        previewCardView.addSubview(previewBrandLabel)
        previewCardView.addSubview(previewNumberLabel)
        previewCardView.addSubview(previewExpiryLabel)
        previewCardView.addSubview(previewTypeLabel)
        view.addSubview(activityIndicator)
    }

    private func setupConstraints() {
        let inset = AppConstants.Auth.horizontalPadding
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        stepLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(inset)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(stepLabel.snp.bottom).offset(AppConstants.Spacing.small)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        cardTypeStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        primaryButton.snp.makeConstraints { make in
            make.top.equalTo(cardTypeStack.snp.bottom).offset(AppConstants.Spacing.extraLarge)
            make.leading.trailing.equalToSuperview().inset(inset)
            make.height.equalTo(AppConstants.Auth.primaryButtonHeight)
        }
        cardPreviewContainer.snp.makeConstraints { make in
            make.top.equalTo(primaryButton.snp.bottom).offset(AppConstants.Spacing.extraLarge)
            make.leading.trailing.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().offset(-AppConstants.Spacing.large)
        }
        previewCardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(AppConstants.Dashboard.balanceCardHeight)
        }
        previewBrandLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(AppConstants.Dashboard.balanceCardPadding)
        }
        previewNumberLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(AppConstants.Dashboard.balanceCardPadding)
            make.bottom.equalTo(previewExpiryLabel.snp.top).offset(-AppConstants.Spacing.small)
        }
        previewExpiryLabel.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview().inset(AppConstants.Dashboard.balanceCardPadding)
        }
        previewTypeLabel.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(AppConstants.Dashboard.balanceCardPadding)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func bind() {
        viewModel.$step
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in self?.updateUI(for: step) }
            .store(in: &cancellables)

        viewModel.$previewCard
            .receive(on: DispatchQueue.main)
            .sink { [weak self] card in self?.updatePreview(card: card) }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading { self?.activityIndicator.startAnimating() } else { self?.activityIndicator.stopAnimating() }
                self?.primaryButton.isEnabled = !loading
            }
            .store(in: &cancellables)

        viewModel.$didFinish
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in self?.coordinator?.didFinishAddCard() }
            .store(in: &cancellables)
    }

    private func updateUI(for step: AddCardStep) {
        switch step {
        case .chooseType:
            stepLabel.text = "Step 1"
            titleLabel.text = "Choose card type"
            cardTypeStack.isHidden = false
            cardPreviewContainer.isHidden = true
            primaryButton.setTitle("Continue", for: .normal)
            primaryButton.removeTarget(nil, action: nil, for: .touchUpInside)
            primaryButton.addTarget(self, action: #selector(continueFromTypeTapped), for: .touchUpInside)
            buildTypeButtons()
        case .preview:
            stepLabel.text = "Step 2"
            titleLabel.text = "Your new card"
            cardTypeStack.isHidden = true
            cardPreviewContainer.isHidden = false
            primaryButton.setTitle("Add this card", for: .normal)
            primaryButton.removeTarget(nil, action: nil, for: .touchUpInside)
            primaryButton.addTarget(self, action: #selector(addCardTapped), for: .touchUpInside)
        }
    }

    private func buildTypeButtons() {
        cardTypeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let digital = makeTypeOption(title: "Digital", subtitle: "Virtual card for online use", type: .virtual)
        let physical = makeTypeOption(title: "Physical", subtitle: "Card delivered to you", type: .physical)
        cardTypeStack.addArrangedSubview(digital)
        cardTypeStack.addArrangedSubview(physical)
        digital.isUserInteractionEnabled = true
        physical.isUserInteractionEnabled = true
        digital.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectDigital)))
        physical.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectPhysical)))
    }

    private func makeTypeOption(title: String, subtitle: String, type: CardType) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        let t = UILabel()
        t.text = title
        t.font = .systemFont(ofSize: 17, weight: .semibold)
        t.textColor = .label
        let s = UILabel()
        s.text = subtitle
        s.font = .systemFont(ofSize: 14, weight: .regular)
        s.textColor = .secondaryLabel
        container.addSubview(t)
        container.addSubview(s)
        t.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview().inset(AppConstants.Spacing.medium)
        }
        s.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.medium)
            make.top.equalTo(t.snp.bottom).offset(AppConstants.Spacing.small / 2)
            make.bottom.equalToSuperview().inset(AppConstants.Spacing.medium)
        }
        container.tag = type == .virtual ? 0 : 1
        return container
    }

    @objc private func selectDigital() {
        viewModel.selectType(.virtual)
        cardTypeStack.arrangedSubviews.forEach { v in
            v.layer.borderWidth = v.tag == 0 ? 2 : 0
            v.layer.borderColor = v.tag == 0 ? AppConstants.Colors.mandarinOrange.cgColor : nil
        }
    }

    @objc private func selectPhysical() {
        viewModel.selectType(.physical)
        cardTypeStack.arrangedSubviews.forEach { v in
            v.layer.borderWidth = v.tag == 1 ? 2 : 0
            v.layer.borderColor = v.tag == 1 ? AppConstants.Colors.mandarinOrange.cgColor : nil
        }
    }

    @objc private func continueFromTypeTapped() {
        viewModel.continueFromType()
    }

    @objc private func addCardTapped() {
        Task { await viewModel.saveCard() }
    }

    private func updatePreview(card: AddCardPreview?) {
        guard let card = card else {
            cardPreviewContainer.isHidden = true
            return
        }
        cardPreviewContainer.isHidden = false
        previewBrandLabel.text = card.brand == .visa ? "Visa" : "Mastercard"
        previewNumberLabel.text = card.maskedNumber
        previewExpiryLabel.text = "Expires \(card.expiryDate)"
        previewTypeLabel.text = card.type == .virtual ? "Digital" : "Physical"
        applyPreviewGradientColors()
    }

    private func applyPreviewGradientColors() {
        let isLight = traitCollection.userInterfaceStyle == .light
        if isLight {
            previewGradientLayer.colors = [
                UIColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 1).cgColor,
                AppConstants.Colors.mandarinOrange.cgColor,
                AppConstants.Colors.mandarinDeep.cgColor
            ]
        } else {
            previewGradientLayer.colors = [
                AppConstants.Colors.mandarinLight.resolvedColor(with: traitCollection).cgColor,
                AppConstants.Colors.mandarinOrange.cgColor,
                AppConstants.Colors.mandarinDeep.resolvedColor(with: traitCollection).cgColor
            ]
        }
    }
}
