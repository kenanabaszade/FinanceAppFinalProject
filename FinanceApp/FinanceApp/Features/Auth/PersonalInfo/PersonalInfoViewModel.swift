import Foundation
import Combine

@MainActor
final class PersonalInfoViewModel: ObservableObject {

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var submitSuccess = false

    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }

    func validate(firstName: String, lastName: String) -> String? {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if first.isEmpty || last.isEmpty {
            return "Please enter both first and last name."
        }
        if !isLettersOnly(first) || !isLettersOnly(last) {
            return "Names can only contain letters."
        }
        return nil
    }

    func submit(firstName: String, lastName: String) async {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let error = validate(firstName: first, lastName: last) {
            errorMessage = error
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            guard let uid = authService.currentUserId(),
                  var user = try await firestoreService.getUser(uid: uid) else {
                isLoading = false
                errorMessage = "Could not load your account."
                return
            }
            user.firstName = first
            user.lastName = last
            user.onboardingStep = 3
            try await firestoreService.updateUser(user)
            UserCache.shared.setCachedUser(user)
            isLoading = false
            submitSuccess = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func isLettersOnly(_ string: String) -> Bool {
        let allowed = CharacterSet.letters.union(.whitespaces)
        return string.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
