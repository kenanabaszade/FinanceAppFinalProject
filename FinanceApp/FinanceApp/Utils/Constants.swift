import UIKit

enum AppConstants {
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let topOffset: CGFloat = 60
    }
    
    enum Sizes {
        static let textFieldHeight: CGFloat = 50
        static let buttonHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 12
    }
    
    enum Animation {
        static let shortDuration: TimeInterval = 0.1
        static let mediumDuration: TimeInterval = 0.3
        static let longDuration: TimeInterval = 0.8
    }
    
    enum Password {
        static let minimumLength = 6
    }
}
