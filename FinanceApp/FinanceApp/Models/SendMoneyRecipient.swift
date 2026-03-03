import Foundation
 
struct SendMoneyRecipient {
    let id: String
    let displayName: String
    let phone: String?
    let profileImageURL: String?
    let contactImageData: Data?
    let isAppUser: Bool
    let userId: String?

    static func from(user: User) -> SendMoneyRecipient {
        let name = user.fullName.isEmpty ? "—" : user.fullName
        return SendMoneyRecipient(
            id: user.uid,
            displayName: name,
            phone: user.phone,
            profileImageURL: user.profileImageURL,
            contactImageData: nil,
            isAppUser: true,
            userId: user.uid
        )
    }

    var displayPhone: String { phone ?? "—" }

    var initials: String {
        let first = displayName.prefix(1)
        return first.isEmpty ? "?" : String(first).uppercased()
    }
}
