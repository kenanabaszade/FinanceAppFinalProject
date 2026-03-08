//
//  RequestMoneyRecipientsViewController.swift
//  FinanceApp
//
//  Created by Macbook on 2.27.26.
//

import UIKit
import SnapKit
import Combine

final class RequestMoneyRecipientsViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    private let viewModel: RequestMoneyRecipientsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return tv
    }()
    
    private let headerContainer = UIView()
    
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
        tf.placeholder = "Ad, @tag və ya nömrə"
        tf.font = .systemFont(ofSize: 15, weight: .regular)
        tf.textColor = AppConstants.Colors.authTitle
        tf.borderStyle = .none
        tf.clearButtonMode = .whileEditing
        return tf
    }()
    
    private let recentSectionContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.mandarinOrange.withAlphaComponent(0.12)
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let recentTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "TEZ-TEZ İSTİFADƏ OLUNANLAR"
        l.font = .systemFont(ofSize: 12, weight: .bold)
        l.textColor = AppConstants.Colors.mandarinOrange
        l.numberOfLines = 1
        return l
    }()
    
    private let recentCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        return cv
    }()
    
    private let allContactsTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Bütün kontaktlar"
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()
    
    private let bottomContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.dashboardBackground
        return v
    }()
    
    private let inviteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        var titleAttr = AttributedString("Dostlarını Dəvət Et")
        titleAttr.font = .systemFont(ofSize: 16, weight: .semibold)
        config.attributedTitle = titleAttr
        config.image = UIImage(systemName: "person.badge.plus")
        config.imagePadding = 8
        config.baseBackgroundColor = AppConstants.Colors.mandarinOrange.withAlphaComponent(0.12)
        config.baseForegroundColor = AppConstants.Colors.mandarinOrange
        config.cornerStyle = .medium
        return UIButton(configuration: config)
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()
    
    private var recentSectionHeight: Constraint?
    
    init(viewModel: RequestMoneyRecipientsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        setupNavigationBar()
        setupUI()
        setupConstraints()
        bind()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RecipientCell.self, forCellReuseIdentifier: RecipientCell.reuseId)
        
        recentCollectionView.dataSource = self
        recentCollectionView.delegate = self
        recentCollectionView.register(FrequentRecipientCell.self, forCellWithReuseIdentifier: FrequentRecipientCell.reuseId)
        recentCollectionView.contentInset = UIEdgeInsets(top: 0, left: AppConstants.Auth.horizontalPadding, bottom: 0, right: AppConstants.Auth.horizontalPadding)
        
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        inviteButton.addTarget(self, action: #selector(inviteTapped), for: .touchUpInside)
        
        Task { await viewModel.loadRecipients() }
    }
    
    private func setupNavigationBar() {
        title = "Sıfır"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.setNavigationBarHidden(false, animated: false)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppConstants.Colors.dashboardBackground
        appearance.titleTextAttributes = [
            .foregroundColor: AppConstants.Colors.authTitle,
            .font: AppConstants.Fonts.bodySemibold(size: 17)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = AppConstants.Colors.authTitle
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(bottomContainer)
        bottomContainer.addSubview(inviteButton)
        view.addSubview(activityIndicator)
        
        headerContainer.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        headerContainer.addSubview(recentSectionContainer)
        recentSectionContainer.addSubview(recentTitleLabel)
        recentSectionContainer.addSubview(recentCollectionView)
        headerContainer.addSubview(allContactsTitleLabel)
        
        tableView.tableHeaderView = headerContainer
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(bottomContainer.snp.top)
        }
        bottomContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        inviteButton.snp.makeConstraints { make in
            make.top.equalTo(bottomContainer.snp.top).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalTo(bottomContainer).inset(AppConstants.Auth.horizontalPadding)
            make.bottom.equalTo(bottomContainer.snp.bottom).inset(AppConstants.Spacing.medium)
            make.height.equalTo(54)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        headerContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)
        
        let h = AppConstants.Auth.horizontalPadding
        searchContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(44)
        }
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview()
        }
        recentSectionContainer.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(h)
            recentSectionHeight = make.height.equalTo(140).constraint
        }
        recentTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalToSuperview().inset(16)
        }
        recentCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recentTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(88)
            make.bottom.equalToSuperview().inset(12)
        }
        allContactsTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(recentSectionContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(h)
            make.bottom.equalToSuperview().offset(-AppConstants.Spacing.medium)
        }
        
        headerContainer.snp.makeConstraints { make in
            make.width.equalTo(tableView.snp.width)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateHeaderSize()
        }
    }
    
    private func updateHeaderSize() {
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = headerContainer.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        var frame = headerContainer.frame
        frame.size.width = tableView.bounds.width
        frame.size.height = height
        headerContainer.frame = frame
        tableView.tableHeaderView = headerContainer
    }
    
    private func bind() {
        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$frequentRecipients
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
                guard let self = self else { return }
                let hasFrequent = !list.isEmpty
                self.recentSectionContainer.isHidden = !hasFrequent
                self.recentSectionHeight?.update(offset: hasFrequent ? 140 : 0)
                self.recentCollectionView.reloadData()
                self.updateHeaderSize()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self, let message, !message.isEmpty else { return }
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func searchChanged() {
        viewModel.searchText = searchField.text ?? ""
    }
    
    @objc private func inviteTapped() {
        let recipient = SendMoneyRecipient(
            id: "invite-placeholder",
            displayName: "",
            phone: nil,
            profileImageURL: nil,
            contactImageData: nil,
            isAppUser: false,
            userId: nil
        )
        coordinator?.openInviteToContact(recipient: recipient)
    }
    
    private func handleSelection(_ recipient: SendMoneyRecipient) {
        if recipient.isAppUser, recipient.userId != nil {
            coordinator?.showRequestMoneyEnterAmount(recipient: recipient)
        } else {
            coordinator?.openInviteToContact(recipient: recipient)
        }
    }
}


extension RequestMoneyRecipientsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].recipients.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: RecipientCell.reuseId,
            for: indexPath
        ) as! RecipientCell
        let section = viewModel.sections[indexPath.section]
        let recipient = section.recipients[indexPath.row]
        cell.configure(with: recipient)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        container.backgroundColor = .clear
        
        let bgView = UIView()
        bgView.backgroundColor = AppConstants.Colors.authInputBackground
        bgView.layer.cornerRadius = 6
        container.addSubview(bgView)
        
        let label = UILabel()
        label.text = viewModel.sections[section].title.uppercased()
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
        return 36
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = viewModel.sections[indexPath.section]
        let recipient = section.recipients[indexPath.row]
        handleSelection(recipient)
    }
}

extension RequestMoneyRecipientsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.frequentRecipients.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FrequentRecipientCell.reuseId,
            for: indexPath
        ) as! FrequentRecipientCell
        let recipient = viewModel.frequentRecipients[indexPath.item]
        cell.configure(with: recipient)
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 64, height: 88)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let recipient = viewModel.frequentRecipients[indexPath.item]
        handleSelection(recipient)
    }
} 

private final class RecipientCell: UITableViewCell {
    static let reuseId = "RecipientCell"
    
    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authInputBackground
        v.layer.cornerRadius = 22
        v.clipsToBounds = true
        return v
    }()
    
    private let avatarImageView: UIImageView = {
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
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
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
        
        contentView.addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(initialsLabel)
        
        let labelsStack = UIStackView(arrangedSubviews: [nameLabel, detailLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2
        labelsStack.alignment = .leading
        contentView.addSubview(labelsStack)
        
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
            make.top.greaterThanOrEqualToSuperview().inset(8)
            make.bottom.lessThanOrEqualToSuperview().inset(8)
        }
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        initialsLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        labelsStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(avatarView.snp.centerY)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with recipient: SendMoneyRecipient) {
        nameLabel.text = recipient.displayName
        let phoneText = recipient.displayPhone
        detailLabel.text = recipient.isAppUser ? "@\(recipient.userId ?? "")  ·  \(phoneText)" : phoneText
        
        if let data = recipient.contactImageData, let image = UIImage(data: data) {
            avatarImageView.image = image
            avatarImageView.isHidden = false
            initialsLabel.isHidden = true
        } else {
            avatarImageView.image = nil
            avatarImageView.isHidden = true
            initialsLabel.isHidden = false
            initialsLabel.text = recipient.initials
        }
    }
}

private final class FrequentRecipientCell: UICollectionViewCell {
    
    static let reuseId = "FrequentRecipientCell"
    
    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authInputBackground
        v.layer.cornerRadius = 28
        v.clipsToBounds = true
        return v
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let initialsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        l.textAlignment = .center
        return l
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = AppConstants.Colors.authTitle
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(initialsLabel)
        contentView.addSubview(nameLabel)
        
        avatarView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(56)
        }
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        initialsLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with recipient: SendMoneyRecipient) {
        nameLabel.text = recipient.displayName
        
        if let data = recipient.contactImageData, let image = UIImage(data: data) {
            avatarImageView.image = image
            avatarImageView.isHidden = false
            initialsLabel.isHidden = true
        } else {
            avatarImageView.image = nil
            avatarImageView.isHidden = true
            initialsLabel.isHidden = false
            initialsLabel.text = recipient.initials
        }
    }
}

