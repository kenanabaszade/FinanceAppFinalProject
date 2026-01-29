import UIKit
import FirebaseAuth

class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
    }
    
    func start() {
        if let user = Auth.auth().currentUser, user.isEmailVerified {
            showHome()
        } else {
            showLaunchScreen()
        }
    }
    
    private func showLaunchScreen() {
        let launchVC = LaunchScreenViewController()
        launchVC.coordinator = self
        navigationController.setViewControllers([launchVC], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    func showOnboarding() {
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        onboardingCoordinator.parentCoordinator = self
        addChild(onboardingCoordinator)
        onboardingCoordinator.start()
    }
    
    func showAuth() {
        let authCoordinator = AuthCoordinator(navigationController: navigationController)
        authCoordinator.parentCoordinator = self
        addChild(authCoordinator)
        authCoordinator.start()
    }
    
    func showHome() {
        let homeVC = HomeViewController()
        navigationController.setViewControllers([homeVC], animated: true)
        navigationController.setNavigationBarHidden(false, animated: true)
    }
}
