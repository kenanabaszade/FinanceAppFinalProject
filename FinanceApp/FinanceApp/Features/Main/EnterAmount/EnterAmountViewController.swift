//
//  EnterAmountViewController.swift
//  FinanceApp
//
//  Created by Macbook on 28.02.26.
//


import UIKit
import SnapKit
import Combine

final class EnterAmountViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    private let viewModel: EnterAmountViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.keyboardDismissMode = .onDrag
        return sv
    }()
    private let contentView = UIView()
    
    private let recipientLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
    private let recipientNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()
    private let amountField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "0.00"
        tf.font = .systemFont(ofSize: 36, weight: .semibold)
        tf.keyboardType = .decimalPad
        tf.textAlignment = .center
        tf.textColor = .label
        return tf
    }()
    private let currencyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
    private let cardsSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "From"
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }()
    private let cardsTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.isScrollEnabled = false
        tv.backgroundColor = .secondarySystemGroupedBackground
        tv.layer.cornerRadius = 12
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return tv
    }()
    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Send money", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = 12
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
    
    private let cardsEmptyContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()
    
    private let cardsEmptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Add a card to send money"
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    private lazy var cardsEmptyAddButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add card", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = 12
        b.addTarget(self, action: #selector(addCardFromEnterAmountTapped), for: .touchUpInside)
        return b
    }()
    
    init(viewModel: EnterAmountViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Send money"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .never
        setupLayout()
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        recipientLabel.text = "Sending to"
        recipientNameLabel.text = viewModel.recipient.displayName
        currencyLabel.text = viewModel.selectedCardWithBalance?.currency ?? "AZN"
        bind()
        amountField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        cardsTableView.delegate = self
        cardsTableView.dataSource = self
        cardsTableView.register(CardSelectionCell.self, forCellReuseIdentifier: CardSelectionCell.reuseId)
        Task { await viewModel.loadCardsAndAccounts() }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(recipientLabel)
        contentView.addSubview(recipientNameLabel)
        contentView.addSubview(amountField)
        contentView.addSubview(currencyLabel)
        contentView.addSubview(cardsSectionLabel)
        contentView.addSubview(cardsTableView)
        contentView.addSubview(cardsEmptyContainer)
        cardsEmptyContainer.addSubview(cardsEmptyLabel)
        cardsEmptyContainer.addSubview(cardsEmptyAddButton)
        contentView.addSubview(sendButton)
        contentView.addSubview(errorLabel)
        view.addSubview(activityIndicator)
        
        let padding: CGFloat = 20
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        recipientLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        recipientNameLabel.snp.makeConstraints { make in
            make.top.equalTo(recipientLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        amountField.snp.makeConstraints { make in
            make.top.equalTo(recipientNameLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(48)
        }
        currencyLabel.snp.makeConstraints { make in
            make.top.equalTo(amountField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
        cardsSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(currencyLabel.snp.bottom).offset(28)
            make.leading.equalToSuperview().inset(padding)
        }
        cardsTableView.snp.makeConstraints { make in
            make.top.equalTo(cardsSectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(72)
        }
        cardsEmptyContainer.snp.makeConstraints { make in
            make.top.equalTo(cardsSectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(120)
        }
        cardsEmptyLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        cardsEmptyAddButton.snp.makeConstraints { make in
            make.top.equalTo(cardsEmptyLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(160)
            make.height.equalTo(48)
            make.bottom.lessThanOrEqualToSuperview()
        }
        sendButton.snp.makeConstraints { make in
            make.top.equalTo(cardsTableView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-padding - 20)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(sendButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await viewModel.loadCardsAndAccounts() }
    }
    
    private func bind() {
        viewModel.$cardsWithBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
                guard let self = self else { return }
                let isEmpty = list.isEmpty
                self.cardsEmptyContainer.isHidden = !isEmpty
                self.cardsTableView.isHidden = isEmpty
                self.cardsTableView.reloadData()
                self.updateCardsTableHeight(count: list.count)
            }
            .store(in: &cancellables)
        viewModel.$selectedCardWithBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.cardsTableView.reloadData()
                self?.currencyLabel.text = self?.viewModel.selectedCardWithBalance?.currency ?? "AZN"
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
        viewModel.$transferSuccess
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.showSuccessAndPop()
            }
            .store(in: &cancellables)
    }
    
    private func updateCardsTableHeight(count: Int) {
        let h = min(220, CGFloat(max(1, count)) * 72)
        cardsTableView.snp.updateConstraints { make in make.height.equalTo(h) }
    }
    
    private func showSuccessAndPop() {
        let alert = UIAlertController(title: "Request Sent", message: "\(viewModel.recipient.displayName) will receive a notification to choose which card to receive the money.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func amountChanged() {
        viewModel.amountText = amountField.text ?? ""
    }
    
    @objc private func addCardFromEnterAmountTapped() {
        coordinator?.showAddCard()
    }
    
    @objc private func sendTapped() {
        sendButton.isEnabled = false
        activityIndicator.startAnimating()
        Task {
            await viewModel.sendTransfer()
            await MainActor.run {
                self.activityIndicator.stopAnimating()
                self.sendButton.isEnabled = true
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
            let rect = self.contentView.convert(self.sendButton.frame, to: self.scrollView)
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

extension EnterAmountViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.cardsWithBalance.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CardSelectionCell.reuseId, for: indexPath) as! CardSelectionCell
        let item = viewModel.cardsWithBalance[indexPath.row]
        let isSelected = viewModel.selectedCardWithBalance?.card.id == item.card.id
        cell.configure(card: item.card, balance: item.balance, currency: item.currency, isSelected: isSelected)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectedCardWithBalance = viewModel.cardsWithBalance[indexPath.row]
    }
}

private final class CardSelectionCell: UITableViewCell {
    static let reuseId = "CardSelectionCell"
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        return l
    }()
    private let balanceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        return l
    }()
    private let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(balanceLabel)
        contentView.addSubview(checkmark)
        checkmark.tintColor = AppConstants.Colors.mandarinOrange
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(12)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
        balanceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(checkmark.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        checkmark.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(card: Card, balance: Double, currency: String, isSelected: Bool) {
        titleLabel.text = "\(card.name) •••• \(card.lastFourDigits)"
        subtitleLabel.text = "\(currency)"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        balanceLabel.text = (formatter.string(from: NSNumber(value: balance)) ?? "0.00") + " \(currency)"
        checkmark.isHidden = !isSelected
    }
}
