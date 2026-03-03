import Foundation

protocol ServiceContainerProtocol: AnyObject {
    var authService: AuthServiceProtocol { get }
    var firestoreService: FirestoreServiceProtocol { get }
    var contactsService: ContactsServiceProtocol { get }
    var storageService: StorageServiceProtocol { get }
}

final class ServiceContainer: ServiceContainerProtocol {

    let authService: AuthServiceProtocol
    let firestoreService: FirestoreServiceProtocol
    let contactsService: ContactsServiceProtocol
    let storageService: StorageServiceProtocol

    init(
        authService: AuthServiceProtocol = AuthService(),
        firestoreService: FirestoreServiceProtocol = FirestoreService(),
        contactsService: ContactsServiceProtocol = ContactsService(),
        storageService: StorageServiceProtocol = StorageService()
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.contactsService = contactsService
        self.storageService = storageService
    }
}
