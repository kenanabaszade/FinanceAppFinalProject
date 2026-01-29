import UIKit
import SnapKit

class LoginViewController: UIViewController {
    weak var coordinator: AuthCoordinator?
    
    private let viewModel = LoginViewModel()
    
    private lazy var titleLabel = AppLabel(style: .title(), text: "Welcome Back")
    private lazy var subtitleLabel = AppLabel(style: .subtitle(), text: "Sign in to continue")
    private lazy var emailField = AppTextField(type: .email, placeholder: "Email", returnKeyType: .next)
    private lazy var passwordField = AppTextField(type: .password, placeholder: "Password", returnKeyType: .done)
    private lazy var loginButton = LoadingButton(style: .primary, title: "Login")
    private lazy var errorLabel = AppLabel(style: .error)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(loginButton)
        view.addSubview(errorLabel)
        
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppConstants.Spacing.topOffset)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.small)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
        }
        
        emailField.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(48)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
            make.height.equalTo(AppConstants.Sizes.textFieldHeight)
        }
        
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
            make.height.equalTo(AppConstants.Sizes.textFieldHeight)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
            make.height.equalTo(AppConstants.Sizes.buttonHeight)
        }
    }
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func bindViewModel() {
        viewModel.onLoginSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.handleLoginSuccess()
            }
        }
        
        viewModel.onLoginError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.handleLoginError(errorMessage)
            }
        }
        
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            DispatchQueue.main.async {
                self?.updateLoadingState(isLoading)
            }
        }
        
        viewModel.onEmailNotVerified = { [weak self] in
            DispatchQueue.main.async {
                self?.handleEmailNotVerified()
            }
        }
    }
    
    @objc private func loginButtonTapped() {
        dismissKeyboard()
        
        guard let email = emailField.text,
              let password = passwordField.text else {
            return
        }
        
        viewModel.login(email: email, password: password)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showError(_ message: String) {
        errorLabel.showError(message)
    }
    
    private func hideError() {
        errorLabel.hideError()
    }
    
    private func handleLoginSuccess() {
        hideError()
        coordinator?.didFinishAuth()
    }
    
    private func handleLoginError(_ errorMessage: String) {
        showError(errorMessage)
    }
    
    private func handleEmailNotVerified() {
        coordinator?.showEmailVerification()
    }
    
    private func updateLoadingState(_ isLoading: Bool) {
        loginButton.setLoading(isLoading)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        hideError()
    }
}
