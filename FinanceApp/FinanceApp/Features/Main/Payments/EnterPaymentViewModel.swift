//
//  EnterPaymentViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 3.03.26.
//


import Foundation
import Combine
internal import FirebaseFirestoreInternal

@MainActor
final class EnterPaymentViewModel: ObservableObject {
    
    let category: PaymentCategory
    
    @Published var amountText: String = ""
    @Published var referenceText: String = ""
    @Published var phonePrefix: String = ""
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var cards: [Card] = []
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
            let allAccounts = try await firestoreService.getAccounts(userId: userId)
            let allCards = try await firestoreService.getCards(userId: userId, source: .server)
            cards = allCards
            
            let accountIdsWithActiveCard = Set(allCards.filter { !$0.isBlocked }.compactMap { $0.accountId })
            accounts = allAccounts.filter { accountIdsWithActiveCard.contains($0.id) }
            if selectedAccount == nil || !accounts.contains(where: { $0.id == selectedAccount?.id }) {
                selectedAccount = accounts.first
            }
        } catch {
            accounts = []
        }
    }
    
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
