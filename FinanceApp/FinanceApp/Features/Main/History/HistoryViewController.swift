//
//  HistoryViewController.swift
//  FinanceApp
//
//  Created by Macbook on 28.02.26.
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
    
    private let segmentContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authInputBackground
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 1
        v.layer.borderColor = AppConstants.Colors.authInputBorder.cgColor
        return v
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let items = HistoryFilter.allCases.map(\.rawValue)
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        sc.backgroundColor = .clear
        sc.selectedSegmentTintColor = AppConstants.Colors.mandarinOrange
        sc.setTitleTextAttributes([
            .foregroundColor: AppConstants.Colors.authTitle,
            .font: UIFont.systemFont(ofSize: 15, weight: .medium)
        ], for: .normal)
        sc.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ], for: .selected)
        return sc
    }()

    private lazy var categoryButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Kateqoriya"
        config.baseForegroundColor = AppConstants.Colors.authTitle
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { _ in
            var a = AttributeContainer()
            a.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            return a
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        config.image = UIImage(systemName: "chevron.down", withConfiguration: symbolConfig)
        config.imagePlacement = .trailing
        config.imagePadding = 8
        let b = UIButton(configuration: config)
        b.backgroundColor = AppConstants.Colors.authInputBackground
        b.layer.cornerRadius = 10
        b.layer.borderWidth = 1
        b.layer.borderColor = AppConstants.Colors.authInputBorder.cgColor
        b.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        return b
    }()

    private let filterStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        s.alignment = .fill
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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HistoryTransactionCell.self, forCellReuseIdentifier: HistoryTransactionCell.reuseId)
        tableView.rowHeight = AppConstants.History.rowHeight
        bind()
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        segmentedControl.selectedSegmentIndex = HistoryFilter.allCases.firstIndex(of: viewModel.selectedFilter) ?? 0
        Task { await viewModel.loadTransactions() }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            segmentContainer.layer.borderColor = AppConstants.Colors.authInputBorder.resolvedColor(with: traitCollection).cgColor
            categoryButton.layer.borderColor = AppConstants.Colors.authInputBorder.resolvedColor(with: traitCollection).cgColor
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let isRoot = (navigationController?.viewControllers.first === self)
        if isRoot {
            navigationItem.leftBarButtonItem = nil
        } else {
            let backBtn = AppConstants.makeBackButton()
            backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        }
    }
    
    private func setupUI() {
        view.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        view.addSubview(filterStack)
        segmentContainer.addSubview(segmentedControl)
        filterStack.addArrangedSubview(segmentContainer)
        filterStack.addArrangedSubview(categoryButton)
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
        filterStack.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview().inset(h)
        }
        segmentContainer.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        segmentedControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        categoryButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterStack.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func bind() {
        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)
        viewModel.$selectedFilter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filter in
                guard let self = self else { return }
                let idx = HistoryFilter.allCases.firstIndex(of: filter) ?? 0
                if self.segmentedControl.selectedSegmentIndex != idx {
                    self.segmentedControl.selectedSegmentIndex = idx
                }
            }
            .store(in: &cancellables)
        viewModel.$selectedCategoryId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categoryId in
                guard let self = self else { return }
                let title = self.viewModel.categoryName(for: categoryId) ?? "Kateqoriya"
                var config = self.categoryButton.configuration ?? UIButton.Configuration.plain()
                config.title = title
                self.categoryButton.configuration = config
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
    
    @objc private func segmentChanged() {
        let idx = segmentedControl.selectedSegmentIndex
        guard let filter = HistoryFilter.allCases[safe: idx] else { return }
        viewModel.setFilter(filter)
    }

    @objc private func categoryButtonTapped() {
        let categories = viewModel.categoriesForPicker
        let sheet = UIAlertController(title: "Kateqoriya seçin", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Hamısı", style: .default) { [weak self] _ in
            self?.viewModel.setCategoryFilter(nil)
        })
        for cat in categories {
            sheet.addAction(UIAlertAction(title: cat.name, style: .default) { [weak self] _ in
                self?.viewModel.setCategoryFilter(cat.id)
            })
        }
        sheet.addAction(UIAlertAction(title: "Ləğv et", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = categoryButton
            popover.sourceRect = categoryButton.bounds
        }
        present(sheet, animated: true)
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
