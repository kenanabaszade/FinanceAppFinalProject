import Foundation
import Contacts

protocol ContactsServiceProtocol {
    func requestAccess() async -> Bool
    func fetchContactsWithPhones() async -> [SendMoneyRecipient]
}

final class ContactsService: ContactsServiceProtocol {

    private let store = CNContactStore()

    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func fetchContactsWithPhones() async -> [SendMoneyRecipient] {
        guard await requestAccess() else { return [] }
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        fetchRequest.sortOrder = .userDefault
        let store = self.store
        let recipients: [SendMoneyRecipient] = await Task.detached(priority: .userInitiated) {
            var list: [SendMoneyRecipient] = []
            do {
                try store.enumerateContacts(with: fetchRequest) { contact, _ in
                let phones = contact.phoneNumbers.map { $0.value.stringValue }
                guard let firstPhone = phones.first else { return }
                let fullName = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                let displayName = fullName.isEmpty ? "Unknown" : fullName
                let id = "contact-\(contact.identifier)"
                let recipient = SendMoneyRecipient(
                    id: id,
                    displayName: displayName,
                    phone: firstPhone,
                    profileImageURL: nil,
                    contactImageData: contact.thumbnailImageData,
                    isAppUser: false,
                    userId: nil
                )
                    list.append(recipient)
                }
            } catch {
                return []
            }
            return list
        }.value
        return recipients
    }
}
