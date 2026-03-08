//
//  MainTabBarController.swift
//  FinanceApp
//
//  Created by Macbook on 15.02.26.
//


import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    weak var coordinator: OnboardingCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTabBarAppearance()
        delegate = self
    }
    
    private func setupTabBarAppearance() {
        tabBar.isUserInteractionEnabled = true
        tabBar.isHidden = false
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = AppConstants.Colors.authSubtitle
        normal.titleTextAttributes = [
            .foregroundColor: AppConstants.Colors.authSubtitle,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = AppConstants.Colors.mandarinOrange
        selected.titleTextAttributes = [
            .foregroundColor: AppConstants.Colors.mandarinOrange,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        tabBar.layer.shadowOpacity = 1
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -1)
        tabBar.layer.shadowRadius = 8
        tabBar.clipsToBounds = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            tabBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.05)
                .resolvedColor(with: traitCollection).cgColor
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        true
    }
}
