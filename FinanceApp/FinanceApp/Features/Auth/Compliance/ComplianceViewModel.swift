import Foundation
import Combine

@MainActor
final class ComplianceViewModel: ObservableObject {

    static let countries = CountriesData.countries

    @Published var selectedCountry: Country?
    @Published var selectedDateOfBirth: Date?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var submitSuccess = false

    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }

    func setCountry(_ country: Country) {
        selectedCountry = country
    }

    func setDateOfBirth(_ date: Date) {
        selectedDateOfBirth = date
    }

    func validate() -> String? {
        guard selectedCountry != nil else {
            return "Please select your country."
        }
        guard let birthdate = selectedDateOfBirth else {
            return "Please select your date of birth."
        }
        guard isAtLeast18(birthdate: birthdate) else {
            return "You must be at least 18 years old."
        }
        return nil
    }

    func submit() async {
        if let error = validate() {
            errorMessage = error
            return
        }

        guard let country = selectedCountry,
              let birthdate = selectedDateOfBirth else { return }

        isLoading = true
        errorMessage = nil
        do {
            guard let uid = authService.currentUserId(),
                  var user = try await firestoreService.getUser(uid: uid) else {
                isLoading = false
                errorMessage = "Could not load your account."
                return
            }
            user.country = country.name
            user.countryCode = country.code
            user.dateOfBirth = birthdate
            user.onboardingStep = 4
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

    private func isAtLeast18(birthdate: Date) -> Bool {
        let years = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        return years >= 18
    }
}
