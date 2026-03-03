import UIKit
import SnapKit

final class AuthBottomPromptView: UIView {

    var onAction: (() -> Void)?

    init(promptText: String, actionTitle: String) {
        super.init(frame: .zero)

        let label = UILabel()
        label.text = promptText
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = AppConstants.Colors.authSubtitle

        let button = UIButton(type: .system)
        let attributed = NSAttributedString(
            string: actionTitle,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: AppConstants.Colors.mandarinOrange,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        button.setAttributedTitle(attributed, for: .normal)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, button])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapped() {
        onAction?()
    }
}
