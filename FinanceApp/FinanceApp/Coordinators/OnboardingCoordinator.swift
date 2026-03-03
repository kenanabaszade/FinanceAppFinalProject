import UIKit
import FirebaseAuth

class OnboardingCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    private let container: ServiceContainerProtocol

    init(navigationController: UINavigationController, container: ServiceContainerProtocol) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        navigate(to: .welcome)
    }

    func startResuming(user: User) {
        switch user.onboardingStep {
        case 1:
            navigate(to: .emailVerification(email: user.email ?? ""), replaceStack: true)
        case 2:
            navigate(to: .personalInfo, replaceStack: true)
        case 3:
            navigate(to: .compliance, replaceStack: true)
        case 4:
            runCompletionCheckThenMain()
        case 5:
            navigate(to: .main)
        default:
            navigate(to: .welcome)
        }
        navigationController.setNavigationBarHidden(true, animated: false)
        if let window = navigationController.view.window {
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
    }

    func navigate(to route: OnboardingRoute, replaceStack: Bool = false) {
        let vc: UIViewController
        switch route {
        case .welcome:
            vc = OnboardingViewController()
            (vc as? OnboardingViewController)?.coordinator = self
            vc.loadViewIfNeeded()
            navigationController.setViewControllers([vc], animated: false)
            navigationController.setNavigationBarHidden(true, animated: false)
            if let window = navigationController.view.window {
                window.rootViewController = navigationController
                window.makeKeyAndVisible()
            }
            return
        case .login:
            let vm = LoginViewModel(authService: container.authService)
            vc = LoginViewController(viewModel: vm)
            (vc as? LoginViewController)?.coordinator = self
        case .signup:
            let vm = SignupViewModel(authService: container.authService, firestoreService: container.firestoreService)
            vc = SignupViewController(viewModel: vm)
            (vc as? SignupViewController)?.coordinator = self
        case .emailVerification(let email):
            let vm = EmailVerificationViewModel(
                email: email,
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            vc = EmailVerificationViewController(viewModel: vm)
            (vc as? EmailVerificationViewController)?.coordinator = self
        case .personalInfo:
            let vm = PersonalInfoViewModel(
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            vc = PersonalInfoViewController(viewModel: vm)
            (vc as? PersonalInfoViewController)?.coordinator = self
        case .compliance:
            let vm = ComplianceViewModel(
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            vc = ComplianceViewController(viewModel: vm)
            (vc as? ComplianceViewController)?.coordinator = self
        case .cardDetail(let card):
            let detailVC = CardDetailViewController(
                card: card,
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            detailVC.coordinator = self
            detailVC.hidesBottomBarWhenPushed = true
            if let tabBar = navigationController.viewControllers.last as? MainTabBarController,
               let mainNav = tabBar.viewControllers?.first as? UINavigationController {
                mainNav.pushViewController(detailVC, animated: true)
            }
            return
        case .addCard:
            let vm = AddCardViewModel(
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            let addVC = AddCardViewController(viewModel: vm)
            addVC.coordinator = self
            addVC.hidesBottomBarWhenPushed = true
            if let tabBar = navigationController.viewControllers.last as? MainTabBarController,
               let mainNav = tabBar.viewControllers?.first as? UINavigationController {
                mainNav.pushViewController(addVC, animated: true)
            }
            return
        case .sendMoney:
            let vm = SendMoneyViewModel(
                authService: container.authService,
                firestoreService: container.firestoreService,
                contactsService: container.contactsService
            )
            vc = SendMoneyViewController(viewModel: vm)
            (vc as? SendMoneyViewController)?.coordinator = self
            vc.hidesBottomBarWhenPushed = true
            if let tabBar = navigationController.viewControllers.last as? MainTabBarController,
               let mainNav = tabBar.viewControllers?.first as? UINavigationController {
                mainNav.pushViewController(vc, animated: true)
            }
            return
        case .enterAmount(let recipient):
            let vm = EnterAmountViewModel(
                recipient: recipient,
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            vc = EnterAmountViewController(viewModel: vm)
            (vc as? EnterAmountViewController)?.coordinator = self
            vc.hidesBottomBarWhenPushed = true
            if let tabBar = navigationController.viewControllers.last as? MainTabBarController,
               let mainNav = tabBar.viewControllers?.first as? UINavigationController {
                mainNav.pushViewController(vc, animated: true)
            }
            return
        case .acceptTransfer(let requestId):
            let vm = AcceptTransferViewModel(
                requestId: requestId,
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            let vc = AcceptTransferViewController(viewModel: vm)
            vc.coordinator = self
            vc.hidesBottomBarWhenPushed = true
            if let tabBar = navigationController.viewControllers.last as? MainTabBarController,
               let nav = tabBar.selectedViewController as? UINavigationController {
                nav.pushViewController(vc, animated: true)
            }
            return
        case .notificationsCenter:
            let vm = NotificationsViewModel(
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            let notifVC = NotificationsViewController(viewModel: vm)
            notifVC.coordinator = self
            notifVC.hidesBottomBarWhenPushed = true
            if let tabBar = navigationController.viewControllers.last as? MainTabBarController,
               let nav = tabBar.selectedViewController as? UINavigationController {
                nav.pushViewController(notifVC, animated: true)
            }
            return
        case .completionCheck:
            runCompletionCheckThenMain()
            return
        case .main:
            let vm = MainViewModel(
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            let mainVC = MainViewController(viewModel: vm)
            mainVC.coordinator = self
            let mainNav = UINavigationController(rootViewController: mainVC)
            mainNav.tabBarItem = UITabBarItem(
                title: "Home",
                image: UIImage(systemName: "house"),
                selectedImage: UIImage(systemName: "house.fill")
            )
            mainNav.setNavigationBarHidden(true, animated: false)

            let paymentsVM = PaymentsViewModel(
                authService: container.authService,
                firestoreService: container.firestoreService
            )
            let paymentsVC = PaymentsViewController(viewModel: paymentsVM)
            paymentsVC.coordinator = self
            let payNav = UINavigationController(rootViewController: paymentsVC)
            payNav.setNavigationBarHidden(true, animated: false)
            payNav.tabBarItem = UITabBarItem(
                title: "Payments",
                image: UIImage(systemName: "wallet.pass"),
                selectedImage: UIImage(systemName: "wallet.pass.fill")
            )

            let topUpViewModel = TopUpViewModel(authService: container.authService, firestoreService: container.firestoreService)
            let topUpVC = TopUpViewController(viewModel: topUpViewModel)
            let topUpNav = UINavigationController(rootViewController: topUpVC)
            topUpNav.tabBarItem = UITabBarItem(
                title: "Top Up",
                image: UIImage(systemName: "plus.circle"),
                selectedImage: UIImage(systemName: "plus.circle.fill")
            )

            let historyVM = HistoryViewModel(authService: container.authService, firestoreService: container.firestoreService)
            let historyVC = HistoryViewController(viewModel: historyVM)
            historyVC.coordinator = self
            let historyNav = UINavigationController(rootViewController: historyVC)
            historyNav.tabBarItem = UITabBarItem(
                title: "Tarixçə",
                image: UIImage(systemName: "clock.arrow.circlepath"),
                selectedImage: UIImage(systemName: "clock.arrow.circlepath")
            )

            let profileVM = ProfileViewModel(
                authService: container.authService,
                firestoreService: container.firestoreService,
                storageService: container.storageService
            )
            let profileVC = ProfileTabViewController(viewModel: profileVM)
            profileVC.coordinator = self
            let profileNav = UINavigationController(rootViewController: profileVC)
            profileNav.tabBarItem = UITabBarItem(
                title: "Profile",
                image: UIImage(systemName: "person"),
                selectedImage: UIImage(systemName: "person.fill")
            )

            let tabBar = MainTabBarController()
            tabBar.coordinator = self
            tabBar.setViewControllers([mainNav, payNav, topUpNav, historyNav, profileNav], animated: false)
            tabBar.selectedIndex = 0

            navigationController.setViewControllers([tabBar], animated: true)
            navigationController.setNavigationBarHidden(true, animated: false)
            return
        case .logout:
            do {
                try container.authService.signOut()
            } catch {}
            UserCache.shared.clearCache()
            let welcomeVC = OnboardingViewController()
            (welcomeVC as OnboardingViewController).coordinator = self
            welcomeVC.loadViewIfNeeded()
            navigationController.setViewControllers([welcomeVC], animated: true)
            navigationController.setNavigationBarHidden(true, animated: false)
            return
        }

        if replaceStack {
            navigationController.setViewControllers([vc], animated: false)
        } else {
            navigationController.pushViewController(vc, animated: true)
        }
    }

    private func runCompletionCheckThenMain() {
        guard let uid = Auth.auth().currentUser?.uid else {
            navigate(to: .main)
            return
        }
        Task { @MainActor in
            do {
                guard var user = try await container.firestoreService.getUser(uid: uid) else {
                    navigate(to: .main)
                    return
                }
                guard user.isEmailVerified == true,
                      user.firstName != nil,
                      user.country != nil,
                      user.dateOfBirth != nil else {
                    navigate(to: .main)
                    return
                }
                user.onboardingStep = 5
                try await container.firestoreService.updateUser(user)
                navigate(to: .main)
            } catch {
                navigate(to: .main)
            }
        }
    }
}

extension OnboardingCoordinator {

    func showLogin() { navigate(to: .login) }
    func showSignup() { navigate(to: .signup) }
    func showEmailVerification(email: String) { navigate(to: .emailVerification(email: email)) }
    func showPersonalInfo() { navigate(to: .personalInfo) }
    func showCompliance() { navigate(to: .compliance) }
    func showCompletionCheck() { navigate(to: .completionCheck) }
    func showMain() { navigate(to: .main) }
    func showCardDetail(card: Card) { navigate(to: .cardDetail(card: card)) }
    func showAddCard() { navigate(to: .addCard) }
    func didFinishAddCard() {
        if let tabBar = navigationController.viewControllers.last as? MainTabBarController,
           let mainNav = tabBar.viewControllers?.first as? UINavigationController {
            mainNav.popViewController(animated: true)
        }
    }
    func didFinishAcceptTransfer() {
        if let tabBar = navigationController.viewControllers.last as? MainTabBarController,
           let nav = tabBar.selectedViewController as? UINavigationController {
            nav.popViewController(animated: true)
        }
    }
    func showSendMoney() { navigate(to: .sendMoney) }
    func showEnterAmount(recipient: SendMoneyRecipient) { navigate(to: .enterAmount(recipient: recipient)) }
    func showEnterPayment(category: PaymentCategory) {
        guard let tabBar = navigationController.viewControllers.last as? MainTabBarController,
              let payNav = tabBar.viewControllers?[1] as? UINavigationController else { return }
        let vm = EnterPaymentViewModel(
            category: category,
            authService: container.authService,
            firestoreService: container.firestoreService
        )
        let vc = EnterPaymentViewController(viewModel: vm)
        vc.coordinator = self
        vc.hidesBottomBarWhenPushed = true
        payNav.pushViewController(vc, animated: true)
    }
    func openInviteToContact(recipient: SendMoneyRecipient) {
        let appName = AppConstants.appName
        let inviteText = "Join me on \(appName) – the smart way to send and manage money. Download here: https://apps.apple.com/app/idYOUR_APP_ID"
        let encoded = inviteText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inviteText
        let phone = recipient.phone?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = phone.isEmpty ? "sms:&body=\(encoded)" : "sms:\(phone)&body=\(encoded)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    func showNotificationsCenter() { navigate(to: .notificationsCenter) }
    func showAcceptTransfer(requestId: String) { navigate(to: .acceptTransfer(requestId: requestId)) }
    func logout() { navigate(to: .logout) }
}
