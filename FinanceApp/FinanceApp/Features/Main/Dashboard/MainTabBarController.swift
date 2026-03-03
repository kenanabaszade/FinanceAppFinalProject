import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    weak var coordinator: OnboardingCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        setupTabBarAppearance()
        delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let tw = view.bounds.width
        let th = view.bounds.height
        let barH = tabBar.frame.height
        guard barH > 0 else {
            view.bringSubviewToFront(tabBar)
            return
        }
        let bg = AppConstants.Colors.dashboardBackground
        for subview in view.subviews where subview !== tabBar {
            subview.backgroundColor = bg
            subview.frame = CGRect(x: 0, y: 0, width: tw, height: th - barH)
            break
        }
        tabBar.frame = CGRect(x: 0, y: th - barH, width: tw, height: barH)
        view.bringSubviewToFront(tabBar)
    }

    private func setupTabBarAppearance() {
        tabBar.isUserInteractionEnabled = true
        tabBar.isHidden = false

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppConstants.Colors.authCardBackground
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

    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        true
    }
}
