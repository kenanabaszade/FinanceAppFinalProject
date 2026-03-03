//
//  HistoryViewController.swift
//  FinanceApp
//

import UIKit
import SnapKit
import Combine

final class HistoryViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?
    private let viewModel: HistoryViewModel
    private var cancellables = Set<AnyCancellable>()

    private let searchContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authInputBackground
        v.layer.cornerRadius = AppConstants.History.searchBarCornerRadius
        return v
    }()

    private let searchIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass", withConfiguration: config))
        iv.tintColor = AppConstants.Colors.authSubtitle
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var searchField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Məkan və ya məbləğ axtar"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.textColor = AppConstants.Colors.authTitle
        tf.attributedPlaceholder = NSAttributedString(
            string: "Məkan və ya məbləğ axtar",
            attributes: [.foregroundColor: AppConstants.Colors.authPlaceholder]
        )
        tf.borderStyle = .none
        tf.clearButtonMode = .whileEditing
        return tf
    }()

    private let filterScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private let filterStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        return s
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = AppConstants.Colors.dashboardBackground
        tv.separatorStyle = .none
        tv.sectionHeaderTopPadding = 0
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return tv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()

    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        title = "Tarixçə"
        navigationController?.setNavigationBarHidden(false, animated: false)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = AppConstants.Colors.dashboardBackground
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.tintColor = AppConstants.Colors.authTitle
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppConstants.Colors.authTitle,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        setupUI()
        setupConstraints()
        setupFilterPills()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HistoryTransactionCell.self, forCellReuseIdentifier: HistoryTransactionCell.reuseId)
        tableView.rowHeight = AppConstants.History.rowHeight
        bind()
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        Task { await viewModel.loadTransactions() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let isRoot = (navigationController?.viewControllers.first === self)
        navigationItem.leftBarButtonItem = isRoot ? nil : UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
    }

    private func setupUI() {
        view.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        view.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStack)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
    }

    private func setupConstraints() {
        let h = AppConstants.Auth.horizontalPadding
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(AppConstants.History.searchBarHeight)
        }
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        filterScrollView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(AppConstants.History.filterPillHeight)
        }
        filterStack.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(filterScrollView.contentLayoutGuide.snp.trailing)
            make.height.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupFilterPills() {
        filterStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for filter in HistoryFilter.allCases {
            let pill = filterPill(for: filter)
            filterStack.addArrangedSubview(pill)
        }
        filterStack.layoutIfNeeded()
        let padding = AppConstants.Auth.horizontalPadding
        filterScrollView.contentInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }

    private func filterPill(for filter: HistoryFilter) -> UIButton {
        let isSelected = viewModel.selectedFilter == filter
        var config = UIButton.Configuration.plain()
        config.title = filter.rawValue
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { _ in
            var a = AttributeContainer()
            a.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            return a
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        config.baseBackgroundColor = isSelected ? AppConstants.Colors.mandarinOrange : AppConstants.Colors.authInputBackground
        config.baseForegroundColor = isSelected ? .white : AppConstants.Colors.authTitle
        if filter == .income || filter == .expense || filter == .category {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            config.image = UIImage(systemName: "chevron.down", withConfiguration: symbolConfig)
            config.imagePlacement = .trailing
            config.imagePadding = 6
        }
        let b = UIButton(configuration: config)
        b.layer.cornerRadius = AppConstants.History.filterPillHeight / 2
        b.clipsToBounds = true
        b.tag = HistoryFilter.allCases.firstIndex(of: filter) ?? 0
        b.addTarget(self, action: #selector(filterPillTapped(_:)), for: .touchUpInside)
        return b
    }

    private func updatePillStyle(_ button: UIButton, selected: Bool) {
        guard var config = button.configuration else { return }
        config.baseBackgroundColor = selected ? AppConstants.Colors.mandarinOrange : AppConstants.Colors.authInputBackground
        config.baseForegroundColor = selected ? .white : AppConstants.Colors.authTitle
        button.configuration = config
    }

    private func bind() {
        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)
        viewModel.$selectedFilter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.filterStack.arrangedSubviews.forEach { v in
                    guard let b = v as? UIButton else { return }
                    let idx = b.tag
                    let filter = HistoryFilter.allCases[safe: idx] ?? .all
                    self?.updatePillStyle(b, selected: self?.viewModel.selectedFilter == filter)
                }
            }
            .store(in: &cancellables)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading { self?.activityIndicator.startAnimating() } else { self?.activityIndicator.stopAnimating() }
            }
            .store(in: &cancellables)
    }

    @objc private func searchChanged() {
        viewModel.searchText = searchField.text ?? ""
        viewModel.refreshSections()
    }

    @objc private func filterPillTapped(_ sender: UIButton) {
        let idx = sender.tag
        guard let filter = HistoryFilter.allCases[safe: idx] else { return }
        viewModel.setFilter(filter)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryTransactionCell.reuseId, for: indexPath) as! HistoryTransactionCell
        let tx = viewModel.sections[indexPath.section].transactions[indexPath.row]
        cell.configure(with: tx)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let wrap = UIView()
        wrap.backgroundColor = AppConstants.Colors.dashboardBackground
        let label = UILabel()
        label.text = viewModel.sections[section].title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = AppConstants.Colors.authSubtitle
        wrap.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Auth.horizontalPadding)
            make.centerY.equalToSuperview()
        }
        return wrap
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        36
    }
}
