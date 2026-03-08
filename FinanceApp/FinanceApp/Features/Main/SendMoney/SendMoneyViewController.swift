//
//  SendMoneyViewController.swift
//  FinanceApp
//
//  Created by Macbook on 2.27.26.
//

import UIKit
import SnapKit
import Combine

final class SendMoneyViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    
    private let viewModel: SendMoneyViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let navBar: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    
    private lazy var backButton: UIButton = {
        let b = AppConstants.makeBackButton()
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Send Money"
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .label
        return l
    }()
    
    private let searchContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.tertiarySystemFill
        v.layer.cornerRadius = 10
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
        tf.placeholder = "Search name, phone, or IBAN"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.textColor = .label
        tf.backgroundColor = .clear
        tf.borderStyle = .none
        tf.returnKeyType = .search
        tf.autocorrectionType = .no
        tf.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        return tf
    }()
    
    private let appUsersSectionContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.mandarinOrange.withAlphaComponent(0.12)
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let appUsersLabel: UILabel = {
        let l = UILabel()
        l.text = "ON \(AppConstants.appName.uppercased())"
        l.font = .systemFont(ofSize: 12, weight: .bold)
        l.textColor = AppConstants.Colors.mandarinOrange
        return l
    }()
    
    private lazy var appUsersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(RecentRecipientCell.self, forCellWithReuseIdentifier: RecentRecipientCell.reuseId)
        cv.contentInset = UIEdgeInsets(top: 0, left: AppConstants.Auth.horizontalPadding, bottom: 0, right: AppConstants.Auth.horizontalPadding)
        return cv
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.sectionIndexColor = AppConstants.Colors.mandarinOrange
        tv.sectionIndexBackgroundColor = .clear
        return tv
    }()
    
    private var appUsersSectionHeight: Constraint?
    
    init(viewModel: SendMoneyViewModel) {
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
        setupNavBar()
        setupSearch()
        setupAppUsersSection()
        setupTable()
        bind()
        Task { await viewModel.loadRecipients() }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        Task { await viewModel.loadRecipients() }
    }
    
    private func setupNavBar() {
        view.addSubview(navBar)
        navBar.addSubview(backButton)
        navBar.addSubview(titleLabel)
        
        navBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupSearch() {
        view.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom).offset(16)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(44)
        }
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }
    
    private func setupAppUsersSection() {
        view.addSubview(appUsersSectionContainer)
        appUsersSectionContainer.addSubview(appUsersLabel)
        appUsersSectionContainer.addSubview(appUsersCollectionView)
        
        appUsersSectionContainer.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(20)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
            appUsersSectionHeight = make.height.equalTo(124).constraint
        }
        appUsersLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalToSuperview().inset(16)
        }
        appUsersCollectionView.snp.makeConstraints { make in
            make.top.equalTo(appUsersLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(88)
        }
    }
    
    private func setupTable() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RecipientCell.self, forCellReuseIdentifier: RecipientCell.reuseId)
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .separator
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.estimatedRowHeight = 64
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(appUsersSectionContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func bind() {
        viewModel.$allRecipients
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.appUsersCollectionView.reloadData()
                let hasAppUsers = !self.viewModel.appUserRecipients.isEmpty
                self.appUsersSectionContainer.isHidden = !hasAppUsers
                self.appUsersSectionHeight?.update(offset: hasAppUsers ? 124 : 0)
                self.updateEmptyState()
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
        viewModel.$searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateEmptyState()
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func updateEmptyState() {
        let isEmpty = viewModel.filteredRecipients.isEmpty
        if isEmpty {
            let wrapper = UIView()
            let empty = UILabel()
            empty.text = "No recipients found"
            empty.font = .systemFont(ofSize: 17, weight: .regular)
            empty.textColor = .secondaryLabel
            empty.textAlignment = .center
            empty.numberOfLines = 0
            wrapper.addSubview(empty)
            empty.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview().offset(40)
                make.trailing.lessThanOrEqualToSuperview().offset(-40)
            }
            tableView.backgroundView = wrapper
        } else {
            tableView.backgroundView = nil
        }
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func searchChanged() {
        viewModel.searchText = searchField.text ?? ""
    }
}

extension SendMoneyViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.appUserRecipients.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentRecipientCell.reuseId, for: indexPath) as! RecentRecipientCell
        cell.configure(with: viewModel.appUserRecipients[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 64, height: 88)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let recipient = viewModel.appUserRecipients[indexPath.item]
        coordinator?.showEnterAmount(recipient: recipient)
    }
}

extension SendMoneyViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sectionedRecipients.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sectionedRecipients[section].recipients.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        container.backgroundColor = .clear
        let bgView = UIView()
        bgView.backgroundColor = AppConstants.Colors.authInputBackground
        bgView.layer.cornerRadius = 6
        container.addSubview(bgView)
        let label = UILabel()
        label.text = viewModel.sectionedRecipients[section].letter.uppercased()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = AppConstants.Colors.authSubtitle
        bgView.addSubview(label)
        bgView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(4)
        }
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        return container
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        36
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCell.reuseId, for: indexPath) as! RecipientCell
        let recipient = viewModel.sectionedRecipients[indexPath.section].recipients[indexPath.row]
        cell.configure(with: recipient)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let recipient = viewModel.sectionedRecipients[indexPath.section].recipients[indexPath.row]
        handleRecipientTapped(recipient)
    }
    
    private func handleRecipientTapped(_ recipient: SendMoneyRecipient) {
        if recipient.isAppUser {
            coordinator?.showEnterAmount(recipient: recipient)
        } else {
            coordinator?.openInviteToContact(recipient: recipient)
        }
    }
}

private final class RecentRecipientCell: UICollectionViewCell {
    
    static let reuseId = "RecentRecipientCell"
    
    private let avatarView = RecipientAvatarView()
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .label
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()
    private let typeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(typeLabel)
        avatarView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(56)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
        typeLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with recipient: SendMoneyRecipient) {
        avatarView.configure(recipient: recipient, size: 56)
        nameLabel.text = recipient.displayName
        typeLabel.text = AppConstants.appName
    }
}

private final class RecipientCell: UITableViewCell {
    
    static let reuseId = "RecipientCell"
    
    private let avatarView = RecipientAvatarView()
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()
    private let detailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .default
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
            make.top.greaterThanOrEqualToSuperview().inset(8)
            make.bottom.lessThanOrEqualToSuperview().inset(8)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
        }
        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with recipient: SendMoneyRecipient) {
        avatarView.configure(recipient: recipient, size: 44)
        nameLabel.text = recipient.displayName
        let phoneText = recipient.displayPhone
        detailLabel.text = recipient.isAppUser ? "@\(recipient.userId ?? "")  ·  \(phoneText)" : phoneText
    }
}

private final class RecipientAvatarView: UIView {
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    private let initialsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        l.textAlignment = .center
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppConstants.Colors.authInputBackground
        layer.cornerRadius = 22
        clipsToBounds = true
        addSubview(imageView)
        addSubview(initialsLabel)
        imageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        initialsLabel.snp.makeConstraints { make in make.center.equalToSuperview() }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
    
    func configure(recipient: SendMoneyRecipient, size: CGFloat) {
        layer.cornerRadius = size / 2
        initialsLabel.text = recipient.initials
        initialsLabel.isHidden = false
        imageView.image = nil
        imageView.isHidden = true
        
        if let imageData = recipient.contactImageData, let img = UIImage(data: imageData) {
            imageView.image = img
            imageView.isHidden = false
            initialsLabel.isHidden = true
        } else if let urlString = recipient.profileImageURL, let url = URL(string: urlString) {
            imageView.isHidden = false
            initialsLabel.isHidden = true
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.imageView.image = img
                }
            }.resume()
        } else {
            imageView.isHidden = true
            initialsLabel.isHidden = false
        }
    }
}
