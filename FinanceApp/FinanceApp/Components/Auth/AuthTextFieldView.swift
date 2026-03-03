import UIKit
import SnapKit

final class AuthTextFieldView: UIView {

    enum Style {
        case email
        case password(showToggle: Bool)
    }

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    var onTextChange: ((String) -> Void)?

    private let style: Style

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppConstants.Colors.authTitle
        return label
    }()

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authInputBackground
        v.layer.borderWidth = 1
        v.layer.borderColor = AppConstants.Colors.authInputBorder.cgColor
        return v
    }()

    let textField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.textColor = AppConstants.Colors.authTitle
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        return tf
    }()

    private lazy var visibilityButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        b.setImage(UIImage(systemName: "eye.slash", withConfiguration: config), for: .normal)
        b.tintColor = AppConstants.Colors.authSubtitle
        b.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        return b
    }()

    init(style: Style, title: String, placeholder: String) {
        self.style = style
        super.init(frame: .zero)
        titleLabel.text = title
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AppConstants.Colors.authPlaceholder]
        )

        switch style {
        case .email:
            textField.keyboardType = .emailAddress
            textField.textContentType = .emailAddress
        case .password(let showToggle):
            textField.isSecureTextEntry = true
            textField.textContentType = .password
            if showToggle {
                containerView.addSubview(visibilityButton)
            }
        }

        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        addSubview(titleLabel)
        addSubview(containerView)
        containerView.addSubview(textField)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = containerView.bounds.height / 2
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            containerView.layer.borderColor = AppConstants.Colors.authInputBorder
                .resolvedColor(with: traitCollection).cgColor
        }
    }

    private func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.small)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(AppConstants.Sizes.textFieldHeight)
        }

        let hasToggle: Bool
        switch style {
        case .email: hasToggle = false
        case .password(let show): hasToggle = show
        }

        if hasToggle {
            visibilityButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-AppConstants.Spacing.medium)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(AppConstants.Auth.iconButtonSize)
            }
            textField.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
                make.trailing.equalTo(visibilityButton.snp.leading).offset(-4)
            }
        } else {
            textField.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
                make.centerY.equalToSuperview()
            }
        }
    }

    @objc private func editingChanged() {
        onTextChange?(textField.text ?? "")
    }

    @objc private func toggleTapped() {
        let isSecure = textField.isSecureTextEntry
        textField.isSecureTextEntry = !isSecure
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        visibilityButton.setImage(
            UIImage(systemName: isSecure ? "eye" : "eye.slash", withConfiguration: config),
            for: .normal
        )
    }
}
