//
//  RequestMoneyRecipientsViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 2.27.26.
//

import Foundation
import Combine

struct RequestMoneyRecipientSection {
    let title: String
    let recipients: [SendMoneyRecipient]
}

@MainActor
final class RequestMoneyRecipientsViewModel: ObservableObject {
    
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var searchText: String = "" {
        didSet { applyFilter() }
    }
    @Published private(set) var frequentRecipients: [SendMoneyRecipient] = []
    @Published private(set) var sections: [RequestMoneyRecipientSection] = []
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    private let contactsService: ContactsServiceProtocol
    
    private var allRecipients: [SendMoneyRecipient] = []
    private var appRecipients: [SendMoneyRecipient] = []
    
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
        guard let currentUserId = authService.currentUserId() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let users = try await firestoreService.getAllRecipients(excludingUserId: currentUserId)
            let appRecipients = users.map(SendMoneyRecipient.from(user:))
            self.appRecipients = appRecipients
            
            let contacts = await contactsService.fetchContactsWithPhones()
            
            var merged: [SendMoneyRecipient] = []
            merged.reserveCapacity(appRecipients.count + contacts.count)
            merged.append(contentsOf: appRecipients)
            
            let existingIds = Set(appRecipients.map { $0.id })
            for contact in contacts where !existingIds.contains(contact.id) {
                merged.append(contact)
            }
            
            allRecipients = merged
            rebuildLists(using: allRecipients)
        } catch {
            errorMessage = error.localizedDescription
            allRecipients = []
            appRecipients = []
            frequentRecipients = []
            sections = []
        }
    }
    
    private func applyFilter() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            rebuildLists(using: allRecipients)
            return
        }
        let lower = trimmed.lowercased()
        let filtered = allRecipients.filter { recipient in
            let nameMatch = recipient.displayName.lowercased().contains(lower)
            let phoneMatch = recipient.displayPhone.lowercased().contains(lower)
            let idMatch = recipient.id.lowercased().contains(lower)
            return nameMatch || phoneMatch || idMatch
        }
        rebuildLists(using: filtered)
    }
    
    private func rebuildLists(using recipients: [SendMoneyRecipient]) {
        buildFrequentRecipients()
        buildSections(from: recipients)
    }
    
    private func buildFrequentRecipients() {
        let sorted = appRecipients
            .filter { $0.userId != authService.currentUserId() }
            .sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
        frequentRecipients = Array(sorted.prefix(6))
    }
    
    private func buildSections(from recipients: [SendMoneyRecipient]) {
        var grouped: [String: [SendMoneyRecipient]] = [:]
        for recipient in recipients {
            if recipient.userId == authService.currentUserId() {
                continue
            }
            let firstChar = recipient.displayName.trimmingCharacters(in: .whitespacesAndNewlines).first
            let key = firstChar.map { String($0).uppercased() } ?? "#"
            grouped[key, default: []].append(recipient)
        }
        
        let sortedKeys = grouped.keys.sorted()
        sections = sortedKeys.compactMap { key in
            guard let list = grouped[key]?.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }),
                  !list.isEmpty else { return nil }
            return RequestMoneyRecipientSection(title: key, recipients: list)
        }
    }
}

