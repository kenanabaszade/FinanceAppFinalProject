import Foundation
import FirebaseFirestore

struct UserPayload: Codable {
    let uid: String
    var email: String?
    var firstName: String?
    var lastName: String?
    var phone: String?
    var profileImageURL: String?
    /// Base64-encoded small JPEG; used when Firebase Storage is not available (no upgrade).
    var profileImageBase64: String?
    var country: String?
    var countryCode: String?
    var dateOfBirth: Date?
    var isEmailVerified: Bool?
    var onboardingStep: Int?
    var purposes: [String]?
    var selectedPlan: String?
    var cardType: String?
    var hasCard: Bool?
    var pinSet: Bool?
    let createdAt: Date
    var updatedAt: Date
}


struct UserPayloadLenient: Codable {
    var uid: String?
    var email: String?
    var firstName: String?
    var lastName: String?
    var phone: String?
    var profileImageURL: String?
    var profileImageBase64: String?
    var country: String?
    var countryCode: String?
    var dateOfBirth: Date?
    var isEmailVerified: Bool?
    var onboardingStep: Int?
    var purposes: [String]?
    var selectedPlan: String?
    var cardType: String?
    var hasCard: Bool?
    var pinSet: Bool?
    var createdAt: Date?
    var updatedAt: Date?

    func toUserPayload(fallbackUid: String) -> UserPayload {
        let fallback = Date()
        return UserPayload(
            uid: uid ?? fallbackUid,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            profileImageURL: profileImageURL,
            profileImageBase64: profileImageBase64,
            country: country,
            countryCode: countryCode,
            dateOfBirth: dateOfBirth,
            isEmailVerified: isEmailVerified,
            onboardingStep: onboardingStep,
            purposes: purposes,
            selectedPlan: selectedPlan,
            cardType: cardType,
            hasCard: hasCard,
            pinSet: pinSet,
            createdAt: createdAt ?? fallback,
            updatedAt: updatedAt ?? fallback
        )
    }
}

struct User {
    let uid: String
    var email: String?
    var firstName: String?
    var lastName: String?
    var phone: String?
    var profileImageURL: String?
    /// Base64-encoded small JPEG when Storage is not used.
    var profileImageBase64: String?
    var country: String?
    var countryCode: String?
    var dateOfBirth: Date?
    var isEmailVerified: Bool?
    var onboardingStep: Int?
    var purposes: [String]?
    var selectedPlan: String?
    var cardType: String?
    var hasCard: Bool?
    var pinSet: Bool?
    var createdAt: Date
    var updatedAt: Date

    init(uid: String, payload: UserPayload) {
        self.uid = uid
        self.email = payload.email
        self.firstName = payload.firstName
        self.lastName = payload.lastName
        self.phone = payload.phone
        self.profileImageURL = payload.profileImageURL
        self.profileImageBase64 = payload.profileImageBase64
        self.country = payload.country
        self.countryCode = payload.countryCode
        self.dateOfBirth = payload.dateOfBirth
        self.isEmailVerified = payload.isEmailVerified
        self.onboardingStep = payload.onboardingStep
        self.purposes = payload.purposes
        self.selectedPlan = payload.selectedPlan
        self.cardType = payload.cardType
        self.hasCard = payload.hasCard
        self.pinSet = payload.pinSet
        self.createdAt = payload.createdAt
        self.updatedAt = payload.updatedAt
    }

    init(uid: String) {
        self.uid = uid
        self.createdAt = Date()
        self.updatedAt = Date()
        self.email = nil
        self.firstName = nil
        self.lastName = nil
        self.phone = nil
        self.profileImageURL = nil
        self.profileImageBase64 = nil
        self.country = nil
        self.countryCode = nil
        self.dateOfBirth = nil
        self.isEmailVerified = nil
        self.onboardingStep = nil
        self.purposes = nil
        self.selectedPlan = nil
        self.cardType = nil
        self.hasCard = nil
        self.pinSet = nil
    }

    func toPayload() -> UserPayload {
        UserPayload(
            uid: uid,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            profileImageURL: profileImageURL,
            profileImageBase64: profileImageBase64,
            country: country,
            countryCode: countryCode,
            dateOfBirth: dateOfBirth,
            isEmailVerified: isEmailVerified,
            onboardingStep: onboardingStep,
            purposes: purposes,
            selectedPlan: selectedPlan,
            cardType: cardType,
            hasCard: hasCard,
            pinSet: pinSet,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    var displayPhone: String {
        phone ?? "—"
    }
}
