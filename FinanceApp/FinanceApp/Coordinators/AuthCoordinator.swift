import UIKit

class AuthCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: AppCoordinator?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        showLogin()
    }
    
    func showLogin() {
        let loginVC = LoginViewController()
        loginVC.coordinator = self
        navigationController.pushViewController(loginVC, animated: true)
    }
    
    func showSignup() {
        let signupVC = SignupViewController()
        signupVC.coordinator = self
        navigationController.pushViewController(signupVC, animated: true)
    }
    
    func showForgotPassword() {
        let forgotPasswordVC = ForgotPasswordViewController()
        forgotPasswordVC.coordinator = self
        navigationController.pushViewController(forgotPasswordVC, animated: true)
    }
    
    func showEmailVerification() {
        let emailVerificationVC = EmailVerificationViewController()
        emailVerificationVC.coordinator = self
        navigationController.pushViewController(emailVerificationVC, animated: true)
    }
    
    func didFinishAuth() {
        parentCoordinator?.showHome()
        parentCoordinator?.removeChild(self)
    }
}
