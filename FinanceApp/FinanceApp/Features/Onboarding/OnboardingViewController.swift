//
//  OnboardingViewController.swift
//  FinanceApp
//
//  Created by Macbook on 26.01.26.
//

import UIKit
import SnapKit

class OnboardingViewController: UIViewController {
    weak var coordinator: OnboardingCoordinator?

    private let storiesView: StoriesView = {
        let view = StoriesView()
        return view
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        return view
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "mandarinlaunch")
        return imageView
    }()

    private let buttonContainerView: UIView = {
        let v = UIView()
        return v
    }()

    private let buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = AppConstants.Spacing.medium
        stack.distribution = .fillEqually
        return stack
    }()

    private let loginButton = AuthPillButton(style: .filledPrimary, title: "Login")
    private let signUpButton = AuthPillButton(style: .filledDark, title: "Sign up")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    }

    @objc private func signUpTapped() {
        coordinator?.showSignup()
    }

    @objc private func loginTapped() {
        coordinator?.showLogin()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        storiesView.startStories()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        storiesView.pauseStories()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        storiesView.resumeStories()
    }

    private func setupUI() {
        view.backgroundColor = AppConstants.Colors.authBackground
        addSubViews()
        setupConstraints()
        addAnimations()
    }

    private func addSubViews() {
        view.addSubview(storiesView)
        view.addSubview(overlayView)
        view.addSubview(logoImageView)
        view.addSubview(buttonContainerView)
        buttonContainerView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(loginButton)
        buttonStackView.addArrangedSubview(signUpButton)
    }

    private func setupConstraints() {
        storiesView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(140)
        }

        buttonContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(120)
        }

        buttonStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.extraLarge)
            make.centerY.equalToSuperview()
            make.height.equalTo(AppConstants.Sizes.buttonHeight + 8)
        }
    }

    private func addAnimations() {
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(translationX: 0, y: 20)

        UIView.animate(withDuration: 0.8, delay: 0.2, options: .curveEaseOut) {
            self.logoImageView.alpha = 1
            self.logoImageView.transform = .identity
        }
    }
}
