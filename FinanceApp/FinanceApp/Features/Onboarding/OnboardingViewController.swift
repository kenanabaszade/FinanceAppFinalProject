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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "dollarsign.circle.fill")
        imageView.tintColor = .white
        return imageView
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let signupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot Password?", for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.8), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
       
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
        view.backgroundColor = .systemBackground
        addSubViews()
        setupConstraints()
        setupActions()
        addAnimations()
    }
    
    private func addSubViews() {
        view.addSubview(storiesView)
        view.addSubview(overlayView)
        view.addSubview(logoImageView)
        view.addSubview(buttonStackView)
        view.addSubview(forgotPasswordButton)
        
        buttonStackView.addArrangedSubview(signupButton)
        buttonStackView.addArrangedSubview(loginButton)

    }
    
    private func setupConstraints() {
        storiesView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(80)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalTo(forgotPasswordButton.snp.top).offset(-24)
            signupButton.snp.makeConstraints { make in
                make.height.equalTo(56)
            }
            loginButton.snp.makeConstraints { make in
                make.height.equalTo(56)
            }
        }
        
        forgotPasswordButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-32)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }
    }
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        signupButton.addTarget(self, action: #selector(signupButtonTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordButtonTapped), for: .touchUpInside)
        
        [loginButton, signupButton, forgotPasswordButton].forEach { button in
            button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
    }
    
    private func addAnimations() {
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(translationX: 0, y: 20)
        
        [buttonStackView, forgotPasswordButton].forEach { view in
            view.alpha = 0
            view.transform = CGAffineTransform(translationX: 0, y: 30)
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.2, options: .curveEaseOut) {
            self.logoImageView.alpha = 1
            self.logoImageView.transform = .identity
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.6, options: .curveEaseOut) {
            self.buttonStackView.alpha = 1
            self.buttonStackView.transform = .identity
            self.forgotPasswordButton.alpha = 1
            self.forgotPasswordButton.transform = .identity
        }
    }
    
    @objc private func loginButtonTapped() {
        coordinator?.showLogin()
    }
    
    @objc private func signupButtonTapped() {
        coordinator?.showSignup()
    }
    
    @objc private func forgotPasswordButtonTapped() {
        coordinator?.showForgotPassword()
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        ButtonAnimator.animatePress(sender, isPressed: true)
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        ButtonAnimator.animatePress(sender, isPressed: false)
    }
}

