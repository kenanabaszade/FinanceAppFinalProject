//
//  AcceptTransferViewController.swift
//  FinanceApp
//

import UIKit
import SnapKit
import Combine

final class AcceptTransferViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?
    private let viewModel: AcceptTransferViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let senderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
    private let senderNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()
    private let amountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 36, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        return l
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
        l.text = "Receive into"
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
    private lazy var acceptButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Accept", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = 12
        b.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        return b
    }()
    private lazy var rejectButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Reject", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        b.setTitleColor(.secondaryLabel, for: .normal)
        b.addTarget(self, action: #selector(rejectTapped), for: .touchUpInside)
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
    private let emptyCardsLabel: UILabel = {
        let l = UILabel()
        l.text = "No card with matching currency. Add a card to receive."
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    init(viewModel: AcceptTransferViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Receive money"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .never
        setupLayout()
        bind()
        cardsTableView.delegate = self
        cardsTableView.dataSource = self
        cardsTableView.register(AcceptTransferCardCell.self, forCellReuseIdentifier: AcceptTransferCardCell.reuseId)
        Task { await viewModel.load() }
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(senderLabel)
        contentView.addSubview(senderNameLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(currencyLabel)
        contentView.addSubview(cardsSectionLabel)
        contentView.addSubview(cardsTableView)
        contentView.addSubview(emptyCardsLabel)
        contentView.addSubview(acceptButton)
        contentView.addSubview(rejectButton)
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
        senderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        senderNameLabel.snp.makeConstraints { make in
            make.top.equalTo(senderLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        amountLabel.snp.makeConstraints { make in
            make.top.equalTo(senderNameLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        currencyLabel.snp.makeConstraints { make in
            make.top.equalTo(amountLabel.snp.bottom).offset(8)
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
        emptyCardsLabel.snp.makeConstraints { make in
            make.top.equalTo(cardsSectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        acceptButton.snp.makeConstraints { make in
            make.top.equalTo(cardsTableView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(50)
        }
        rejectButton.snp.makeConstraints { make in
            make.top.equalTo(acceptButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-padding - 20)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(rejectButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func bind() {
        viewModel.$request
            .receive(on: DispatchQueue.main)
            .sink { [weak self] req in
                guard let self = self, let req = req else { return }
                self.senderLabel.text = "From"
                self.senderNameLabel.text = req.senderDisplayName
                self.amountLabel.text = self.viewModel.amountText
                self.currencyLabel.text = req.currency
            }
            .store(in: &cancellables)
        viewModel.$cardsWithBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
                guard let self = self else { return }
                let isEmpty = list.isEmpty
                self.emptyCardsLabel.isHidden = !isEmpty
                self.cardsTableView.isHidden = isEmpty
                self.cardsTableView.snp.updateConstraints { make in
                    make.height.equalTo(isEmpty ? 0 : CGFloat(list.count) * 72)
                }
                self.cardsTableView.reloadData()
            }
            .store(in: &cancellables)
        viewModel.$selectedCardWithBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.cardsTableView.reloadData()
            }
            .store(in: &cancellables)
        Publishers.CombineLatest(viewModel.$request, viewModel.$selectedCardWithBalance)
            .map { req, card in req != nil && req?.status == .pending && card != nil }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] can in
                self?.acceptButton.isEnabled = can
                self?.acceptButton.alpha = can ? 1 : 0.5
            }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.errorLabel.text = msg
                self?.errorLabel.isHidden = msg == nil || msg?.isEmpty == true
            }
            .store(in: &cancellables)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading { self?.activityIndicator.startAnimating() } else { self?.activityIndicator.stopAnimating() }
            }
            .store(in: &cancellables)
        viewModel.$acceptSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] success in
                guard success else { return }
                self?.showAcceptSuccessAndPop()
            }
            .store(in: &cancellables)
        viewModel.$rejectSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] success in
                guard success else { return }
                self?.showRejectSuccessAndPop()
            }
            .store(in: &cancellables)
    }

    private func showAcceptSuccessAndPop() {
        let alert = UIAlertController(
            title: "Received",
            message: "You received \(viewModel.amountText) \(viewModel.request?.currency ?? "") from \(viewModel.request?.senderDisplayName ?? "").",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.coordinator?.didFinishAcceptTransfer()
        })
        present(alert, animated: true)
    }

    private func showRejectSuccessAndPop() {
        let alert = UIAlertController(title: "Rejected", message: "You declined the transfer request.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.coordinator?.didFinishAcceptTransfer()
        })
        present(alert, animated: true)
    }

    @objc private func acceptTapped() {
        Task { await viewModel.accept() }
    }

    @objc private func rejectTapped() {
        Task { await viewModel.reject() }
    }
}

extension AcceptTransferViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.cardsWithBalance.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AcceptTransferCardCell.reuseId, for: indexPath) as! AcceptTransferCardCell
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

private final class AcceptTransferCardCell: UITableViewCell {
    static let reuseId = "AcceptTransferCardCell"
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
        subtitleLabel.text = currency
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        balanceLabel.text = (formatter.string(from: NSNumber(value: balance)) ?? "0.00") + " \(currency)"
        checkmark.isHidden = !isSelected
    }
}
