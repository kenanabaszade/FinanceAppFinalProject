import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
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
            // Success is shown via callback; clear any previous error
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
