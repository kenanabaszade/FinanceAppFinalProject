//
//  PersonalInfoViewController.swift
//  FinanceApp
//
//  Created by Macbook on 27.02.26.
//

import UIKit
import SnapKit
import Combine

final class PersonalInfoViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    
    private let viewModel: PersonalInfoViewModel
    private var cancellables = Set<AnyCancellable>()
    private var errorHeightConstraint: Constraint?
    
    private lazy var backButton: UIButton = AppConstants.makeBackButton()
    
    private let topRightImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "mandarinlaunch")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let headerView = AuthHeaderView(
        title: "Personal info",
        subtitle: "Tell us your name."
    )
    
    private let stepLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = AppConstants.Colors.authSubtitle
        label.text = "Step 2 of 4"
        return label
    }()
    
    private let firstNameField = AuthTextFieldView(
        style: .email,
        title: "First Name",
        placeholder: "John"
    )
    
    private let lastNameField = AuthTextFieldView(
        style: .email,
        title: "Last Name",
        placeholder: "Doe"
    )
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()
    
    private let nextButton = AuthPillButton(style: .filledPrimary, title: "Next")
    
    init(viewModel: PersonalInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addSubViews()
        setupConstraints()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupUI() {
        view.backgroundColor = AppConstants.Colors.authBackground
        
        firstNameField.textField.delegate = self
        lastNameField.textField.delegate = self
        firstNameField.textField.returnKeyType = .next
        lastNameField.textField.returnKeyType = .go
        firstNameField.textField.autocapitalizationType = .words
        lastNameField.textField.autocapitalizationType = .words
        
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func addSubViews() {
        view.addSubview(backButton)
        view.addSubview(topRightImageView)
        view.addSubview(headerView)
        view.addSubview(stepLabel)
        view.addSubview(firstNameField)
        view.addSubview(lastNameField)
        view.addSubview(errorLabel)
        view.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        let h = AppConstants.Auth.horizontalPadding
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppConstants.Spacing.medium)
            make.leading.equalToSuperview().offset(h)
            make.width.height.equalTo(AppConstants.Auth.iconButtonSize)
        }
        
        topRightImageView.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.trailing.equalToSuperview().offset(-h)
            make.width.height.equalTo(40)
        }
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(h)
        }
        
        stepLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(AppConstants.Spacing.small)
            make.leading.equalToSuperview().offset(h)
        }
        
        firstNameField.snp.makeConstraints { make in
            make.top.equalTo(stepLabel.snp.bottom).offset(AppConstants.Spacing.extraLarge)
            make.leading.trailing.equalToSuperview().inset(h)
        }
        
        lastNameField.snp.makeConstraints { make in
            make.top.equalTo(firstNameField.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(h)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(lastNameField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(h)
            errorHeightConstraint = make.height.equalTo(0).constraint
        }
        
        nextButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(AppConstants.Auth.primaryButtonHeight)
        }
    }
    
    private func bind() {
        firstNameField.onTextChange = { [weak self] _ in self?.viewModel.clearError() }
        lastNameField.onTextChange = { [weak self] _ in self?.viewModel.clearError() }
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.applyLoading(loading)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showError(message)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .filter { $0 == nil || $0?.isEmpty == true }
            .sink { [weak self] _ in
                self?.clearError()
            }
            .store(in: &cancellables)
        
        viewModel.$submitSuccess
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.coordinator?.showCompliance()
            }
            .store(in: &cancellables)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func clearError() {
        guard !errorLabel.isHidden else { return }
        errorLabel.isHidden = true
        errorLabel.text = nil
        errorHeightConstraint?.activate()
        UIView.animate(withDuration: AppConstants.Animation.mediumDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        errorHeightConstraint?.deactivate()
        UIView.animate(withDuration: AppConstants.Animation.mediumDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func applyLoading(_ loading: Bool) {
        nextButton.isEnabled = !loading
        nextButton.alpha = loading ? 0.6 : 1.0
        firstNameField.textField.isEnabled = !loading
        lastNameField.textField.isEnabled = !loading
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func nextTapped() {
        view.endEditing(true)
        let first = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        Task {
            await viewModel.submit(firstName: first, lastName: last)
        }
    }
}

extension PersonalInfoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === firstNameField.textField {
            lastNameField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            nextTapped()
        }
        return true
    }
}
