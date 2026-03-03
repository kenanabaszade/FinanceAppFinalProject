//
//  EnterPaymentViewModel.swift
//  FinanceApp
//

import Foundation
import Combine

@MainActor
final class EnterPaymentViewModel: ObservableObject {

    let category: PaymentCategory

    @Published var amountText: String = ""
    /// Reference input: number part for phone, or full value for other categories
    @Published var referenceText: String = ""
    /// For mobile: selected prefix (e.g. "+994 50")
    @Published var phonePrefix: String = ""
    @Published private(set) var accounts: [Account] = []
    @Published var selectedAccount: Account?
    @Published private(set) var isLoading = false
    @Published private(set) var didSucceed = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    init(category: PaymentCategory, authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.category = category
        self.authService = authService
        self.firestoreService = firestoreService
        if case .phoneWithPrefix(let prefixes) = category.inputKind, let first = prefixes.first {
            phonePrefix = first
        }
    }

    func loadAccounts() async {
        guard let userId = authService.currentUserId() else { return }
        do {
            accounts = try await firestoreService.getAccounts(userId: userId)
            if selectedAccount == nil || !accounts.contains(where: { $0.id == selectedAccount?.id }) {
                selectedAccount = accounts.first
            }
        } catch {
            accounts = []
        }
    }

    /// Full reference to store (e.g. "+994 50 123 45 67" or "12345678")
    var paymentReference: String? {
        let trimmed = referenceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if category.id == "other" {
            return trimmed.isEmpty ? nil : trimmed
        }
        if case .phoneWithPrefix = category.inputKind {
            let num = trimmed
            if num.isEmpty { return nil }
            return [phonePrefix, num].joined(separator: " ").trimmingCharacters(in: .whitespaces)
        }
        return trimmed.isEmpty ? nil : trimmed
    }

    var isReferenceRequired: Bool {
        category.id != "other"
    }

    var canPay: Bool {
        guard let account = selectedAccount else { return false }
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)),
              amount > 0 else { return false }
        if account.amount < amount { return false }
        if isReferenceRequired, paymentReference == nil { return false }
        return true
    }

    func pay() async {
        guard let userId = authService.currentUserId(),
              let account = selectedAccount else {
            errorMessage = "Please select an account"
            return
        }
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)),
              amount > 0 else {
            errorMessage = "Enter a valid amount"
            return
        }
        guard account.amount >= amount else {
            errorMessage = "Insufficient balance"
            return
        }
        if isReferenceRequired, paymentReference == nil {
            errorMessage = "Please enter \(category.inputLabel.lowercased())"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await firestoreService.payFromAccount(
                userId: userId,
                accountId: account.id,
                amount: amount,
                currency: account.currency,
                merchantName: category.name,
                category: category.id,
                reference: paymentReference
            )
            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
