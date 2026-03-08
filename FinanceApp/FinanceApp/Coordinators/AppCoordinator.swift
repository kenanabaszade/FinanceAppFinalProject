import UIKit
import FirebaseAuth

class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let window: UIWindow
    private let container: ServiceContainerProtocol
    
    init(window: UIWindow, container: ServiceContainerProtocol) {
        self.window = window
        self.container = container
        self.navigationController = UINavigationController()
    }
    
    func start() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
            return
        }
        
        showLaunchScreen()
    }
    
    private func showLaunchScreen() {
        let launchVC = LaunchScreenViewController()
        launchVC.coordinator = self
        navigationController.setViewControllers([launchVC], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.isHidden.toggle()
    }
    
    func continueAfterLaunch() {
        guard Auth.auth().currentUser != nil else {
            showOnboarding()
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            showOnboarding()
            return
        }
        Task {
            do {
                let user = try await container.firestoreService.getUser(uid: uid)
                await MainActor.run {
                    if let user = user {
                        showOnboardingResuming(user: user)
                    } else {
                        showOnboarding()
                    }
                }
            } catch {
                await MainActor.run { showOnboarding() }
            }
        }
    }
    
    func showOnboarding() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showOnboarding()
            }
            return
        }
        
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController, container: container)
        addChild(onboardingCoordinator)
        onboardingCoordinator.start()
    }
    
    private func showOnboardingResuming(user: User) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showOnboardingResuming(user: user)
            }
            return
        }
        
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController, container: container)
        addChild(onboardingCoordinator)
        onboardingCoordinator.startResuming(user: user)
    }
     
    func onOnboardingDidFinish(_ coordinator: OnboardingCoordinator) {
        removeChild(coordinator)
    }
}
