import UIKit
import SnapKit
import Combine

final class EmailVerificationViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?

    private let viewModel: EmailVerificationViewModel
    private var cancellables = Set<AnyCancellable>()
    private var errorHeightConstraint: Constraint?

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
        title: "Verify your email",
        subtitle: ""
    )

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = AppConstants.Colors.authSubtitle
        label.numberOfLines = 0
        return label
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()

    private let verifiedButton = AuthPillButton(style: .filledPrimary, title: "I Verified")
    private let resendButton = InlineLinkButton(title: "Resend Email")

    init(viewModel: EmailVerificationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bodyLabel.text = viewModel.bodyText
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

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        verifiedButton.addTarget(self, action: #selector(verifiedTapped), for: .touchUpInside)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
    }

    private func addSubViews() {
        view.addSubview(backButton)
        view.addSubview(topRightImageView)
        view.addSubview(headerView)
        view.addSubview(bodyLabel)
        view.addSubview(errorLabel)
        view.addSubview(verifiedButton)
        view.addSubview(resendButton)
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

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(AppConstants.Spacing.extraLarge)
            make.leading.trailing.equalToSuperview().inset(h)
        }

        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(h)
            errorHeightConstraint = make.height.equalTo(0).constraint
        }

        verifiedButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(AppConstants.Spacing.large)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(AppConstants.Auth.primaryButtonHeight)
        }

        resendButton.snp.makeConstraints { make in
            make.top.equalTo(verifiedButton.snp.bottom).offset(AppConstants.Spacing.medium)
            make.leading.equalToSuperview().offset(h)
        }
    }

    private func bind() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.applyLoading(loading)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                if let message = message, !message.isEmpty {
                    self.errorLabel.textColor = self.viewModel.isResendSuccess ? .systemGreen : .systemRed
                    self.showError(message)
                } else {
                    self.clearError()
                }
            }
            .store(in: &cancellables)

        viewModel.$verifiedSuccess
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.coordinator?.showPersonalInfo()
            }
            .store(in: &cancellables)
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        errorHeightConstraint?.deactivate()
        UIView.animate(withDuration: AppConstants.Animation.mediumDuration) {
            self.view.layoutIfNeeded()
        }
    }

    private func clearError() {
        errorLabel.isHidden = true
        errorLabel.text = nil
        errorLabel.textColor = .systemRed
        errorHeightConstraint?.activate()
        UIView.animate(withDuration: AppConstants.Animation.mediumDuration) {
            self.view.layoutIfNeeded()
        }
    }

    private func applyLoading(_ loading: Bool) {
        verifiedButton.isEnabled = !loading
        verifiedButton.alpha = loading ? 0.6 : 1.0
        resendButton.isEnabled = !loading
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func verifiedTapped() {
        viewModel.clearError()
        Task {
            await viewModel.verify()
        }
    }

    @objc private func resendTapped() {
        viewModel.clearError()
        Task {
            await viewModel.resend()
        }
    }
}
