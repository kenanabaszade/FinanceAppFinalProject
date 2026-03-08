import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func validate(email: String, password: String) -> LoginValidationState {
        let emailValid = isValidEmail(email)
        let passwordValid = password.count >= AppConstants.Password.minimumLength
        if emailValid && passwordValid { return .valid }
        if !emailValid && !passwordValid { return .invalidBoth }
        return !emailValid ? .invalidEmail : .invalidPassword
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signIn(email: email, password: password)
            
            if let uid = authService.currentUserId(),
               try await firestoreService.getUser(uid: uid) == nil {
                var user = User(uid: uid)
                user.email = email
                try await firestoreService.saveUser(user)
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func sendPasswordReset(email: String) async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        guard isValidEmail(trimmed) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.sendPasswordReset(email: trimmed)
            isLoading = false
            errorMessage = nil
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    private func isValidEmail(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count > 5
    }
}

enum LoginValidationState {
    case valid
    case invalidEmail
    case invalidPassword
    case invalidBoth
}
