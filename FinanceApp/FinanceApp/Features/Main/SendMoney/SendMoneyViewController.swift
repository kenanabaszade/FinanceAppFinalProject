import UIKit
import SnapKit
import Combine

final class SendMoneyViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?

    private let viewModel: SendMoneyViewModel
    private var cancellables = Set<AnyCancellable>()

    private let navBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.secondarySystemBackground
        return v
    }()

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        b.tintColor = .label
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

    private lazy var qrButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        b.setImage(UIImage(systemName: "qrcode", withConfiguration: config), for: .normal)
        b.tintColor = .label
        b.addTarget(self, action: #selector(qrTapped), for: .touchUpInside)
        return b
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
        view.backgroundColor = UIColor.systemGroupedBackground
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
        navBar.addSubview(qrButton)

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
        qrButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
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
        tableView.register(RecipientSectionHeader.self, forHeaderFooterViewReuseIdentifier: RecipientSectionHeader.reuseId)
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.sectionIndexMinimumDisplayRowCount = 1
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .separator
        let leftInset = AppConstants.Auth.horizontalPadding + 44 + 12
        tableView.separatorInset = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: AppConstants.Auth.horizontalPadding)
        tableView.estimatedRowHeight = 72

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

    @objc private func qrTapped() {
        // QR scan for recipient – placeholder
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
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: RecipientSectionHeader.reuseId) as? RecipientSectionHeader
        header?.configure(letter: viewModel.sectionedRecipients[section].letter)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        28
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCell.reuseId, for: indexPath) as! RecipientCell
        let recipient = viewModel.sectionedRecipients[indexPath.section].recipients[indexPath.row]
        cell.configure(with: recipient)
        cell.onSendTapped = { [weak self] in
            self?.handleRecipientTapped(recipient)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
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

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        viewModel.sectionedRecipients.map(\.letter)
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        index
    }
}

// MARK: - Recent recipient cell
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

// MARK: - Section header
private final class RecipientSectionHeader: UITableViewHeaderFooterView {

    static let reuseId = "RecipientSectionHeader"

    private let letterLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.systemGroupedBackground
        contentView.addSubview(letterLabel)
        letterLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(AppConstants.Auth.horizontalPadding)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(letter: String) {
        letterLabel.text = letter
    }
}

// MARK: - Recipient row cell
private final class RecipientCell: UITableViewCell {

    static let reuseId = "RecipientCell"

    private let avatarView = RecipientAvatarView()
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()
    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        l.textColor = .white
        l.backgroundColor = AppConstants.Colors.mandarinOrange
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()
    private let phoneLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        return l
    }()
    private lazy var sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("₼", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = 22
        b.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        return b
    }()

    var onSendTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .secondarySystemGroupedBackground
        selectionStyle = .default
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(badgeLabel)
        contentView.addSubview(phoneLabel)
        contentView.addSubview(sendButton)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(AppConstants.Auth.horizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalToSuperview().inset(14)
        }
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        badgeLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(6)
            make.centerY.equalTo(nameLabel)
            make.height.equalTo(18)
            make.trailing.lessThanOrEqualTo(sendButton.snp.leading).offset(-8)
        }
        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        phoneLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(sendButton.snp.leading).offset(-8)
        }
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppConstants.Auth.horizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with recipient: SendMoneyRecipient) {
        avatarView.configure(recipient: recipient, size: 44)
        nameLabel.text = recipient.displayName
        phoneLabel.text = recipient.displayPhone
        if recipient.isAppUser {
            badgeLabel.text = "  \(AppConstants.appName)  "
            badgeLabel.backgroundColor = AppConstants.Colors.mandarinOrange
            badgeLabel.textColor = .white
            badgeLabel.isHidden = false
        } else {
            badgeLabel.text = "  Contact  "
            badgeLabel.backgroundColor = .tertiaryLabel
            badgeLabel.textColor = .white
            badgeLabel.isHidden = false
        }
    }

    @objc private func sendTapped() {
        onSendTapped?()
    }
}

// MARK: - Avatar (initials or image)
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
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppConstants.Colors.mandarinOrange
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
