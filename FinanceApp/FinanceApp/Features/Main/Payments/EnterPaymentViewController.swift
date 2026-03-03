//
//  EnterPaymentViewController.swift
//  FinanceApp
//

import UIKit
import SnapKit
import Combine

final class EnterPaymentViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?
    private let viewModel: EnterPaymentViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.keyboardDismissMode = .onDrag
        return sv
    }()
    private let contentView = UIView()

    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.text = "Paying"
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        l.textAlignment = .center
        return l
    }()

    private let categoryNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        l.textAlignment = .center
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

    private let referenceSectionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()

    private let referenceContainerView: UIView = {
        let v = UIView()
        return v
    }()

    private let prefixButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        b.setTitleColor(AppConstants.Colors.authTitle, for: .normal)
        b.backgroundColor = AppConstants.Colors.authInputBackground
        b.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        b.contentHorizontalAlignment = .center
        return b
    }()

    private let referenceField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 17, weight: .regular)
        tf.textColor = AppConstants.Colors.authTitle
        tf.backgroundColor = AppConstants.Colors.authInputBackground
        tf.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.rightViewMode = .always
        return tf
    }()

    private let accountsSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "Pay from"
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

    private let payButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Pay", for: .normal)
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

    init(viewModel: EnterPaymentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        title = "Payment"
        navigationController?.setNavigationBarHidden(false, animated: false)
        categoryNameLabel.text = viewModel.category.name
        setupLayout()
        setupReferenceInput()
        bind()
        amountField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        referenceField.addTarget(self, action: #selector(referenceChanged), for: .editingChanged)
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)
        accountsTableView.delegate = self
        accountsTableView.dataSource = self
        accountsTableView.register(AccountSelectionCell.self, forCellReuseIdentifier: AccountSelectionCell.reuseId)
        Task { await viewModel.loadAccounts() }
        updatePayButton()
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(categoryNameLabel)
        contentView.addSubview(amountField)
        contentView.addSubview(currencyLabel)
        contentView.addSubview(referenceSectionLabel)
        contentView.addSubview(referenceContainerView)
        referenceContainerView.addSubview(referenceField)
        contentView.addSubview(accountsSectionLabel)
        contentView.addSubview(accountsTableView)
        contentView.addSubview(payButton)
        contentView.addSubview(errorLabel)
        view.addSubview(activityIndicator)

        let padding: CGFloat = AppConstants.Auth.horizontalPadding
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        categoryLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        categoryNameLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        amountField.snp.makeConstraints { make in
            make.top.equalTo(categoryNameLabel.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(56)
        }
        currencyLabel.snp.makeConstraints { make in
            make.top.equalTo(amountField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
        referenceSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(currencyLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        referenceContainerView.snp.makeConstraints { make in
            make.top.equalTo(referenceSectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(56)
        }
        referenceField.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        accountsSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(referenceContainerView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        accountsTableView.snp.makeConstraints { make in
            make.top.equalTo(accountsSectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(0)
        }
        payButton.snp.makeConstraints { make in
            make.top.equalTo(accountsTableView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().offset(-24)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(payButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func bind() {
        viewModel.$accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                self?.accountsTableView.reloadData()
                self?.updateAccountsTableHeight(count: accounts.count)
                if self?.viewModel.selectedAccount == nil, let first = accounts.first {
                    self?.viewModel.selectedAccount = first
                }
            }
            .store(in: &cancellables)
        viewModel.$selectedAccount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.accountsTableView.reloadData()
                self?.updateCurrencyLabel()
                self?.updatePayButton()
            }
            .store(in: &cancellables)
        viewModel.$amountText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updatePayButton() }
            .store(in: &cancellables)
        viewModel.$referenceText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updatePayButton() }
            .store(in: &cancellables)
        viewModel.$phonePrefix
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updatePayButton() }
            .store(in: &cancellables)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading { self?.activityIndicator.startAnimating() } else { self?.activityIndicator.stopAnimating() }
                self?.payButton.isEnabled = !loading
            }
            .store(in: &cancellables)
        viewModel.$didSucceed
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in self?.showSuccessAndPop() }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.errorLabel.text = msg
                self?.errorLabel.isHidden = msg == nil || msg?.isEmpty == true
            }
            .store(in: &cancellables)
    }

    private func setupReferenceInput() {
        referenceSectionLabel.text = viewModel.category.inputLabel
        switch viewModel.category.inputKind {
        case .phoneWithPrefix(let prefixes):
            referenceField.placeholder = "e.g. 123 45 67"
            referenceField.keyboardType = .phonePad
            referenceContainerView.addSubview(prefixButton)
            prefixButton.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalTo(100)
            }
            referenceField.snp.remakeConstraints { make in
                make.leading.equalTo(prefixButton.snp.trailing).offset(8)
                make.trailing.top.bottom.equalToSuperview()
            }
            if viewModel.phonePrefix.isEmpty, let first = prefixes.first {
                viewModel.phonePrefix = first
            }
            prefixButton.setTitle(viewModel.phonePrefix, for: .normal)
            prefixButton.addTarget(self, action: #selector(prefixTapped), for: .touchUpInside)
        case .singleLine(let placeholder, let keyboardNumber):
            referenceField.placeholder = placeholder
            referenceField.keyboardType = keyboardNumber ? .numberPad : .default
        }
    }

    @objc private func prefixTapped() {
        guard case .phoneWithPrefix(let prefixes) = viewModel.category.inputKind else { return }
        let sheet = UIAlertController(title: "Select prefix", message: nil, preferredStyle: .actionSheet)
        for p in prefixes {
            sheet.addAction(UIAlertAction(title: p, style: .default) { [weak self] _ in
                self?.viewModel.phonePrefix = p
                self?.prefixButton.setTitle(p, for: .normal)
                self?.updatePayButton()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = prefixButton
            popover.sourceRect = prefixButton.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func referenceChanged() {
        viewModel.referenceText = referenceField.text ?? ""
    }

    private func updateAccountsTableHeight(count: Int) {
        let h = count * 56
        accountsTableView.snp.updateConstraints { make in
            make.height.equalTo(max(0, h))
        }
    }

    private func updateCurrencyLabel() {
        currencyLabel.text = viewModel.selectedAccount?.currency ?? "AZN"
    }

    private func updatePayButton() {
        payButton.isEnabled = viewModel.canPay
        payButton.alpha = viewModel.canPay ? 1 : 0.6
    }

    private func showSuccessAndPop() {
        let alert = UIAlertController(title: "Payment successful", message: "Amount deducted from your balance.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func amountChanged() {
        viewModel.amountText = amountField.text ?? ""
    }

    @objc private func payTapped() {
        Task { await viewModel.pay() }
    }
}

extension EnterPaymentViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.accounts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountSelectionCell.reuseId, for: indexPath) as! AccountSelectionCell
        let account = viewModel.accounts[indexPath.row]
        let isSelected = viewModel.selectedAccount?.id == account.id
        cell.configure(account: account, isSelected: isSelected)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 56 }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedAccount = viewModel.accounts[indexPath.row]
    }
}

private final class AccountSelectionCell: UITableViewCell {
    static let reuseId = "AccountSelectionCell"
    private let titleLabel = UILabel()
    private let balanceLabel = UILabel()
    private let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = AppConstants.Colors.authInputBackground
        contentView.addSubview(titleLabel)
        contentView.addSubview(balanceLabel)
        contentView.addSubview(checkmark)
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = AppConstants.Colors.authTitle
        balanceLabel.font = .systemFont(ofSize: 15, weight: .regular)
        balanceLabel.textColor = AppConstants.Colors.authSubtitle
        checkmark.tintColor = AppConstants.Colors.mandarinOrange
        checkmark.contentMode = .scaleAspectFit
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        balanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        checkmark.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(account: Account, isSelected: Bool) {
        titleLabel.text = account.currency
        balanceLabel.text = String(format: "%.2f", account.amount)
        checkmark.isHidden = !isSelected
    }
}
