//
//  CardManagementViewController.swift
//  FinanceApp
//
//  Created by Macbook on 1.03.26.
//

import UIKit
import SnapKit
import Combine


final class CardManagementViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    
    private let viewModel: CardManagementViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var backButton: UIButton = AppConstants.makeBackButton()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Card Management"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "You have no cards yet.\nAdd a card from the dashboard."
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppConstants.Colors.authSubtitle
        l.numberOfLines = 0
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.hidesWhenStopped = true
        i.color = AppConstants.Colors.mandarinOrange
        return i
    }()
    
    private var pageController: UIPageViewController?
    private var pageContentViewControllers: [CardManagementPageContentViewController] = []
    
    init(viewModel: CardManagementViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(emptyLabel)
        view.addSubview(loadingIndicator)
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppConstants.Spacing.small)
            make.leading.equalToSuperview().inset(AppConstants.Auth.horizontalPadding)
            make.width.height.equalTo(AppConstants.Auth.iconButtonSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.centerX.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        bind()
        Task { await viewModel.loadCards() }
    }
    
    private func bind() {
        viewModel.$cards
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cards in
                self?.updateContent(cards: cards)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self, let message = message, !message.isEmpty else { return }
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.viewModel.errorMessage = nil
                })
                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    private func updateContent(cards: [Card]) {
        emptyLabel.isHidden = !cards.isEmpty
        
        if cards.isEmpty {
            pageController?.view.removeFromSuperview()
            pageController?.removeFromParent()
            pageController = nil
            pageContentViewControllers = []
            return
        }
        
        if pageController == nil {
            let pc = UIPageViewController(
                transitionStyle: .scroll,
                navigationOrientation: .horizontal,
                options: nil
            )
            pc.dataSource = self
            pc.delegate = self
            pc.view.backgroundColor = .clear
            addChild(pc)
            view.addSubview(pc.view)
            pc.view.snp.makeConstraints { make in
                make.top.equalTo(backButton.snp.bottom).offset(AppConstants.Spacing.medium)
                make.leading.trailing.bottom.equalToSuperview()
            }
            pc.didMove(toParent: self)
            pageController = pc
        }
        
        pageContentViewControllers = cards.map { card in
            let content = CardManagementPageContentViewController(
                card: card,
                viewModel: viewModel,
                onDeleted: { [weak self] in
                    self?.onCardDeleted()
                }
            )
            return content
        }
        
        pageController?.setViewControllers(
            [pageContentViewControllers[0]],
            direction: .forward,
            animated: false
        )
    }
    
    private func onCardDeleted() {
        if viewModel.cards.isEmpty {
            navigationController?.popViewController(animated: true)
        } else {
            updateContent(cards: viewModel.cards)
        }
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}


extension CardManagementViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? CardManagementPageContentViewController,
              let idx = pageContentViewControllers.firstIndex(of: vc),
              idx > 0 else { return nil }
        return pageContentViewControllers[idx - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? CardManagementPageContentViewController,
              let idx = pageContentViewControllers.firstIndex(of: vc),
              idx < pageContentViewControllers.count - 1 else { return nil }
        return pageContentViewControllers[idx + 1]
    }
}


final class CardManagementPageContentViewController: UIViewController {
    
    private let card: Card
    private weak var viewModel: CardManagementViewModel?
    private var onDeleted: () -> Void
    
    private let cardFaceView = CardFaceView()
    
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        return s
    }()
    
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 20
        return s
    }()
    
    private let cardTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()
    
    private let cardTypeSubtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    
    private let statusBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = AppConstants.Colors.mandarinOrange
        l.backgroundColor = AppConstants.Colors.mandarinOrange.withAlphaComponent(0.2)
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()
    
    private let securitySectionLabel: UILabel = {
        let l = UILabel()
        l.text = "Security"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    
    private let blockCardRow: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        return v
    }()
    
    private let blockCardIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "lock.slash", withConfiguration: config))
        iv.tintColor = AppConstants.Colors.mandarinOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let blockCardLabel: UILabel = {
        let l = UILabel()
        l.text = "Block card"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()
    
    private let blockSwitch: UISwitch = {
        let s = UISwitch()
        s.onTintColor = AppConstants.Colors.mandarinOrange
        return s
    }()
    
    private let managementSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "Management"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    
    private let deleteCardRow: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = AppConstants.Colors.authCardBackground
        b.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        b.contentHorizontalAlignment = .left
        return b
    }()
    
    private let deleteCardIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "trash", withConfiguration: config))
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let deleteCardLabel: UILabel = {
        let l = UILabel()
        l.text = "Delete card"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .systemRed
        return l
    }()
    
    private let deleteChevron: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let iv = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: config))
        iv.tintColor = AppConstants.Colors.authSubtitle
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    init(card: Card, viewModel: CardManagementViewModel, onDeleted: @escaping () -> Void) {
        self.card = card
        self.viewModel = viewModel
        self.onDeleted = onDeleted
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        cardFaceView.configure(
            card: card,
            balance: 0,
            currency: card.currency,
            showBalance: true,
            isPrimary: true
        )
        blockSwitch.isOn = card.isBlocked
        blockSwitch.addTarget(self, action: #selector(blockSwitchChanged), for: .valueChanged)
        deleteCardRow.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        contentStack.addArrangedSubview(cardFaceView)
        
        let infoRow = UIView()
        infoRow.addSubview(cardTitleLabel)
        infoRow.addSubview(cardTypeSubtitleLabel)
        infoRow.addSubview(statusBadge)
        contentStack.addArrangedSubview(infoRow)
        
        contentStack.addArrangedSubview(securitySectionLabel)
        blockCardRow.addSubview(blockCardIcon)
        blockCardRow.addSubview(blockCardLabel)
        blockCardRow.addSubview(blockSwitch)
        contentStack.addArrangedSubview(blockCardRow)
        
        contentStack.addArrangedSubview(managementSectionLabel)
        deleteCardRow.addSubview(deleteCardIcon)
        deleteCardRow.addSubview(deleteCardLabel)
        deleteCardRow.addSubview(deleteChevron)
        contentStack.addArrangedSubview(deleteCardRow)
        
        configureInfoRow()
        setupConstraints(infoRow: infoRow)
    }
    
    private func configureInfoRow() {
        cardTitleLabel.text = card.name
        cardTypeSubtitleLabel.text = card.type == .physical ? "Physical Debit Card" : "Virtual Debit Card"
        statusBadge.text = card.isBlocked ? "BLOCKED" : "ACTIVE"
        statusBadge.backgroundColor = card.isBlocked
        ? UIColor.systemGray.withAlphaComponent(0.2)
        : AppConstants.Colors.mandarinOrange.withAlphaComponent(0.2)
        statusBadge.textColor = card.isBlocked ? .systemGray : AppConstants.Colors.mandarinOrange
    }
    
    private func setupConstraints(infoRow: UIView) {
        let h = AppConstants.Auth.horizontalPadding
        let pad = AppConstants.Dashboard.balanceCardPadding
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(h)
            make.width.equalToSuperview().offset(-h * 2)
        }
        
        cardFaceView.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.Dashboard.balanceCardHeight)
        }
        
        infoRow.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        cardTitleLabel.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
        }
        cardTypeSubtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
        }
        statusBadge.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(60)
            make.height.equalTo(28)
        }
        
        let rowHorizontalPadding: CGFloat = 24
        
        blockCardRow.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        blockCardIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(rowHorizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        blockCardLabel.snp.makeConstraints { make in
            make.leading.equalTo(blockCardIcon.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        blockSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(rowHorizontalPadding)
            make.centerY.equalToSuperview()
        }
        
        deleteCardRow.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        deleteCardIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(rowHorizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        deleteCardLabel.snp.makeConstraints { make in
            make.leading.equalTo(deleteCardIcon.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        deleteChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(rowHorizontalPadding)
            make.centerY.equalToSuperview()
        }
    }
    
    @objc private func blockSwitchChanged() {
        let newValue = blockSwitch.isOn
        Task {
            await viewModel?.setBlocked(card: card, isBlocked: newValue)
            await MainActor.run {
                statusBadge.text = newValue ? "BLOCKED" : "ACTIVE"
                statusBadge.backgroundColor = newValue
                ? UIColor.systemGray.withAlphaComponent(0.2)
                : AppConstants.Colors.mandarinOrange.withAlphaComponent(0.2)
                statusBadge.textColor = newValue ? .systemGray : AppConstants.Colors.mandarinOrange
            }
        }
    }
    
    @objc private func deleteTapped() {
        let alert = UIAlertController(
            title: "Delete card",
            message: "Are you sure you want to remove this card? The linked account and balance will remain.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })
        present(alert, animated: true)
    }
    
    private func performDelete() {
        guard let viewModel = viewModel else { return }
        Task {
            do {
                try await viewModel.deleteCard(card)
                await MainActor.run {
                    onDeleted()
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
