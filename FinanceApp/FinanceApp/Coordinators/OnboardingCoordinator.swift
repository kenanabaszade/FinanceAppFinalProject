import UIKit

class OnboardingCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: AppCoordinator?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let onboardingVC = OnboardingViewController()
        onboardingVC.coordinator = self
        navigationController.setViewControllers([onboardingVC], animated: true)
        navigationController.setNavigationBarHidden(true, animated: false)
    }
    
    func showLogin() {
        let authCoordinator = AuthCoordinator(navigationController: navigationController)
        authCoordinator.parentCoordinator = parentCoordinator
        parentCoordinator?.addChild(authCoordinator)
        authCoordinator.showLogin()
    }
    
    func showSignup() {
        let authCoordinator = AuthCoordinator(navigationController: navigationController)
        authCoordinator.parentCoordinator = parentCoordinator
        parentCoordinator?.addChild(authCoordinator)
        authCoordinator.showSignup()
    }
    
    func showForgotPassword() {
        let authCoordinator = AuthCoordinator(navigationController: navigationController)
        authCoordinator.parentCoordinator = parentCoordinator
        parentCoordinator?.addChild(authCoordinator)
        authCoordinator.showForgotPassword()
    }
}
