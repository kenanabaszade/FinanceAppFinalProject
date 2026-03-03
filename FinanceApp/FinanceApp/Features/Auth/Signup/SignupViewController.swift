import UIKit
import SnapKit
import Combine

final class SignupViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?

    private let viewModel: SignupViewModel
    private var cancellables = Set<AnyCancellable>()
    private var errorHeightConstraint: Constraint?

    init(viewModel: SignupViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        b.setImage(UIImage(systemName: "arrow.left", withConfiguration: config), for: .normal)
        b.tintColor = AppConstants.Colors.authTitle
        b.backgroundColor = AppConstants.Colors.authBackButtonBackground
        b.layer.cornerRadius = AppConstants.Auth.iconButtonSize / 2
        return b
    }()

    private let topRightImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "mandarinlaunch")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let headerView = AuthHeaderView(
        title: "Create account",
        subtitle: "Enter your email and password."
    )

    private let stepLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = AppConstants.Colors.authSubtitle
        label.text = "Step 1 of 4"
        return label
    }()

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

    private let confirmPasswordField = AuthTextFieldView(
        style: .password(showToggle: true),
        title: "Confirm Password",
        placeholder: "••••••"
    )

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()

    private let createAccountButton = AuthPillButton(style: .filledPrimary, title: "Create Account")

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

        emailField.textField.delegate = self
        passwordField.textField.delegate = self
        confirmPasswordField.textField.delegate = self
        emailField.textField.returnKeyType = .next
        passwordField.textField.returnKeyType = .next
        confirmPasswordField.textField.returnKeyType = .go

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func addSubViews() {
        view.addSubview(backButton)
        view.addSubview(topRightImageView)
        view.addSubview(headerView)
        view.addSubview(stepLabel)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(confirmPasswordField)
        view.addSubview(errorLabel)
        view.addSubview(createAccountButton)
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

        emailField.snp.makeConstraints { make in
            make.top.equalTo(stepLabel.snp.bottom).offset(AppConstants.Spacing.extraLarge)
            make.leading.trailing.equalToSuperview().inset(h)
        }

        passwordField.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(h)
        }

        confirmPasswordField.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(h)
        }

        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(h)
            errorHeightConstraint = make.height.equalTo(0).constraint
        }

        createAccountButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(AppConstants.Auth.primaryButtonHeight)
        }
    }

    private func bind() {
        emailField.onTextChange = { [weak self] _ in self?.viewModel.clearError() }
        passwordField.onTextChange = { [weak self] _ in self?.viewModel.clearError() }
        confirmPasswordField.onTextChange = { [weak self] _ in self?.viewModel.clearError() }

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
        createAccountButton.isEnabled = !loading
        createAccountButton.alpha = loading ? 0.6 : 1.0
        emailField.textField.isEnabled = !loading
        passwordField.textField.isEnabled = !loading
        confirmPasswordField.textField.isEnabled = !loading
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func createAccountTapped() {
        view.endEditing(true)

        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        let confirm = confirmPasswordField.text ?? ""

        switch viewModel.validate(email: email, password: password, confirmPassword: confirm) {
        case .valid:
            break
        case .invalidEmail:
            showError("Please enter a valid email address.")
            return
        case .invalidPassword:
            showError("Password must be at least \(AppConstants.Password.signupMinimumLength) characters.")
            return
        case .passwordMismatch:
            showError("Passwords do not match.")
            return
        case .invalidMultiple:
            showError("Please enter a valid email and matching passwords (min \(AppConstants.Password.signupMinimumLength) characters).")
            return
        }

        clearError()

        Task {
            await viewModel.createAccount(email: email, password: password)
            await MainActor.run {
                if viewModel.errorMessage == nil {
                    coordinator?.showEmailVerification(email: email)
                }
            }
        }
    }
}

extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField.textField {
            passwordField.textField.becomeFirstResponder()
        } else if textField === passwordField.textField {
            confirmPasswordField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            createAccountTapped()
        }
        return true
    }
}
