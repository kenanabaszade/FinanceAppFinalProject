//
//  SettingsViewController.swift
//  FinanceApp
//
//  Created by Macbook on 2.28.26.
//

import UIKit
import SnapKit
import Combine

final class SettingsViewController: UIViewController {
    
    weak var coordinator: OnboardingCoordinator?
    private let viewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 28
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.25).cgColor
        v.layer.shadowOpacity = 0.18
        v.layer.shadowOffset = CGSize(width: 0, height: 8)
        v.layer.shadowRadius = 20
        return v
    }()
    
    private lazy var backCircleButton: UIButton = AppConstants.makeBackButton()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Tənzimləmələr"
        l.font = .systemFont(ofSize: 26, weight: .bold)
        l.textColor = .label
        return l
    }()
    
    private let rowsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        return s
    }()
    
    private var darkModeToggle: UISwitch?
    private var pushToggle: UISwitch?
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupLayout()
        bind()
        backCircleButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }
    
    private func setupLayout() {
        view.addSubview(cardView)
        cardView.addSubview(backCircleButton)
        cardView.addSubview(titleLabel)
        cardView.addSubview(rowsStack)
        
        let padding: CGFloat = 12
        cardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(padding)
        }
        
        backCircleButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(padding)
            make.leading.equalToSuperview().offset(padding)
            make.width.height.equalTo(AppConstants.Auth.iconButtonSize)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backCircleButton.snp.bottom).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        
        rowsStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.bottom.equalToSuperview().inset(padding)
        }
        
        addAppearanceRow()
        addNotificationsRow()
        addLanguageRow()
        addTestNotificationRow()
    }
    
    private func addAppearanceRow() {
        let toggle = UISwitch()
        toggle.onTintColor = AppConstants.Colors.mandarinOrange
        toggle.isOn = viewModel.darkModeOn
        toggle.addTarget(self, action: #selector(darkModeChanged(_:)), for: .valueChanged)
        darkModeToggle = toggle
        addSettingsRow(
            icon: "moon.fill",
            title: "Görünüş",
            subtitle: "Qaranlıq rejim",
            rightView: toggle
        )
    }
    
    private func addNotificationsRow() {
        let toggle = UISwitch()
        toggle.onTintColor = AppConstants.Colors.mandarinOrange
        toggle.isOn = viewModel.pushNotificationsOn
        toggle.addTarget(self, action: #selector(pushNotificationsChanged(_:)), for: .valueChanged)
        pushToggle = toggle
        addSettingsRow(
            icon: "bell.fill",
            title: "Bildirişlər",
            subtitle: "Push bildirişləri",
            rightView: toggle
        )
    }
    
    private func addLanguageRow() {
        let label = UILabel()
        label.text = viewModel.languageDisplay
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = AppConstants.Colors.authSubtitle
        chevron.contentMode = .scaleAspectFit
        let stack = UIStackView(arrangedSubviews: [label, chevron])
        stack.spacing = 6
        stack.axis = .horizontal
        chevron.snp.makeConstraints { make in make.width.equalTo(12) }
        addSettingsRow(
            icon: "globe",
            title: "Dil",
            subtitle: "Tətbiq dili",
            rightView: stack,
            isTappable: true
        ) { [weak self] in
            self?.languageRowTapped()
        }
    }
    
    private func addTestNotificationRow() {
        let label = UILabel()
        label.text = "Send test"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppConstants.Colors.mandarinOrange
        addSettingsRow(
            icon: "bell.badge",
            title: "Test notification",
            subtitle: "Sends a local notification in 5 seconds",
            rightView: label,
            isTappable: true
        ) { [weak self] in
            self?.sendTestNotificationTapped()
        }
    }
    
    private func addSettingsRow(
        icon: String,
        title: String,
        subtitle: String,
        rightView: UIView,
        isTappable: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        let row = UIView()
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = AppConstants.Colors.mandarinOrange
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        
        iconView.snp.makeConstraints { make in make.width.height.equalTo(24) }
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.spacing = 2
        textStack.axis = .vertical
        textStack.alignment = .leading
        
        let mainRow = UIStackView(arrangedSubviews: [iconView, textStack, rightView])
        mainRow.spacing = 12
        mainRow.axis = .horizontal
        mainRow.alignment = .center
        
        row.addSubview(mainRow)
        mainRow.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }
        
        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        row.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        row.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(52)
        }
        
        if isTappable, let onTap = onTap {
            let button = UIButton(type: .system)
            button.backgroundColor = .clear
            button.addAction(UIAction { _ in onTap() }, for: .touchUpInside)
            row.addSubview(button)
            button.snp.makeConstraints { make in make.edges.equalToSuperview() }
        }
        
        rowsStack.addArrangedSubview(row)
    }
    
    private func languageRowTapped() {
        let alert = UIAlertController(
            title: "Dil",
            message: "Tətbiq dili dəstəyi tezliklə əlavə ediləcək.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func sendTestNotificationTapped() {
        viewModel.scheduleTestNotification { [weak self] success, message in
            let alert = UIAlertController(
                title: success ? "Test scheduled" : "Cannot send test",
                message: message ?? (success ? nil : "Unknown error"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    private func bind() {
        viewModel.$darkModeOn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] on in
                self?.darkModeToggle?.setOn(on, animated: true)
            }
            .store(in: &cancellables)
        
        viewModel.$pushNotificationsOn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] on in
                self?.pushToggle?.setOn(on, animated: true)
            }
            .store(in: &cancellables)
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func darkModeChanged(_ sender: UISwitch) {
        viewModel.setDarkMode(sender.isOn, window: view.window)
    }
    
    @objc private func pushNotificationsChanged(_ sender: UISwitch) {
        viewModel.setPushNotifications(sender.isOn) { [weak self] granted in
            if sender.isOn && !granted {
                let alert = UIAlertController(
                    title: nil,
                    message: "Bildirişlər üçün icazə lazımdır. Ayarlar > Mandarin > Bildirişlər bölməsindən aktiv edin.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
}
