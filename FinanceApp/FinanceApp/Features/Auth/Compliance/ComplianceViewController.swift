import UIKit
import SnapKit
import Combine

final class ComplianceViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?

    private let viewModel: ComplianceViewModel
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
        title: "Almost there",
        subtitle: "Country and date of birth."
    )

    private let stepLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = AppConstants.Colors.authSubtitle
        label.text = "Step 3 of 4"
        return label
    }()

    private let countryTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppConstants.Colors.authTitle
        label.text = "Country"
        return label
    }()

    private let countryContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authInputBackground
        v.layer.borderWidth = 1
        v.layer.borderColor = AppConstants.Colors.authInputBorder.cgColor
        return v
    }()

    private let countryButton: UIButton = {
        let b = UIButton(type: .system)
        b.contentHorizontalAlignment = .left
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        b.setTitleColor(AppConstants.Colors.authPlaceholder, for: .normal)
        b.setTitle("Select country", for: .normal)
        return b
    }()

    private let birthdateTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppConstants.Colors.authTitle
        label.text = "Birthdate"
        return label
    }()

    private let birthdateContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authInputBackground
        v.layer.borderWidth = 1
        v.layer.borderColor = AppConstants.Colors.authInputBorder.cgColor
        return v
    }()

    private let birthdateButton: UIButton = {
        let b = UIButton(type: .system)
        b.contentHorizontalAlignment = .left
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        b.setTitleColor(AppConstants.Colors.authPlaceholder, for: .normal)
        b.setTitle("Select date", for: .normal)
        return b
    }()

    private lazy var datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())
        if #available(iOS 13.4, *) {
            p.preferredDatePickerStyle = .wheels
        }
        p.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        return p
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()

    private let nextButton = AuthPillButton(style: .filledPrimary, title: "Next")

    init(viewModel: ComplianceViewModel) {
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        countryContainerView.layer.cornerRadius = countryContainerView.bounds.height / 2
        birthdateContainerView.layer.cornerRadius = birthdateContainerView.bounds.height / 2
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            countryContainerView.layer.borderColor = AppConstants.Colors.authInputBorder
                .resolvedColor(with: traitCollection).cgColor
            birthdateContainerView.layer.borderColor = AppConstants.Colors.authInputBorder
                .resolvedColor(with: traitCollection).cgColor
        }
    }

    private func setupUI() {
        view.backgroundColor = AppConstants.Colors.authBackground

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        countryButton.addTarget(self, action: #selector(countryTapped), for: .touchUpInside)
        birthdateButton.addTarget(self, action: #selector(birthdateTapped), for: .touchUpInside)
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
        view.addSubview(countryTitleLabel)
        view.addSubview(countryContainerView)
        countryContainerView.addSubview(countryButton)
        view.addSubview(birthdateTitleLabel)
        view.addSubview(birthdateContainerView)
        birthdateContainerView.addSubview(birthdateButton)
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

        countryTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(stepLabel.snp.bottom).offset(AppConstants.Spacing.extraLarge)
            make.leading.trailing.equalToSuperview().inset(h)
        }

        countryContainerView.snp.makeConstraints { make in
            make.top.equalTo(countryTitleLabel.snp.bottom).offset(AppConstants.Spacing.small)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(AppConstants.Sizes.textFieldHeight)
        }

        countryButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }

        birthdateTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(countryContainerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(h)
        }

        birthdateContainerView.snp.makeConstraints { make in
            make.top.equalTo(birthdateTitleLabel.snp.bottom).offset(AppConstants.Spacing.small)
            make.leading.trailing.equalToSuperview().inset(h)
            make.height.equalTo(AppConstants.Sizes.textFieldHeight)
        }

        birthdateButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }

        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(birthdateContainerView.snp.bottom).offset(8)
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

        viewModel.$selectedCountry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] country in
                guard let self = self else { return }
                let title = country?.name ?? "Select country"
                let color = country != nil ? AppConstants.Colors.authTitle : AppConstants.Colors.authPlaceholder
                self.countryButton.setTitle(title, for: .normal)
                self.countryButton.setTitleColor(color, for: .normal)
            }
            .store(in: &cancellables)

        viewModel.$selectedDateOfBirth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                guard let self = self else { return }
                if let date = date {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    self.birthdateButton.setTitle(formatter.string(from: date), for: .normal)
                    self.birthdateButton.setTitleColor(AppConstants.Colors.authTitle, for: .normal)
                } else {
                    self.birthdateButton.setTitle("Select date", for: .normal)
                    self.birthdateButton.setTitleColor(AppConstants.Colors.authPlaceholder, for: .normal)
                }
            }
            .store(in: &cancellables)

        viewModel.$submitSuccess
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.coordinator?.showCompletionCheck()
            }
            .store(in: &cancellables)
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
        countryButton.isEnabled = !loading
        birthdateButton.isEnabled = !loading
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func countryTapped() {
        let sheet = UIAlertController(title: "Country", message: nil, preferredStyle: .actionSheet)
        for country in ComplianceViewModel.countries {
            let countryToSelect = country
            sheet.addAction(UIAlertAction(title: "\(country.flag) \(country.name)", style: .default) { [weak self] _ in
                self?.viewModel.setCountry(countryToSelect)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = countryButton
            popover.sourceRect = countryButton.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func birthdateTapped() {
        view.endEditing(true)
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.view.addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        vc.preferredContentSize = CGSize(width: view.bounds.width, height: 220)
        let nav = UINavigationController(rootViewController: vc)
        vc.navigationItem.title = "Birthdate"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(birthdateDoneTapped))
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(nav, animated: true)
    }

    @objc private func birthdateDoneTapped() {
        viewModel.setDateOfBirth(datePicker.date)
        dismiss(animated: true)
    }

    @objc private func datePickerChanged() {
        viewModel.setDateOfBirth(datePicker.date)
    }

    @objc private func nextTapped() {
        view.endEditing(true)
        viewModel.clearError()
        Task {
            await viewModel.submit()
        }
    }
}
