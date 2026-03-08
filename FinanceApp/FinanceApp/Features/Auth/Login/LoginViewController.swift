import UIKit
import SnapKit
import Combine

final class LoginViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    
    private let viewModel: LoginViewModel
    private var cancellables = Set<AnyCancellable>()
    private var errorHeightConstraint: Constraint?
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var backButton: UIButton = AppConstants.makeBackButton()
    
    private let topRightImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "mandarinlaunch")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let headerView = AuthHeaderView(
        title: "Welcome back",
        subtitle: "Log in to your Mandarin account."
    )
    
    private let emailField = AuthTextFieldView(
        style: .email,
        title: "Email",
        placeholder: "name@example.com"
    )
    
    private let passwordField = AuthTextFieldView(
        style: .password(showToggle: true),
        title: "Password",
        placeholder: "••••••"
    )
    
    private let forgotPasswordButton = InlineLinkButton(title: "Forgot password?")
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()
    
    private let loginButton = AuthPillButton(style: .filledPrimary, title: "Sign In")
    
    private let dividerView = AuthDividerView()
    
    private let socialStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 20
        sv.alignment = .center
        return sv
    }()
    
    private let googleButton = AuthSocialIconButton(provider: .google)
    private let appleButton = AuthSocialIconButton(provider: .apple)
    
    private let bottomPromptView = AuthBottomPromptView(
        promptText: "Don't have an account?",
        actionTitle: "Sign up"
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupUI() {
        view.backgroundColor = AppConstants.Colors.authBackground
        addSubViews()
        
        emailField.textField.delegate = self
        passwordField.textField.delegate = self
        emailField.textField.returnKeyType = .next
        passwordField.textField.returnKeyType = .go
        
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(socialTapped(_:)), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(socialTapped(_:)), for: .touchUpInside)
        bottomPromptView.onAction = { [weak self] in self?.coordinator?.showSignup() }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func addSubViews() {
        view.addSubview(backButton)
        view.addSubview(topRightImageView)
        view.addSubview(headerView)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(forgotPasswordButton)
        view.addSubview(errorLabel)
        view.addSubview(loginButton)
        view.addSubview(dividerView)
        view.addSubview(socialStackView)
        socialStackView.addArrangedSubview(googleButton)
        socialStackView.addArrangedSubview(appleButton)
        view.addSubview(bottomPromptView)
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
        
        emailField.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(AppConstants.Spacing.extraLarge)
            make.leading.trailing.equalToSuperview().inset(h)
        }
        
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(h)
        }
        
        forgotPasswordButton.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(6)
            make.trailing.equalToSuperview().inset(h)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(forgotPasswordButton.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(h)
            errorHeightConstraint = make.height.equalTo(0).constraint
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(AppConstants.Auth.primaryButtonHeight)
        }
        
        dividerView.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(20)
        }
        
        socialStackView.snp.makeConstraints { make in
            make.top.equalTo(dividerView.snp.bottom).offset(h)
            make.centerX.equalToSuperview()
        }
        
        bottomPromptView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-AppConstants.Spacing.medium)
        }
    }
    
    private func bind() {
        emailField.onTextChange = { [weak self] _ in self?.viewModel.clearError() }
        passwordField.onTextChange = { [weak self] _ in self?.viewModel.clearError() }
        
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
        loginButton.isEnabled = !loading
        loginButton.alpha = loading ? 0.6 : 1.0
        emailField.textField.isEnabled = !loading
        passwordField.textField.isEnabled = !loading
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func forgotPasswordTapped() {
        view.endEditing(true)
        let alert = UIAlertController(
            title: "Reset Password",
            message: "Enter your email and we'll send you a link to reset your password.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "name@example.com"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.text = self.emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let email = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            Task {
                await self.viewModel.sendPasswordReset(email: email)
                await MainActor.run {
                    if self.viewModel.errorMessage == nil {
                        let successAlert = UIAlertController(
                            title: "Check your email",
                            message: "If an account exists for that email, you'll receive a link to reset your password.",
                            preferredStyle: .alert
                        )
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(successAlert, animated: true)
                    } else {
                        let errorAlert = UIAlertController(
                            title: "Reset failed",
                            message: self.viewModel.errorMessage,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.viewModel.clearError()
                        })
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })
        present(alert, animated: true)
    }
    
    @objc private func socialTapped(_ sender: UIButton) {}
    
    @objc private func loginTapped() {
        view.endEditing(true)
        
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        
        switch viewModel.validate(email: email, password: password) {
        case .valid:
            break
        case .invalidEmail:
            showError("Please enter a valid email address.")
            return
        case .invalidPassword:
            showError("Password must be at least \(AppConstants.Password.minimumLength) characters.")
            return
        case .invalidBoth:
            showError("Please enter a valid email and password.")
            return
        }
        
        clearError()
        
        Task {
            await viewModel.login(email: email, password: password)
            await MainActor.run {
                if viewModel.errorMessage == nil {
                    coordinator?.showMain()
                }
            }
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField.textField {
            passwordField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            loginTapped()
        }
        return true
    }
}
