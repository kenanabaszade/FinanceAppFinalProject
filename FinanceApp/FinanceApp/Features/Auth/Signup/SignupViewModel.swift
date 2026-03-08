import Foundation
import Combine

@MainActor
final class SignupViewModel: ObservableObject {
    
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func validate(email: String, password: String, confirmPassword: String) -> SignupValidationState {
        let emailValid = isValidEmail(email)
        let passwordValid = password.count >= AppConstants.Password.signupMinimumLength
        let match = password == confirmPassword
        if emailValid && passwordValid && match { return .valid }
        if !emailValid && !passwordValid { return .invalidMultiple }
        if !emailValid { return .invalidEmail }
        if !passwordValid { return .invalidPassword }
        if !match { return .passwordMismatch }
        return .invalidMultiple
    }
    
    func createAccount(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let uid = try await authService.createUser(email: email, password: password)
            try await authService.sendEmailVerification()
            var user = User(uid: uid)
            user.email = email
            user.onboardingStep = 1
            user.isEmailVerified = false
            try await firestoreService.saveUser(user)
            UserCache.shared.setCachedUser(user)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    private func isValidEmail(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count > 5
    }
}

enum SignupValidationState {
    case valid
    case invalidEmail
    case invalidPassword
    case passwordMismatch
    case invalidMultiple
}
