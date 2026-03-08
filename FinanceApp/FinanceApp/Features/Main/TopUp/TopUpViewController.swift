//
//  TopUpViewController.swift
//  FinanceApp
//
//  Created by Macbook on 2.28.26.
//

import UIKit
import SnapKit
import Combine

final class TopUpViewController: UIViewController {
    
    private let viewModel: TopUpViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.keyboardDismissMode = .onDrag
        return sv
    }()
    private let contentView = UIView()
    
    private let balanceCard: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = AppConstants.Sizes.cornerRadius * 2
        v.layer.borderWidth = 1
        return v
    }()
    
    private let balanceTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "CURRENT BALANCE"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    
    private let balanceAmountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()
    
    private let balanceIconView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "dollarsign.circle.fill", withConfiguration: config))
        iv.tintColor = AppConstants.Colors.mandarinOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let amountSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "Add amount"
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    
    private let amountField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "0.00"
        tf.font = .systemFont(ofSize: 36, weight: .semibold)
        tf.keyboardType = .decimalPad
        tf.textAlignment = .center
        tf.textColor = AppConstants.Colors.authTitle
        tf.backgroundColor = AppConstants.Colors.authInputBackground
        tf.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        return tf
    }()
    
    private let currencyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .medium)
        l.textColor = AppConstants.Colors.authSubtitle
        l.textAlignment = .center
        return l
    }()
    
    private let accountsSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "Account"
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    
    private let accountsTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.isScrollEnabled = false
        tv.backgroundColor = AppConstants.Colors.authInputBackground
        tv.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return tv
    }()
    
    private let addMoneyButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add money", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        return b
    }()
    
    private let errorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .systemRed
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()
    
    private let emptyAccountsLabel: UILabel = {
        let l = UILabel()
        l.text = "Add a card to create an account"
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()
    
    init(viewModel: TopUpViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        title = "Top Up"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .never
        let helpButton = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle"), style: .plain, target: self, action: #selector(helpTapped))
        navigationItem.rightBarButtonItem = helpButton
        setupLayout()
        bind()
        addMoneyButton.addTarget(self, action: #selector(addMoneyTapped), for: .touchUpInside)
        amountField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        accountsTableView.delegate = self
        accountsTableView.dataSource = self
        accountsTableView.register(TopUpAccountCell.self, forCellReuseIdentifier: TopUpAccountCell.reuseId)
        Task { await viewModel.loadAccounts() }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            balanceCard.layer.borderColor = AppConstants.Colors.authInputBorder.resolvedColor(with: traitCollection).cgColor
        }
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(balanceCard)
        balanceCard.addSubview(balanceTitleLabel)
        balanceCard.addSubview(balanceAmountLabel)
        balanceCard.addSubview(balanceIconView)
        contentView.addSubview(amountSectionLabel)
        contentView.addSubview(amountField)
        contentView.addSubview(currencyLabel)
        contentView.addSubview(accountsSectionLabel)
        contentView.addSubview(accountsTableView)
        contentView.addSubview(emptyAccountsLabel)
        contentView.addSubview(addMoneyButton)
        contentView.addSubview(errorLabel)
        view.addSubview(activityIndicator)
        
        let padding: CGFloat = AppConstants.Auth.horizontalPadding
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        balanceCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(100)
        }
        balanceTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        balanceIconView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(balanceTitleLabel)
            make.size.equalTo(32)
        }
        balanceAmountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(balanceTitleLabel.snp.bottom).offset(8)
        }
        amountSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(balanceCard.snp.bottom).offset(28)
            make.leading.equalToSuperview().inset(padding)
        }
        amountField.snp.makeConstraints { make in
            make.top.equalTo(amountSectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(48)
        }
        currencyLabel.snp.makeConstraints { make in
            make.top.equalTo(amountField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
        accountsSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(currencyLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().inset(padding)
        }
        accountsTableView.snp.makeConstraints { make in
            make.top.equalTo(accountsSectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(72)
        }
        emptyAccountsLabel.snp.makeConstraints { make in
            make.top.equalTo(accountsSectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        addMoneyButton.snp.makeConstraints { make in
            make.top.equalTo(accountsTableView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-padding - 20)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(addMoneyButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        balanceCard.layer.borderColor = AppConstants.Colors.authInputBorder.resolvedColor(with: traitCollection).cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await viewModel.loadAccounts() }
    }
    
    private func bind() {
        viewModel.$accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
                guard let self = self else { return }
                let isEmpty = list.isEmpty
                self.emptyAccountsLabel.isHidden = !isEmpty
                self.accountsTableView.isHidden = isEmpty
                self.accountsTableView.reloadData()
                self.updateAccountsTableHeight(count: list.count)
            }
            .store(in: &cancellables)
        viewModel.$selectedAccount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                self?.accountsTableView.reloadData()
                self?.updateBalanceDisplay(account: account)
                self?.currencyLabel.text = account?.currency ?? "AZN"
            }
            .store(in: &cancellables)
        viewModel.$amountText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                if self?.amountField.text != text { self?.amountField.text = text }
            }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.errorLabel.text = msg
                self?.errorLabel.isHidden = msg == nil || msg?.isEmpty == true
            }
            .store(in: &cancellables)
        viewModel.$topUpSuccess
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.showSuccessAndRefresh()
            }
            .store(in: &cancellables)
    }
    
    private func updateBalanceDisplay(account: Account?) {
        guard let account = account else {
            balanceAmountLabel.text = "0.00"
            return
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let str = formatter.string(from: NSNumber(value: account.amount)) ?? "0.00"
        let symbol: String
        switch account.currency {
        case "AZN": symbol = "₼"
        case "USD": symbol = "$"
        default: symbol = account.currency
        }
        balanceAmountLabel.text = symbol + " " + str
    }
    
    private func updateAccountsTableHeight(count: Int) {
        let h = count == 0 ? 60 : min(220, CGFloat(count) * 72)
        accountsTableView.snp.updateConstraints { make in make.height.equalTo(h) }
    }
    
    private func showSuccessAndRefresh() {
        viewModel.clearSuccess()
        let alert = UIAlertController(title: "Money added", message: "Your balance has been updated.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            Task { await self?.viewModel.loadAccounts() }
        })
        present(alert, animated: true)
    }
    
    @objc private func amountChanged() {
        viewModel.amountText = amountField.text ?? ""
    }
    
    @objc private func helpTapped() {
        let alert = UIAlertController(title: "Top Up", message: "Enter an amount and tap Add money to add funds to your selected account.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func addMoneyTapped() {
        view.endEditing(true)
        addMoneyButton.isEnabled = false
        activityIndicator.startAnimating()
        Task {
            await viewModel.addMoney()
            await MainActor.run {
                self.activityIndicator.stopAnimating()
                self.addMoneyButton.isEnabled = true
            }
        }
    }
    
    @objc private func keyboardWillShow(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = frame.height
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            let rect = self.contentView.convert(self.addMoneyButton.frame, to: self.scrollView)
            self.scrollView.scrollRectToVisible(rect, animated: false)
        }
    }
    
    @objc private func keyboardWillHide(_ note: Notification) {
        guard let userInfo = note.userInfo else { return }
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
}

extension TopUpViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.accounts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TopUpAccountCell.reuseId, for: indexPath) as! TopUpAccountCell
        let account = viewModel.accounts[indexPath.row]
        let isSelected = viewModel.selectedAccount?.id == account.id
        cell.configure(account: account, isSelected: isSelected)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectedAccount = viewModel.accounts[indexPath.row]
    }
}

private final class TopUpAccountCell: UITableViewCell {
    static let reuseId = "TopUpAccountCell"
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()
    private let balanceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    private let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = AppConstants.Colors.authInputBackground
        contentView.addSubview(titleLabel)
        contentView.addSubview(balanceLabel)
        contentView.addSubview(checkmark)
        checkmark.tintColor = AppConstants.Colors.mandarinOrange
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview().offset(-10)
        }
        balanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
        checkmark.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(account: Account, isSelected: Bool) {
        let symbol: String
        switch account.currency {
        case "AZN": symbol = "₼"
        case "USD": symbol = "$"
        default: symbol = account.currency
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        titleLabel.text = account.currency
        balanceLabel.text = (formatter.string(from: NSNumber(value: account.amount)) ?? "0.00") + " " + symbol
        checkmark.isHidden = !isSelected
    }
}
