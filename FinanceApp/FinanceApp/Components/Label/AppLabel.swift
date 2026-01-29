import UIKit

class AppLabel: UILabel {
    
    enum LabelStyle {
        case title(size: CGFloat = 32)
        case subtitle(size: CGFloat = 16)
        case body(size: CGFloat = 14)
        case error
    }
    
    init(style: LabelStyle, text: String = "") {
        super.init(frame: .zero)
        setupLabel(style: style, text: text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel(style: LabelStyle, text: String) {
        self.text = text
        textAlignment = .center
        
        switch style {
        case .title(let size):
            font = .systemFont(ofSize: size, weight: .bold)
            textColor = .label
        case .subtitle(let size):
            font = .systemFont(ofSize: size, weight: .regular)
            textColor = .secondaryLabel
        case .body(let size):
            font = .systemFont(ofSize: size, weight: .regular)
            textColor = .label
            textAlignment = .left
        case .error:
            font = .systemFont(ofSize: 14, weight: .regular)
            textColor = .systemRed
            numberOfLines = 0
            isHidden = true
        }
    }
    
    func showError(_ message: String) {
        text = message
        isHidden = false
    }
    
    func hideError() {
        text = ""
        isHidden = true
    }
}
