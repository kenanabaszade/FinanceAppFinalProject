import UIKit

enum AppConstants {
    
    static let appName = "Mandarin"
    
    enum Fonts {
        static var familyName: String? = "Montserrat"
        static func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            guard let name = familyName else {
                return .systemFont(ofSize: size, weight: weight)
            }
            let suffix: String
            switch weight {
            case .ultraLight: suffix = "ExtraLight"
            case .thin: suffix = "Thin"
            case .light: suffix = "Light"
            case .regular: suffix = "Regular"
            case .medium: suffix = "Medium"
            case .semibold: suffix = "SemiBold"
            case .bold: suffix = "Bold"
            case .heavy: suffix = "ExtraBold"
            case .black: suffix = "Black"
            default: suffix = "Regular"
            }
            let fullName = "\(name)-\(suffix)"
            if let custom = UIFont(name: fullName, size: size) { return custom }
            return .systemFont(ofSize: size, weight: weight)
        }
        static func title(size: CGFloat = 28) -> UIFont { font(size: size, weight: .bold) }
        static func headline(size: CGFloat = 22) -> UIFont { font(size: size, weight: .semibold) }
        static func body(size: CGFloat = 16) -> UIFont { font(size: size, weight: .regular) }
        static func bodyMedium(size: CGFloat = 16) -> UIFont { font(size: size, weight: .medium) }
        static func bodySemibold(size: CGFloat = 16) -> UIFont { font(size: size, weight: .semibold) }
        static func caption(size: CGFloat = 13) -> UIFont { font(size: size, weight: .regular) }
        static func captionMedium(size: CGFloat = 13) -> UIFont { font(size: size, weight: .medium) }
        static func small(size: CGFloat = 12) -> UIFont { font(size: size, weight: .medium) }
        static func button(size: CGFloat = 17) -> UIFont { font(size: size, weight: .semibold) }
    }
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    enum Sizes {
        static let textFieldHeight: CGFloat = 50
        static let buttonHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 12
        static let addCardButtonMinWidth: CGFloat = 160
    }
    
    enum Animation {
        static let mediumDuration: TimeInterval = 0.3
        static let launchDisplayDuration: TimeInterval = 1.5
    }
    
    enum Stories {
        static let storyDuration: TimeInterval = 4.0
        static let progressBarHeight: CGFloat = 3
        static let horizontalInset: CGFloat = 16
        static let contentHorizontalInset: CGFloat = 32
    }
    
    enum Password {
        static let minimumLength = 6
        static let signupMinimumLength = 8
    }
    
    enum Colors {
        private static func color(named name: String, default fallback: UIColor) -> UIColor {
            UIColor(named: name) ?? fallback
        }
        
        static let mandarinOrange    = color(named: "MandarinOrange", default: .systemOrange)
        static let mandarinLight            = color(named: "MandarinLight", default: .systemOrange.withAlphaComponent(0.6))
        static let mandarinDeep             = color(named: "MandarinDeep", default: .systemOrange.withAlphaComponent(0.8))
        
        static let authPrimary              = mandarinOrange
        
        static let authBackground           = color(named: "AuthBackground", default: .systemBackground)
        static let authCardBackground       = color(named: "AuthCardBackground", default: .secondarySystemBackground)
        static let authInputBackground      = color(named: "AuthInputBackground", default: .tertiarySystemBackground)
        static let authInputBorder          = color(named: "AuthInputBorder", default: .separator)
        static let authTitle                = color(named: "AuthTitle", default: .label)
        static let authSubtitle             = color(named: "AuthSubtitle", default: .secondaryLabel)
        static let authPlaceholder          = color(named: "AuthPlaceholder", default: .tertiaryLabel)
        static let authDividerText          = color(named: "AuthDividerText", default: .secondaryLabel)
        static let authDividerLine          = color(named: "AuthDividerLine", default: .separator)
        static let authBackButtonBackground = color(named: "AuthBackButtonBg", default: .tertiarySystemBackground)
        static let authSocialBackground     = color(named: "AuthSocialBg", default: .secondarySystemBackground)
        static let balanceCardText          = color(named: "BalanceCardText", default: .white) 
        static let dashboardBackground      = UIColor.systemGroupedBackground
        static let dashboardCardDark        = color(named: "DashboardCardDark", default: .secondarySystemBackground)
        static let transactionIconBg        = color(named: "TransactionIconBg", default: .tertiarySystemBackground)
    }
    
    enum Auth {
        static let cardCornerRadius: CGFloat = 28
        static let iconButtonSize: CGFloat = 44
        static let socialButtonSize: CGFloat = 56
        static let primaryButtonHeight: CGFloat = 54
        static let horizontalPadding: CGFloat = 24
    }
    
    enum Dashboard {
        static let balanceCardHeight: CGFloat = 220
        static let balanceCardCornerRadius: CGFloat = 20
        static let balanceCardPadding: CGFloat = 20
        static let brandCircleSize: CGFloat = 36
        static let brandCircleCornerRadius: CGFloat = 18
        static let quickActionCircleSize: CGFloat = 56
        static let quickActionContainerWidth: CGFloat = 72
        static let cardCellCornerRadius: CGFloat = 20
        static let cardNumberFontSize: CGFloat = 14
        static let expiryFontSize: CGFloat = 12
        static let transactionRowHeight: CGFloat = 66
        static let transactionIconSize: CGFloat = 44
        static let notificationBellSize: CGFloat = 44
        static let pageActiveDotSize: CGFloat = 8
        static let pageInactiveDotSize: CGFloat = 6
        static let pageDotSpacing: CGFloat = 6
    }
    
    enum History {
        static let transactionLimit: Int = 100
        static let rowHeight: CGFloat = 70
        static let iconSize: CGFloat = 44
        static let searchBarHeight: CGFloat = 48
        static let searchBarCornerRadius: CGFloat = 24
        static let filterPillHeight: CGFloat = 36
    }
    
    enum Notifications {
        static let limit: Int = 50
        static let rowHeight: CGFloat = 96
        static let iconSize: CGFloat = 44
        static let cardCornerRadius: CGFloat = 14
        static let cardVerticalSpacing: CGFloat = 10
        static let horizontalInset: CGFloat = 20
        static let cardInnerPadding: CGFloat = 16
    }
}
  
extension AppConstants {
    static func makeBackButton() -> UIButton {
        let b = UIButton(type: .system)
        b.backgroundColor = Colors.authBackButtonBackground
        b.layer.cornerRadius = Auth.iconButtonSize / 2
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        b.tintColor = Colors.authTitle
        b.bounds = CGRect(origin: .zero, size: CGSize(width: Auth.iconButtonSize, height: Auth.iconButtonSize))
        return b
    }
}
