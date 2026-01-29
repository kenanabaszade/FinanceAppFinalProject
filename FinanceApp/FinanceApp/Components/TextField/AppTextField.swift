import UIKit

class AppTextField: UITextField {
    
    enum TextFieldType {
        case email
        case password
        case text
        case number
    }
    
    init(type: TextFieldType, placeholder: String, returnKeyType: UIReturnKeyType = .default) {
        super.init(frame: .zero)
        setupTextField(type: type, placeholder: placeholder, returnKeyType: returnKeyType)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextField(type: TextFieldType, placeholder: String, returnKeyType: UIReturnKeyType) {
        self.placeholder = placeholder
        self.returnKeyType = returnKeyType
        self.borderStyle = .roundedRect
        self.backgroundColor = .systemGray6
        self.autocapitalizationType = .none
        self.autocorrectionType = .no
        
        switch type {
        case .email:
            self.keyboardType = .emailAddress
        case .password:
            self.isSecureTextEntry = true
        case .number:
            self.keyboardType = .numberPad
        case .text:
            break
        }
    }
}
