import UIKit
import SnapKit

class ForgotPasswordViewController: UIViewController {
    weak var coordinator: AuthCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Forgot Password"
    }
}
