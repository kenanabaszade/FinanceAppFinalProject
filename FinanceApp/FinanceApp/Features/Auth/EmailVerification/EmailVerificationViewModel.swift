import Foundation
import Combine

@MainActor
final class EmailVerificationViewModel: ObservableObject {
    
    let email: String
    var bodyText: String { "We sent a verification email to \(email)." }
    
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var verifiedSuccess = false
    @Published var isResendSuccess = false
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(email: String, authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.email = email
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func verify() async {
        isLoading = true
        errorMessage = nil
        isResendSuccess = false
        do {
            try await authService.reloadCurrentUser()
            guard authService.isCurrentUserEmailVerified() else {
                isLoading = false
                errorMessage = "Email not verified yet."
                return
            }
            guard let uid = authService.currentUserId(),
                  var user = try await firestoreService.getUser(uid: uid) else {
                isLoading = false
                errorMessage = "Could not load your account."
                return
            }
            user.isEmailVerified = true
            user.onboardingStep = 2
            try await firestoreService.updateUser(user)
            UserCache.shared.setCachedUser(user)
            isLoading = false
            verifiedSuccess = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    func resend() async {
        isLoading = true
        errorMessage = nil
        isResendSuccess = false
        do {
            try await authService.sendEmailVerification()
            isLoading = false
            errorMessage = "Verification email sent."
            isResendSuccess = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
        isResendSuccess = false
    }
}
