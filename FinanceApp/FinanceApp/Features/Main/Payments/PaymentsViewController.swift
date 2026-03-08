//
//  PaymentsViewController.swift
//  FinanceApp
//
//  Created by Macbook on 3.03.26.
//


import UIKit
import SnapKit
import Combine

final class PaymentsViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    private let viewModel: PaymentsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()
    private let contentView = UIView()
    
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "My Payments"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()
    
    private let searchContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authInputBackground
        v.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        return v
    }()
    
    private let searchIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass", withConfiguration: config))
        iv.tintColor = AppConstants.Colors.authSubtitle
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let searchField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Search"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.textColor = AppConstants.Colors.authTitle
        tf.borderStyle = .none
        tf.clearButtonMode = .whileEditing
        return tf
    }()
    
    private let categoriesTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .singleLine
        tv.separatorColor = AppConstants.Colors.authInputBorder
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.rowHeight = 64
        tv.isScrollEnabled = false
        return tv
    }()
    
    init(viewModel: PaymentsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        setupUI()
        setupTable()
        bind()
        Task { await viewModel.loadAccounts() }
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerLabel)
        contentView.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        contentView.addSubview(categoriesTableView)
        
        let h = AppConstants.Auth.horizontalPadding
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(h)
        }
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(48)
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
        categoriesTableView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(CGFloat(viewModel.filteredCategories.count) * 64)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
    
    private func setupTable() {
        categoriesTableView.delegate = self
        categoriesTableView.dataSource = self
        categoriesTableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseId)
    }
    
    private func bind() {
        viewModel.$searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.categoriesTableView.reloadData()
                self?.updateTableHeight()
            }
            .store(in: &cancellables)
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
    }
    
    private func updateTableHeight() {
        let count = viewModel.filteredCategories.count
        categoriesTableView.snp.updateConstraints { make in
            make.height.equalTo(CGFloat(count) * 64)
        }
    }
    
    @objc private func searchChanged() {
        viewModel.searchText = searchField.text ?? ""
    }
}

extension PaymentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredCategories.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.reuseId, for: indexPath) as! CategoryCell
        cell.configure(with: viewModel.filteredCategories[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let category = viewModel.filteredCategories[indexPath.row]
        coordinator?.showEnterPayment(category: category)
    }
}

private final class CategoryCell: UITableViewCell {
    static let reuseId = "CategoryCell"
    private let iconBg = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let badgeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(iconBg)
        iconBg.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(badgeLabel)
        iconBg.backgroundColor = AppConstants.Colors.authInputBackground
        iconBg.layer.cornerRadius = 22
        iconView.tintColor = AppConstants.Colors.mandarinOrange
        iconView.contentMode = .scaleAspectFit
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = AppConstants.Colors.authTitle
        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textColor = AppConstants.Colors.mandarinOrange
        badgeLabel.backgroundColor = AppConstants.Colors.mandarinOrange.withAlphaComponent(0.12)
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center
        iconBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Auth.horizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBg.snp.trailing).offset(14)
            make.centerY.equalToSuperview()
        }
        badgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppConstants.Auth.horizontalPadding)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(36)
            make.height.equalTo(20)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(with category: PaymentCategory) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image = UIImage(systemName: category.systemImageName, withConfiguration: config)
        titleLabel.text = category.name
        badgeLabel.isHidden = true
    }
}
