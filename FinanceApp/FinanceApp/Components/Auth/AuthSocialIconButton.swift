import UIKit
import SnapKit

final class AuthSocialIconButton: UIButton {

    enum Provider {
        case google
        case apple
    }

    private let iconContainer: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()

    init(provider: Provider) {
        super.init(frame: .zero)
        backgroundColor = AppConstants.Colors.authSocialBackground
        layer.cornerRadius = AppConstants.Auth.socialButtonSize / 2
        layer.borderWidth = 1
        layer.borderColor = AppConstants.Colors.authInputBorder.cgColor

        addSubview(iconContainer)
        iconContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        switch provider {
        case .google:
            let label = UILabel()
            label.text = "G"
            label.font = .systemFont(ofSize: 22, weight: .bold)
            label.textColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1)
            label.textAlignment = .center
            iconContainer.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        case .apple:
            let iv = UIImageView()
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            iv.image = UIImage(systemName: "apple.logo", withConfiguration: config)
            iv.tintColor = AppConstants.Colors.authTitle
            iv.contentMode = .scaleAspectFit
            iconContainer.addSubview(iv)
            iv.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        snp.makeConstraints { make in
            make.width.height.equalTo(AppConstants.Auth.socialButtonSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = AppConstants.Colors.authInputBorder
                .resolvedColor(with: traitCollection).cgColor
        }
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.6 : 1
        }
    }
}
