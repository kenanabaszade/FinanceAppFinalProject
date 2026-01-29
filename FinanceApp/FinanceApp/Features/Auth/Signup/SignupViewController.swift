import UIKit
import SnapKit

class SignupViewController: UIViewController {
    weak var coordinator: AuthCoordinator?
    
    private let viewModel = SignupViewModel()
    
    private lazy var titleLabel = AppLabel(style: .title(), text: "Create Account")
    private lazy var subtitleLabel = AppLabel(style: .subtitle(), text: "Sign up to get started")
    private lazy var emailField = AppTextField(type: .email, placeholder: "Email", returnKeyType: .next)
    private lazy var passwordField = AppTextField(type: .password, placeholder: "Password", returnKeyType: .next)
    private lazy var confirmPasswordField = AppTextField(type: .password, placeholder: "Confirm Password", returnKeyType: .done)
    private lazy var signupButton = LoadingButton(style: .primary, title: "Sign Up")
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
        view.addSubview(confirmPasswordField)
        view.addSubview(signupButton)
        view.addSubview(errorLabel)
        
        emailField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
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
        
        confirmPasswordField.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
            make.height.equalTo(AppConstants.Sizes.textFieldHeight)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordField.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
        }
        
        signupButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
            make.height.equalTo(AppConstants.Sizes.buttonHeight)
        }
    }
    
    private func setupActions() {
        signupButton.addTarget(self, action: #selector(signupButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func bindViewModel() {
        viewModel.onSignupSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.handleSignupSuccess()
            }
        }
        
        viewModel.onSignupError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.handleSignupError(errorMessage)
            }
        }
        
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            DispatchQueue.main.async {
                self?.updateLoadingState(isLoading)
            }
        }
    }
    
    @objc private func signupButtonTapped() {
        dismissKeyboard()
        
        guard let email = emailField.text,
              let password = passwordField.text,
              let confirmPassword = confirmPasswordField.text else {
            return
        }
        
        viewModel.signup(email: email, password: password, confirmPassword: confirmPassword)
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
    
    private func handleSignupSuccess() {
        hideError()
        coordinator?.showEmailVerification()
    }
    
    private func handleSignupError(_ errorMessage: String) {
        showError(errorMessage)
    }
    
    private func updateLoadingState(_ isLoading: Bool) {
        signupButton.setLoading(isLoading)
    }
}

extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            confirmPasswordField.becomeFirstResponder()
        } else if textField == confirmPasswordField {
            signupButtonTapped()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        hideError()
    }
}
