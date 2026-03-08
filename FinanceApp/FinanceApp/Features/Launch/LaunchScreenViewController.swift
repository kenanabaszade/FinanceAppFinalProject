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
    
    private let gradientLayer = CAGradientLayer()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "mandarinlaunch")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = AppConstants.appName
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyGradientColors()
        }
    }
    
    private func setupUI() {
        view.layer.insertSublayer(gradientLayer, at: 0)
        applyGradientColors()
        addSubViews()
        
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        appNameLabel.alpha = 0
        appNameLabel.transform = CGAffineTransform(translationX: 0, y: 20)
    }
    
    private func addSubViews() {
        view.addSubview(logoImageView)
        view.addSubview(appNameLabel)
    }
    
    private func setupConstraints() {
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.width.height.equalTo(280)
        }
        
        appNameLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
    }
    
    private func applyGradientColors() {
        let black = UIColor.black.cgColor
        let orange = AppConstants.Colors.mandarinDeep.resolvedColor(with: traitCollection).cgColor
        gradientLayer.colors = [black, orange]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }
    
    private func startAnimations() {
        UIView.animate(withDuration: 1.2, delay: 0.2,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) {
            self.logoImageView.alpha = 1
            self.logoImageView.transform = .identity
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.6, options: .curveEaseOut) {
            self.appNameLabel.alpha = 1
            self.appNameLabel.transform = .identity
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Animation.launchDisplayDuration) { [weak self] in
            self?.transitionToOnboarding()
        }
    }
    
    private func transitionToOnboarding() {
        DispatchQueue.main.async { [weak self] in
            self?.coordinator?.continueAfterLaunch()
        }
    }
}
