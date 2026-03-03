import UIKit
import SnapKit
import Combine

final class MainViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?

    private let viewModel: MainViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let contentView = UIView()

    private let greetingLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()

    private let notificationBellContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = AppConstants.Dashboard.notificationBellSize / 2
        v.layer.borderWidth = 1
        v.layer.borderColor = AppConstants.Colors.authInputBorder.cgColor
        return v
    }()

    private lazy var notificationButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        b.setImage(UIImage(systemName: "bell.fill", withConfiguration: config), for: .normal)
        b.tintColor = AppConstants.Colors.authTitle
        b.addTarget(self, action: #selector(notificationTapped), for: .touchUpInside)
        return b
    }()

    private let notificationDot: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.mandarinOrange
        v.layer.cornerRadius = 5
        return v
    }()

    private lazy var cardsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.isPagingEnabled = true
        cv.delegate = self
        cv.dataSource = self
        cv.register(DashboardCardCell.self, forCellWithReuseIdentifier: DashboardCardCell.reuseId)
        cv.register(AddCardEmptyCell.self, forCellWithReuseIdentifier: AddCardEmptyCell.reuseId)
        return cv
    }()

    private let pageDotsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = AppConstants.Dashboard.pageDotSpacing
        s.alignment = .center
        return s
    }()

    private var pageDots: [UIView] = []
    private var currentCardIndex = 0

    private let quickActionsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .equalSpacing
        return s
    }()

    private var quickActionCircles: [UIView] = []

    private lazy var sendAction = makeQuickAction(title: "Send", systemImage: "arrow.up", action: #selector(sendTapped))
    private lazy var requestAction = makeQuickAction(title: "Request", systemImage: "arrow.down")
    private lazy var topUpAction = makeQuickAction(title: "Top Up", systemImage: "plus", action: #selector(topUpTapped))
    private lazy var exchangeAction = makeQuickAction(title: "Exchange", systemImage: "dollarsign.arrow.circlepath")

    private let transactionsTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Recent Transactions"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()

    private lazy var seeAllButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("SEE ALL", for: .normal)
        b.setTitleColor(AppConstants.Colors.mandarinOrange, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        b.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)
        return b
    }()

    private let transactionsCard: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = AppConstants.Dashboard.balanceCardCornerRadius
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 10
        return v
    }()

    private let transactionsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        return s
    }()

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await viewModel.loadDashboard() }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            notificationBellContainer.layer.borderColor = AppConstants.Colors.authInputBorder
                .resolvedColor(with: traitCollection).cgColor
            transactionsCard.layer.shadowColor = UIColor.black.withAlphaComponent(0.04)
                .resolvedColor(with: traitCollection).cgColor
            quickActionCircles.forEach { circle in
                circle.layer.borderColor = AppConstants.Colors.authInputBorder
                    .resolvedColor(with: traitCollection).cgColor
            }
        }
    }

    private func setupUI() {
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        addSubviews()
        bind()
    }

    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(greetingLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(notificationBellContainer)
        notificationBellContainer.addSubview(notificationButton)
        notificationBellContainer.addSubview(notificationDot)

        contentView.addSubview(cardsCollectionView)
        contentView.addSubview(pageDotsStack)

        contentView.addSubview(quickActionsStack)
        quickActionsStack.addArrangedSubview(sendAction)
        quickActionsStack.addArrangedSubview(requestAction)
        quickActionsStack.addArrangedSubview(topUpAction)
        quickActionsStack.addArrangedSubview(exchangeAction)

        contentView.addSubview(transactionsTitleLabel)
        contentView.addSubview(seeAllButton)
        contentView.addSubview(transactionsCard)
        transactionsCard.addSubview(transactionsStack)
    }

    private func setupConstraints() {
        let h = AppConstants.Auth.horizontalPadding

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }

        greetingLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.Spacing.medium)
            make.leading.equalToSuperview().inset(h)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(greetingLabel.snp.bottom).offset(AppConstants.Spacing.small / 2)
            make.leading.equalToSuperview().inset(h)
            make.trailing.lessThanOrEqualTo(notificationBellContainer.snp.leading).offset(-AppConstants.Spacing.small)
        }
        notificationBellContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(h)
            make.centerY.equalTo(nameLabel)
            make.width.height.equalTo(AppConstants.Dashboard.notificationBellSize)
        }
        notificationButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        notificationDot.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.Spacing.small - 2)
            make.trailing.equalToSuperview().inset(AppConstants.Spacing.small)
            make.width.height.equalTo(10)
        }

        cardsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(AppConstants.Dashboard.balanceCardHeight)
        }

        pageDotsStack.snp.makeConstraints { make in
            make.top.equalTo(cardsCollectionView.snp.bottom).offset(AppConstants.Spacing.medium)
            make.centerX.equalToSuperview()
        }

        quickActionsStack.snp.makeConstraints { make in
            make.top.equalTo(pageDotsStack.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(h)
        }

        transactionsTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(quickActionsStack.snp.bottom).offset(AppConstants.Spacing.extraLarge)
            make.leading.equalToSuperview().inset(h)
        }
        seeAllButton.snp.makeConstraints { make in
            make.centerY.equalTo(transactionsTitleLabel)
            make.trailing.equalToSuperview().inset(h)
        }
        transactionsCard.snp.makeConstraints { make in
            make.top.equalTo(transactionsTitleLabel.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview().inset(h)
            make.bottom.equalToSuperview().offset(-AppConstants.Spacing.extraLarge)
        }
        transactionsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppConstants.Spacing.small)
        }
    }

    private func bind() {
        viewModel.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateHeader() }
            .store(in: &cancellables)
        viewModel.$unreadNotificationsCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.notificationDot.isHidden = count == 0
            }
            .store(in: &cancellables)
        viewModel.$recentTransactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reloadTransactions() }
            .store(in: &cancellables)
        viewModel.$cards
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.cardsCollectionView.reloadData()
                self?.updatePageDots()
                self?.applyCardTransforms()
            }
            .store(in: &cancellables)
        viewModel.$accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.cardsCollectionView.reloadData()
            }
            .store(in: &cancellables)

        updateHeader()
    }

    private func updateHeader() {
        greetingLabel.text = viewModel.greeting.uppercased()
        nameLabel.text = viewModel.displayName
    }

    private func applyCardTransforms() {
        let scrollView = cardsCollectionView
        let width = scrollView.bounds.width
        guard width > 0 else { return }
        let offsetX = scrollView.contentOffset.x
        for cell in scrollView.visibleCells {
            guard let indexPath = scrollView.indexPath(for: cell) else { continue }
            let cellCenterX = CGFloat(indexPath.item) * width + width / 2
            let distance = abs((offsetX + width / 2) - cellCenterX)
            let scale = max(0.96, 1.0 - (distance / width) * 0.04)
            cell.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    /// Real cards only; no placeholders. Use displayItems for collection view (includes Add Card row).
    private var displayCards: [Card] {
        viewModel.cards
    }

    /// One row per card plus one "Add card" row at the end. When no cards, single row is Add card.
    private var displayItems: [Card?] {
        if viewModel.cards.isEmpty {
            return [nil]
        }
        return viewModel.cards.map { $0 } + [nil]
    }

    private func updatePageDots() {
        pageDots.forEach { $0.removeFromSuperview() }
        pageDotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pageDots.removeAll()

        let count = displayItems.count
        for i in 0..<count {
            let dot = UIView()
            let isActive = i == currentCardIndex
            dot.backgroundColor = isActive
                ? AppConstants.Colors.mandarinOrange
                : AppConstants.Colors.authInputBorder
            let size = isActive
                ? AppConstants.Dashboard.pageActiveDotSize
                : AppConstants.Dashboard.pageInactiveDotSize
            dot.layer.cornerRadius = size / 2
            dot.snp.makeConstraints { make in
                make.width.height.equalTo(size)
            }
            pageDots.append(dot)
            pageDotsStack.addArrangedSubview(dot)
        }
    }

    private func reloadTransactions() {
        transactionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, tx) in viewModel.recentTransactions.enumerated() {
            let row = TransactionRowView(transaction: tx)
            transactionsStack.addArrangedSubview(row)
            if index < viewModel.recentTransactions.count - 1 {
                let separator = UIView()
                separator.backgroundColor = AppConstants.Colors.authInputBorder
                separator.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                }
                transactionsStack.addArrangedSubview(separator)
            }
        }
        if viewModel.recentTransactions.isEmpty {
            let empty = UILabel()
            empty.text = "No recent transactions"
            empty.font = .systemFont(ofSize: 14, weight: .regular)
            empty.textColor = AppConstants.Colors.authSubtitle
            empty.textAlignment = .center
            empty.snp.makeConstraints { make in
                make.height.equalTo(AppConstants.Dashboard.transactionRowHeight)
            }
            transactionsStack.addArrangedSubview(empty)
        }
    }

    private func makeQuickAction(title: String, systemImage: String, action: Selector? = nil) -> UIView {
        let container = UIView()
        if action != nil {
            container.isUserInteractionEnabled = true
            container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        }

        let circle = UIView()
        circle.backgroundColor = .clear
        circle.layer.cornerRadius = AppConstants.Dashboard.quickActionCircleSize / 2
        circle.layer.borderWidth = 1.5
        circle.layer.borderColor = AppConstants.Colors.authInputBorder.cgColor

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let imageView = UIImageView(image: UIImage(systemName: systemImage, withConfiguration: iconConfig))
        imageView.tintColor = AppConstants.Colors.authTitle
        imageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = AppConstants.Colors.authSubtitle
        label.textAlignment = .center

        quickActionCircles.append(circle)

        container.addSubview(circle)
        circle.addSubview(imageView)
        container.addSubview(label)

        circle.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(AppConstants.Dashboard.quickActionCircleSize)
        }
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(AppConstants.Dashboard.quickActionCircleSize * 0.4)
        }
        label.snp.makeConstraints { make in
            make.top.equalTo(circle.snp.bottom).offset(AppConstants.Spacing.small)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        container.snp.makeConstraints { make in
            make.width.equalTo(AppConstants.Dashboard.quickActionContainerWidth)
        }

        return container
    }

    @objc private func notificationTapped() {
        coordinator?.showNotificationsCenter()
    }
    @objc private func seeAllTapped() { }
    @objc private func sendTapped() {
        coordinator?.showSendMoney()
    }

    @objc private func topUpTapped() {
        tabBarController?.selectedIndex = 2
    }
}

extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        displayItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let card = displayItems[indexPath.item] else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AddCardEmptyCell.reuseId,
                for: indexPath
            ) as! AddCardEmptyCell
            cell.configure(isFirstCard: viewModel.cards.isEmpty)
            cell.onAddTapped = { [weak self] in self?.coordinator?.showAddCard() }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DashboardCardCell.reuseId,
            for: indexPath
        ) as! DashboardCardCell
        let currency = card.currency ?? "AZN"
        let balance = viewModel.totalBalanceForCurrency(currency)
        let data = DashboardCardData(
            card: card,
            balance: balance,
            currency: currency
        )
        cell.configure(with: data)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: AppConstants.Dashboard.balanceCardHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        if let card = displayItems[indexPath.item] {
            coordinator?.navigate(to: .cardDetail(card: card))
        }
        // Add card row: tap handled by button in AddCardEmptyCell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == cardsCollectionView else { return }
        let width = scrollView.bounds.width
        guard width > 0 else { return }
        let offsetX = scrollView.contentOffset.x
        let page = Int(round(offsetX / width))
        if page != currentCardIndex {
            currentCardIndex = page
            updatePageDots()
        }
        applyCardTransforms()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == cardsCollectionView else { return }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        currentCardIndex = page
        updatePageDots()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == cardsCollectionView else { return }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        currentCardIndex = page
        updatePageDots()
    }
}
