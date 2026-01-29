import Foundation
import FirebaseAuth

enum FirebaseAuthError: String {
    case invalidEmail = "Invalid email address. Please check and try again."
    case userDisabled = "This account has been disabled. Please contact support."
    case wrongPassword = "Incorrect password. Please try again."
    case userNotFound = "No account found with this email. Please sign up first."
    case networkError = "Network error. Please check your connection and try again."
    case tooManyRequests = "Too many failed attempts. Please try again later."
    case invalidCredential = "Invalid credentials. Please check your email and password."
    case emailAlreadyInUse = "This email is already registered. Please sign in instead."
    case weakPassword = "Password is too weak. Please choose a stronger password."
    case unexpectedError = "An unexpected error occurred. Please try again."
    case loginFailed = "Login failed. Please try again."
    case signupFailed = "Signup failed. Please try again."
    case verificationEmailFailed = "Failed to send verification email"
    
    var message: String {
        return self.rawValue
    }
}

struct FirebaseErrorHandler {
    static func handleAuthError(_ error: Error) -> String {
        guard let authError = error as NSError? else {
            return FirebaseAuthError.unexpectedError.message
        }
        
        switch authError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return FirebaseAuthError.invalidEmail.message
        case AuthErrorCode.userDisabled.rawValue:
            return FirebaseAuthError.userDisabled.message
        case AuthErrorCode.wrongPassword.rawValue:
            return FirebaseAuthError.wrongPassword.message
        case AuthErrorCode.userNotFound.rawValue:
            return FirebaseAuthError.userNotFound.message
        case AuthErrorCode.networkError.rawValue:
            return FirebaseAuthError.networkError.message
        case AuthErrorCode.tooManyRequests.rawValue:
            return FirebaseAuthError.tooManyRequests.message
        case AuthErrorCode.invalidCredential.rawValue:
            return FirebaseAuthError.invalidCredential.message
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return FirebaseAuthError.emailAlreadyInUse.message
        case AuthErrorCode.weakPassword.rawValue:
            return FirebaseAuthError.weakPassword.message
        default:
            return authError.localizedDescription
        }
    }
    
    static func handleVerificationError(_ error: Error) -> String {
        return "\(FirebaseAuthError.verificationEmailFailed.message): \(error.localizedDescription)"
    }
}
