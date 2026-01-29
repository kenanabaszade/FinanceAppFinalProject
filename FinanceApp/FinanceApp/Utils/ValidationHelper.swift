import Foundation

enum ValidationError: String {
    case emptyEmail = "Please enter your email"
    case emptyPassword = "Please enter your password"
    case emptyConfirmPassword = "Please confirm your password"
    case emptyFields = "Please fill in all fields"
    case invalidEmail = "Invalid email address"
    case weakPassword = "Password must be at least 6 characters"
    case passwordMismatch = "Passwords do not match"
    
    var message: String {
        return self.rawValue
    }
}

struct ValidationHelper {
    static func validateEmail(_ email: String) -> ValidationError? {
        guard !email.isEmpty else {
            return .emptyEmail
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailPredicate.evaluate(with: email) ? nil : .invalidEmail
    }
    
    static func validatePassword(_ password: String) -> ValidationError? {
        guard !password.isEmpty else {
            return .emptyPassword
        }
        
        guard password.count >= 6 else {
            return .weakPassword
        }
        
        return nil
    }
    
    static func validateConfirmPassword(_ password: String, _ confirmPassword: String) -> ValidationError? {
        guard !confirmPassword.isEmpty else {
            return .emptyConfirmPassword
        }
        
        guard password == confirmPassword else {
            return .passwordMismatch
        }
        
        return nil
    }
    
    static func validateLoginFields(email: String, password: String) -> ValidationError? {
        guard !email.isEmpty, !password.isEmpty else {
            return .emptyFields
        }
        
        if let error = validateEmail(email) {
            return error
        }
        
        return nil
    }
    
    static func validateSignupFields(email: String, password: String, confirmPassword: String) -> ValidationError? {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            return .emptyFields
        }
        
        if let error = validateEmail(email) {
            return error
        }
        
        if let error = validatePassword(password) {
            return error
        }
        
        if let error = validateConfirmPassword(password, confirmPassword) {
            return error
        }
        
        return nil
    }
}
