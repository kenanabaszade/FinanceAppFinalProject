//
//  PaymentsViewModel.swift
//  FinanceApp
//

import Foundation
import Combine

@MainActor
final class PaymentsViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published private(set) var accounts: [Account] = []

    var categories: [PaymentCategory] { PaymentCategory.all.filter { $0.id != "other" } }
    var shortcuts: [PaymentShortcut] { PaymentShortcut.defaults }

    var filteredCategories: [PaymentCategory] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return categories
        }
        let q = searchText.lowercased()
        return categories.filter { $0.name.lowercased().contains(q) }
    }

    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }

    func loadAccounts() async {
        guard let userId = authService.currentUserId() else { return }
        do {
            accounts = try await firestoreService.getAccounts(userId: userId)
        } catch {
            accounts = []
        }
    }
}

extension PaymentShortcut {
    static let defaults: [PaymentShortcut] = [
        PaymentShortcut(id: "my_number", name: "My number", subtitle: nil, systemImageName: "iphone", categoryId: "mobile"),
        PaymentShortcut(id: "utilities", name: "Utilities", subtitle: "Bills", systemImageName: "house.fill", categoryId: "utilities"),
        PaymentShortcut(id: "transport", name: "Transport", subtitle: "BakuCard", systemImageName: "bus.fill", categoryId: "transport")
    ]
}
