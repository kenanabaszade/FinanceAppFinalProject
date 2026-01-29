import UIKit

class AppButton: UIButton {
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    init(style: ButtonStyle, title: String) {
        super.init(frame: .zero)
        setupButton(style: style, title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton(style: ButtonStyle, title: String) {
        setTitle(title, for: .normal)
        layer.cornerRadius = AppConstants.Sizes.cornerRadius
        titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        
        switch style {
        case .primary:
            setTitleColor(.white, for: .normal)
            backgroundColor = .systemBlue
        case .secondary:
            setTitleColor(.systemBlue, for: .normal)
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = UIColor.systemBlue.cgColor
        case .destructive:
            setTitleColor(.white, for: .normal)
            backgroundColor = .systemRed
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.6
        }
    }
}
