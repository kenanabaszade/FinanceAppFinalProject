//
//  LaunchScreenViewController.swift
//  FinanceApp
//
//  Created by Macbook on 26.01.26.
//

import UIKit
import SnapKit

class LaunchScreenViewController: UIViewController {
    weak var coordinator: AppCoordinator?
    
    // MARK: - UI Components
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.35, green: 0.20, blue: 0.85, alpha: 1.0).cgColor,
            UIColor(red: 0.25, green: 0.45, blue: 0.95, alpha: 1.0).cgColor,
            UIColor(red: 0.15, green: 0.60, blue: 1.0, alpha: 1.0).cgColor
        ]
        layer.locations = [0.0, 0.5, 1.0]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "dollarsign.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "FinanceApp"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.text = "Manage your finances smarter"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    // Animated circles for background effect
    private let circle1: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 100
        return view
    }()
    
    private let circle2: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        view.layer.cornerRadius = 150
        return view
    }()
    
    private let circle3: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        view.layer.cornerRadius = 200
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAnimations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(circle3)
        view.addSubview(circle2)
        view.addSubview(circle1)
        view.addSubview(logoImageView)
        view.addSubview(appNameLabel)
        view.addSubview(taglineLabel)
        
        // Initial states for animation
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3).rotated(by: -CGFloat.pi / 4)
        
        appNameLabel.alpha = 0
        appNameLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        
        taglineLabel.alpha = 0
        taglineLabel.transform = CGAffineTransform(translationX: 0, y: 20)
    }
    
    private func setupConstraints() {
        // Logo
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.width.height.equalTo(120)
        }
        
        // App Name
        appNameLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        // Tagline
        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(appNameLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        // Animated Circles
        circle1.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-50)
            make.centerY.equalToSuperview().offset(100)
            make.width.height.equalTo(200)
        }
        
        circle2.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(80)
            make.centerY.equalToSuperview().offset(-150)
            make.width.height.equalTo(300)
        }
        
        circle3.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-100)
            make.centerY.equalToSuperview().offset(200)
            make.width.height.equalTo(400)
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Animate background circles (pulsing effect)
        animateCircles()
        
        // Logo animation: scale + rotate + fade in
        UIView.animate(withDuration: 1.2, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.logoImageView.alpha = 1
            self.logoImageView.transform = .identity
        }
        
        // App name fade in
        UIView.animate(withDuration: 0.8, delay: 0.6, options: .curveEaseOut) {
            self.appNameLabel.alpha = 1
            self.appNameLabel.transform = .identity
        }
        
        // Tagline fade in
        UIView.animate(withDuration: 0.8, delay: 0.8, options: .curveEaseOut) {
            self.taglineLabel.alpha = 1
            self.taglineLabel.transform = .identity
        }
        
        // Logo rotation animation (continuous)
        rotateLogo()
        
        // Transition to onboarding after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.transitionToOnboarding()
        }
    }
    
    private func animateCircles() {
        // Circle 1 animation
        UIView.animate(withDuration: 3.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.circle1.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.circle1.alpha = 0.3
        }, completion: nil)
        
        // Circle 2 animation
        UIView.animate(withDuration: 4.0, delay: 0.5, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.circle2.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.circle2.alpha = 0.2
        }, completion: nil)
        
        // Circle 3 animation
        UIView.animate(withDuration: 5.0, delay: 1.0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.circle3.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.circle3.alpha = 0.15
        }, completion: nil)
    }
    
    private func rotateLogo() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 20.0
        rotation.repeatCount = .infinity
        logoImageView.layer.add(rotation, forKey: "rotation")
    }
    
    private func transitionToOnboarding() {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            self.coordinator?.showOnboarding()
        }
    }
}

