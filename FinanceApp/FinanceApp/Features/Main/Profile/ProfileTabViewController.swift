//
//  ProfileTabViewController.swift
//  FinanceApp
//

import UIKit
import SnapKit
import Combine
import Photos

final class ProfileTabViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?
    private let viewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    private let navBar: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.dashboardBackground
        return v
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        b.tintColor = AppConstants.Colors.authTitle
        return b
    }()

    private let navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Profile"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()

    private let settingsButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        b.setImage(UIImage(systemName: "gearshape", withConfiguration: config), for: .normal)
        b.tintColor = AppConstants.Colors.authTitle
        return b
    }()

    private let cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = 24
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let avatarContainer: UIView = {
        let v = UIView()
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppConstants.Colors.authInputBackground
        iv.tintColor = AppConstants.Colors.authSubtitle
        iv.image = UIImage(systemName: "person.circle.fill")
        return iv
    }()

    private let cameraButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = AppConstants.Colors.mandarinOrange
        b.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        b.setImage(UIImage(systemName: "camera.fill", withConfiguration: config), for: .normal)
        return b
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = AppConstants.Colors.authTitle
        l.textAlignment = .center
        return l
    }()

    private let memberLabel: UILabel = {
        let l = UILabel()
        l.text = "Mandarin Plus Member"
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = AppConstants.Colors.mandarinOrange
        l.textAlignment = .center
        return l
    }()

    private let accountIdLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        l.textAlignment = .center
        return l
    }()

    private let menuStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        s.backgroundColor = .clear
        return s
    }()

    private let logoutButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = AppConstants.Colors.authInputBackground
        b.setTitle("Logout", for: .normal)
        b.setTitleColor(AppConstants.Colors.authTitle, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.layer.cornerRadius = AppConstants.Sizes.cornerRadius
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        b.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration: config), for: .normal)
        b.tintColor = AppConstants.Colors.authTitle
        b.semanticContentAttribute = .forceLeftToRight
        return b
    }()

    private let versionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        l.textAlignment = .center
        return l
    }()

    private let imageLoadingIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.hidesWhenStopped = true
        i.color = .white
        return i
    }()

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )
        setupUI()
        setupMenuRows()
        bind()
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        Task { await viewModel.loadUser() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await viewModel.loadUser() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
        cameraButton.layer.cornerRadius = cameraButton.bounds.width / 2
    }

    private func setupUI() {
        view.addSubview(navBar)
        navBar.addSubview(backButton)
        navBar.addSubview(navTitleLabel)
        navBar.addSubview(settingsButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(cardContainer)

        cardContainer.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(cameraButton)
        avatarContainer.addSubview(imageLoadingIndicator)
        cardContainer.addSubview(nameLabel)
        cardContainer.addSubview(memberLabel)
        cardContainer.addSubview(accountIdLabel)
        cardContainer.addSubview(menuStack)
        cardContainer.addSubview(logoutButton)
        cardContainer.addSubview(versionLabel)

        let h = AppConstants.Auth.horizontalPadding
        navBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(44)
        }
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(h)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        navTitleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        settingsButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(h)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        let cardHorizontalInset: CGFloat = 20
        let cardTopPadding: CGFloat = 24
        cardContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(cardTopPadding)
            make.leading.equalToSuperview().offset(cardHorizontalInset)
            make.trailing.equalToSuperview().inset(cardHorizontalInset)
            make.bottom.equalTo(contentView.snp.bottom).offset(-cardTopPadding)
        }

        let avatarSize: CGFloat = 100
        let cameraSize: CGFloat = 36
        let cardInnerPadding: CGFloat = 24
        avatarContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(cardInnerPadding + 8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        cameraButton.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
            make.width.height.equalTo(cameraSize)
        }
        imageLoadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(avatarImageView)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(cardInnerPadding)
        }
        memberLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(cardInnerPadding)
        }
        accountIdLabel.snp.makeConstraints { make in
            make.top.equalTo(memberLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(cardInnerPadding)
        }
        menuStack.snp.makeConstraints { make in
            make.top.equalTo(accountIdLabel.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(cardInnerPadding)
            make.trailing.equalToSuperview().inset(cardInnerPadding)
        }
        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(menuStack.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(cardInnerPadding)
            make.height.equalTo(52)
        }
        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(logoutButton.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-28)
        }

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "Version \(version) (AZN-PROD)"
        } else {
            versionLabel.text = "Version 1.0 (AZN-PROD)"
        }
    }

    private func setupMenuRows() {
        let rows: [(icon: String, title: String)] = [
            ("person", "Personal Information"),
            ("lock", "Security & Privacy"),
            ("creditcard", "Card Management"),
            ("bell", "Notifications"),
            ("questionmark.circle", "Help & Support")
        ]
        for (index, item) in rows.enumerated() {
            let row = makeMenuRow(icon: item.icon, title: item.title)
            menuStack.addArrangedSubview(row)
            if index < rows.count - 1 {
                let sep = UIView()
                sep.backgroundColor = AppConstants.Colors.authInputBorder
                sep.snp.makeConstraints { make in make.height.equalTo(1) }
                menuStack.addArrangedSubview(sep)
            }
        }
    }

    private func makeMenuRow(icon: String, title: String) -> UIView {
        let row = UIButton(type: .system)
        row.contentHorizontalAlignment = .left
        row.backgroundColor = .clear
        let container = UIView()
        row.addSubview(container)
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = AppConstants.Colors.mandarinOrange
        iconView.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppConstants.Colors.authTitle
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = AppConstants.Colors.authSubtitle
        chevron.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        container.addSubview(label)
        container.addSubview(chevron)
        iconView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(label.snp.trailing).offset(8)
            make.width.equalTo(12)
        }
        container.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        row.addAction(UIAction { [weak self] _ in self?.menuRowTapped(title: title) }, for: .touchUpInside)
        return row
    }

    private func bind() {
        viewModel.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.nameLabel.text = self?.viewModel.displayName ?? "—"
                self?.accountIdLabel.text = "Account ID: \(self?.viewModel.accountIdDisplay ?? "—")"
                self?.loadAvatarIfNeeded()
            }
            .store(in: &cancellables)

        viewModel.$isUploadingImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uploading in
                if uploading {
                    self?.imageLoadingIndicator.startAnimating()
                } else {
                    self?.imageLoadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self, let message = message, !message.isEmpty else { return }
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.viewModel.errorMessage = nil
                })
                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    private func loadAvatarIfNeeded() {
        if let base64 = viewModel.user?.profileImageBase64,
           let data = Data(base64Encoded: base64),
           let image = UIImage(data: data) {
            avatarImageView.image = image
            avatarImageView.contentMode = .scaleAspectFill
            return
        }
        guard let urlString = viewModel.user?.profileImageURL,
              let url = URL(string: urlString) else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.contentMode = .center
            return
        }
        avatarImageView.contentMode = .scaleAspectFill
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run { self.avatarImageView.image = image }
                }
            } catch {
                await MainActor.run {
                    self.avatarImageView.image = UIImage(systemName: "person.circle.fill")
                    self.avatarImageView.contentMode = .center
                }
            }
        }
    }

    private func menuRowTapped(title: String) {
        if title == "Notifications" {
            coordinator?.showNotificationsCenter()
            return
        }
        let alert = UIAlertController(title: title, message: "Coming soon.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    @objc private func cameraTapped() {
        let alert = UIAlertController(title: "Profile Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.requestCameraAndPresentPicker()
        })
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.requestPhotoLibraryAndPresentPicker()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = cameraButton
            pop.sourceRect = cameraButton.bounds
        }
        present(alert, animated: true)
    }

    private func requestCameraAndPresentPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(message: "Camera is not available on this device.")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.presentImagePicker(sourceType: .camera)
        }
    }

    private func requestPhotoLibraryAndPresentPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showAlert(message: "Photo library is not available.")
            return
        }
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.presentImagePicker(sourceType: .photoLibrary)
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.presentImagePicker(sourceType: .photoLibrary)
                    } else {
                        self?.showAlert(message: "Photo library access is needed to choose a profile picture. Enable it in Settings.")
                    }
                }
            }
        case .denied, .restricted:
            showAlert(message: "Photo library access was denied. Enable it in Settings to choose a profile picture.")
        @unknown default:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.presentImagePicker(sourceType: .photoLibrary)
            }
        }
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func logoutTapped() {
        coordinator?.logout()
    }

    @objc private func backTapped() {
        // Tab context: no-op or pop if embedded in nav
    }

    @objc private func settingsTapped() {
        menuRowTapped(title: "Settings")
    }
}

extension ProfileTabViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            showAlert(message: "Could not get the selected image.")
            return
        }
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            showAlert(message: "Could not process the image.")
            return
        }
        // Show chosen image immediately (optimistic update)
        avatarImageView.image = image
        avatarImageView.contentMode = .scaleAspectFill
        Task {
            await viewModel.uploadAndSetProfileImage(data)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
