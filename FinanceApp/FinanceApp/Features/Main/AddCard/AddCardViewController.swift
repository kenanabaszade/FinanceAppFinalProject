//
//  AddCardViewController.swift
//  FinanceApp
//

import UIKit
import SnapKit
import Combine

private enum AddCardLayout {
    static let horizontalInset: CGFloat = 20
    static let stackSpacing: CGFloat = 14
    static let sectionSpacing: CGFloat = 18
    static let typeOptionSpacing: CGFloat = 8
    static let typeOptionPadding: CGFloat = 14
    static let buttonHeight: CGFloat = 50
    static let previewCardHeight: CGFloat = 200
    static let previewCardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 14
}

final class AddCardViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    private let viewModel: AddCardViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.keyboardDismissMode = .onDrag
        return s
    }()
    
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = AddCardLayout.stackSpacing
        s.alignment = .fill
        return s
    }()
    
    private let stepLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .secondaryLabel
        l.text = "STEP 1"
        return l
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .label
        l.numberOfLines = 1
        return l
    }()
    
    private let cardTypeStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = AddCardLayout.typeOptionSpacing
        return s
    }()
    
    private let primaryButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = AddCardLayout.cornerRadius
        return b
    }()
    
    private let cardPreviewContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        v.layer.cornerRadius = AddCardLayout.cornerRadius
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 10
        v.layer.shadowOpacity = 0.1
        v.backgroundColor = .clear
        return v
    }()
    
    private let previewCardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = AddCardLayout.cornerRadius
        v.clipsToBounds = true
        return v
    }()
    
    private let previewBrandLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = .label
        return l
    }()
    
    private let previewNumberLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        return l
    }()
    
    private let previewExpiryLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private let previewTypeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textColor = .secondaryLabel
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
        navigationController?.setNavigationBarHidden(false, animated: animated)
        updateBackButtonForStep(viewModel.step)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Add card"
        navigationItem.largeTitleDisplayMode = .never
        
        previewCardView.backgroundColor = .secondarySystemBackground
        addSubviews()
    }
    
    @objc private func backTapped() {
        viewModel.goBack()
    }
    
    private func updateBackButtonForStep(_ step: AddCardStep) {
        switch step {
        case .chooseType:
            navigationItem.leftBarButtonItem = nil
            navigationItem.hidesBackButton = false
        case .preview:
            navigationItem.hidesBackButton = true
            let backBtn = AppConstants.makeBackButton()
            backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        }
    }
    
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        contentStack.addArrangedSubview(stepLabel)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(cardTypeStack)
        contentStack.addArrangedSubview(cardPreviewContainer)
        contentStack.addArrangedSubview(primaryButton)
        cardPreviewContainer.addSubview(previewCardView)
        previewCardView.addSubview(previewBrandLabel)
        previewCardView.addSubview(previewNumberLabel)
        previewCardView.addSubview(previewExpiryLabel)
        previewCardView.addSubview(previewTypeLabel)
        view.addSubview(activityIndicator)
    }
    
    private func setupConstraints() {
        let inset = AddCardLayout.horizontalInset
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints { make in
            make.leading.equalTo(scrollView.contentLayoutGuide.snp.leading).offset(inset)
            make.trailing.equalTo(scrollView.contentLayoutGuide.snp.trailing).offset(-inset)
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(16)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).offset(-24)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width).offset(-inset * 2)
        }
        primaryButton.snp.makeConstraints { make in
            make.height.equalTo(AddCardLayout.buttonHeight)
        }
        cardPreviewContainer.snp.makeConstraints { make in
            make.height.equalTo(AddCardLayout.previewCardHeight)
        }
        previewCardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let pad = AddCardLayout.previewCardPadding
        previewBrandLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(pad)
        }
        previewNumberLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(pad)
            make.bottom.equalTo(previewExpiryLabel.snp.top).offset(-6)
        }
        previewExpiryLabel.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview().inset(pad)
        }
        previewTypeLabel.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(pad)
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
        updateBackButtonForStep(step)
        switch step {
        case .chooseType:
            stepLabel.text = "STEP 1"
            titleLabel.text = "Choose card type"
            cardTypeStack.isHidden = false
            cardPreviewContainer.isHidden = true
            primaryButton.setTitle("Continue", for: .normal)
            primaryButton.removeTarget(nil, action: nil, for: .touchUpInside)
            primaryButton.addTarget(self, action: #selector(continueFromTypeTapped), for: .touchUpInside)
            buildTypeButtons()
        case .preview:
            stepLabel.text = "STEP 2"
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
        container.layer.cornerRadius = AddCardLayout.cornerRadius
        let pad = AddCardLayout.typeOptionPadding
        let t = UILabel()
        t.text = title
        t.font = .systemFont(ofSize: 16, weight: .semibold)
        t.textColor = .label
        let s = UILabel()
        s.text = subtitle
        s.font = .systemFont(ofSize: 13, weight: .regular)
        s.textColor = .secondaryLabel
        container.addSubview(t)
        container.addSubview(s)
        t.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview().inset(pad)
        }
        s.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(pad)
            make.top.equalTo(t.snp.bottom).offset(2)
            make.bottom.equalToSuperview().inset(pad)
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
        
    }
}
