//
//  RequestMoneyEnterAmountViewController.swift
//  FinanceApp
//
//  Created by Macbook on 2.27.26.
//

import UIKit
import SnapKit
import Combine

final class RequestMoneyEnterAmountViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    private let viewModel: RequestMoneyEnterAmountViewModel
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
        l.text = "AZN"
        l.font = .systemFont(ofSize: 17, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
    
    private let requestButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Request money", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.layer.cornerRadius = 12
        b.addTarget(RequestMoneyEnterAmountViewController.self, action: #selector(requestTapped), for: .touchUpInside)
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
    
    init(viewModel: RequestMoneyEnterAmountViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Request money"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .never
        setupLayout()
        
        recipientLabel.text = "Requesting from"
        recipientNameLabel.text = viewModel.recipient.displayName
        
        bind()
        amountField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        
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
        contentView.addSubview(requestButton)
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
            make.top.equalToSuperview().offset(48)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        recipientNameLabel.snp.makeConstraints { make in
            make.top.equalTo(recipientLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        amountField.snp.makeConstraints { make in
            make.top.equalTo(recipientNameLabel.snp.bottom).offset(48)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(48)
        }
        currencyLabel.snp.makeConstraints { make in
            make.top.equalTo(amountField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
        
        requestButton.snp.makeConstraints { make in
            make.top.equalTo(currencyLabel.snp.bottom).offset(64)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-padding - 20)
        }
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(requestButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func bind() {
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
        
        viewModel.$requestSuccess
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.showSuccessAndPop()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.activityIndicator.startAnimating()
                    self?.requestButton.isEnabled = false
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.requestButton.isEnabled = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func showSuccessAndPop() {
        let alert = UIAlertController(title: "Request Sent", message: "\(viewModel.recipient.displayName) will receive a notification to approve your request.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func amountChanged() {
        viewModel.amountText = amountField.text ?? ""
    }
    
    @objc private func requestTapped() {
        guard viewModel.canRequest else {
            let alert = UIAlertController(title: "Invalid Amount", message: "Please enter an amount greater than 0.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        Task {
            await viewModel.sendRequest()
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
            let rect = self.contentView.convert(self.requestButton.frame, to: self.scrollView)
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
