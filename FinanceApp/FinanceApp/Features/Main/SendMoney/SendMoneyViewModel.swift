import Foundation
import Combine

@MainActor
final class SendMoneyViewModel: ObservableObject {

    @Published private(set) var allRecipients: [SendMoneyRecipient] = []
    @Published private(set) var isLoading = false
    @Published var searchText = ""

    /// App users only (on Mandarin) – shown in the top section with distinct styling. Excludes current user.
    var appUserRecipients: [SendMoneyRecipient] {
        guard let uid = authService.currentUserId() else { return allRecipients.filter { $0.isAppUser } }
        return allRecipients.filter { $0.isAppUser && $0.userId != uid }
    }

    var sectionedRecipients: [(letter: String, recipients: [SendMoneyRecipient])] {
        let list = filteredRecipients
        let grouped = Dictionary(grouping: list) { recipient -> String in
            let name = recipient.displayName
            guard let first = name.first else { return "#" }
            let letter = String(first).uppercased()
            return letter >= "A" && letter <= "Z" ? letter : "#"
        }
        return grouped
            .map { (letter: $0.key, recipients: $0.value.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }) }
            .sorted { $0.letter.compare($1.letter, options: .numeric) == .orderedAscending }
    }

    var filteredRecipients: [SendMoneyRecipient] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return allRecipients }
        return allRecipients.filter {
            $0.displayName.lowercased().contains(query)
                || ($0.phone?.lowercased().contains(query) ?? false)
        }
    }

    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    private let contactsService: ContactsServiceProtocol

    init(
        authService: AuthServiceProtocol,
        firestoreService: FirestoreServiceProtocol,
        contactsService: ContactsServiceProtocol
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.contactsService = contactsService
    }

    func loadRecipients() async {
        guard let currentUserId = authService.currentUserId() else {
            await loadContactsOnly()
            return
        }
        isLoading = true
        defer { isLoading = false }

        async let appUsersTask: [User] = {
            do {
                return try await firestoreService.getAllRecipients(excludingUserId: currentUserId)
            } catch {
                return []
            }
        }()
        let deviceContacts = await contactsService.fetchContactsWithPhones()

        let appUsers = await appUsersTask
        let appRecipients = appUsers.map { SendMoneyRecipient.from(user: $0) }
        let appUserPhones = Set(appRecipients.compactMap { $0.phone }.map { Self.normalizePhone($0) })
        let contactsNotInApp = deviceContacts.filter { contact in
            guard let p = contact.phone else { return true }
            return !appUserPhones.contains(Self.normalizePhone(p))
        }
        let combined = appRecipients + contactsNotInApp
        allRecipients = combined.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private func loadContactsOnly() async {
        isLoading = true
        defer { isLoading = false }
        let deviceContacts = await contactsService.fetchContactsWithPhones()
        allRecipients = deviceContacts.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private static func normalizePhone(_ phone: String) -> String {
        phone.filter { $0.isNumber }
    }
}
