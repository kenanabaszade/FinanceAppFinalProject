//
//  ProfilePersonalInfoViewController.swift
//  FinanceApp
//
//  Created by Macbook on 2.24.26.
//

import UIKit
import SnapKit
import Combine

final class ProfilePersonalInfoViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?
    private let viewModel: ProfilePersonalInfoViewModel
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
        l.text = "Şəxsi məlumatlar"
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

    private let activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()

    init(viewModel: ProfilePersonalInfoViewModel) {
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
        Task { await viewModel.load() }
    }

    private func setupLayout() {
        view.addSubview(cardView)
        cardView.addSubview(backCircleButton)
        cardView.addSubview(titleLabel)
        cardView.addSubview(rowsStack)
        view.addSubview(activityIndicator)

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

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // Static row titles; values are bound from view model
        addRow(title: "Ad", value: viewModel.firstName, isEmailRow: false)
        addRow(title: "Soyad", value: viewModel.lastName, isEmailRow: false)
        addRow(title: "Ata adı", value: viewModel.fatherName, isEmailRow: false)
        addRow(title: "Doğulduğu ölkə", value: viewModel.countryOfBirth, isEmailRow: false)
        addRow(title: "Doğum tarixi", value: viewModel.dateOfBirthText, isEmailRow: false)
        addRow(title: "E-poçt", value: viewModel.email, isEmailRow: true)
    }

    private func addRow(title: String, value: String, isEmailRow: Bool) {
        let row = UIView()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .regular)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        row.addSubview(titleLabel)
        row.addSubview(valueLabel)

        var gearView: UIView?
        if isEmailRow {
            let gear = UIImageView(image: UIImage(systemName: "gearshape.fill"))
            gear.tintColor = AppConstants.Colors.mandarinOrange
            row.addSubview(gear)
            gear.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalTo(18)
            }
            gearView = gear
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            if let gear = gearView {
                make.trailing.equalTo(gear.snp.leading).offset(-6)
            } else {
                make.trailing.equalToSuperview()
            }
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        row.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        row.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        rowsStack.addArrangedSubview(row)
    }

    private func bind() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading { self?.activityIndicator.startAnimating() } else { self?.activityIndicator.stopAnimating() }
            }
            .store(in: &cancellables)

        viewModel.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Rebuild rows with latest values
                self.rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
                self.addRow(title: "Ad", value: self.viewModel.firstName, isEmailRow: false)
                self.addRow(title: "Soyad", value: self.viewModel.lastName, isEmailRow: false)
                self.addRow(title: "Ata adı", value: self.viewModel.fatherName, isEmailRow: false)
                self.addRow(title: "Doğulduğu ölkə", value: self.viewModel.countryOfBirth, isEmailRow: false)
                self.addRow(title: "Doğum tarixi", value: self.viewModel.dateOfBirthText, isEmailRow: false)
                self.addRow(title: "E-poçt", value: self.viewModel.email, isEmailRow: true)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                guard let self = self, let msg = msg, !msg.isEmpty else { return }
                let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.viewModel.clearError()
                })
                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

