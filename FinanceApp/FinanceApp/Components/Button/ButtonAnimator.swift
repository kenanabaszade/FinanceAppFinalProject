import UIKit

struct ButtonAnimator {
    static func animatePress(_ button: UIButton, isPressed: Bool) {
        UIView.animate(withDuration: AppConstants.Animation.shortDuration) {
            if isPressed {
                button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                button.alpha = 0.8
            } else {
                button.transform = .identity
                button.alpha = 1.0
            }
        }
    }
}
