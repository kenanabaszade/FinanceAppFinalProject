import UIKit

final class InlineLinkButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = AppConstants.Colors.mandarinOrange
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
        config.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 14, weight: .medium)
            ])
        )
        configuration = config
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
