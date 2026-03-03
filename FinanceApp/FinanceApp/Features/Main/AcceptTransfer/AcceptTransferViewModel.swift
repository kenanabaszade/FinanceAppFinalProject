//
//  AcceptTransferViewModel.swift
//  FinanceApp
//

import Foundation
import Combine

@MainActor
final class AcceptTransferViewModel: ObservableObject {
    @Published private(set) var request: PendingTransferRequest?
    @Published private(set) var cardsWithBalance: [CardWithBalance] = []
    @Published private(set) var isLoading = true
    @Published private(set) var acceptSuccess = false
    @Published private(set) var rejectSuccess = false
    @Published private(set) var errorMessage: String?
    @Published var selectedCardWithBalance: CardWithBalance?

    let requestId: String

    var amountText: String {
        guard let r = request else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: r.amount)) ?? String(format: "%.2f", r.amount)
    }

    var canAccept: Bool {
        guard let r = request, r.status == .pending else { return false }
        return selectedCardWithBalance != nil
    }

    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    init(requestId: String, authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.requestId = requestId
        self.authService = authService
        self.firestoreService = firestoreService
    }

    func load() async {
        guard let recipientId = authService.currentUserId() else {
            errorMessage = "Not signed in"
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            guard let req = try await firestoreService.getPendingTransferRequest(requestId: requestId) else {
                errorMessage = "Request not found or expired"
                return
            }
            guard req.recipientId == recipientId else {
                errorMessage = "This request is not for you"
                return
            }
            guard req.status == .pending else {
                errorMessage = "This request has already been \(req.status == .accepted ? "accepted" : "rejected")"
                return
            }
            request = req
            let (accounts, cards) = try await (
                firestoreService.getAccounts(userId: recipientId),
                firestoreService.getCards(userId: recipientId, source: nil)
            )
            let accountMap = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
            var list: [CardWithBalance] = []
            let currency = req.currency
            for card in cards where card.id != "placeholder" && card.id != "placeholder2" {
                let cardCurrency = card.currency ?? "AZN"
                guard cardCurrency == currency else { continue }
                let canonicalId = "\(recipientId)_\(currency)"
                let accountsForCurrency = accounts.filter { $0.currency == currency }
                let totalBalance = accountsForCurrency.reduce(0) { $0 + $1.amount }
                let accForTransfer: Account? = accountsForCurrency.max(by: { $0.amount < $1.amount })
                    ?? accountMap[canonicalId]
                    ?? card.accountId.flatMap { accountMap[$0] }
                    ?? accounts.first { $0.currency == currency }
                let accountForDisplay: Account
                if let acc = accForTransfer {
                    accountForDisplay = Account(id: acc.id, userId: acc.userId, currency: acc.currency, amount: totalBalance, updatedAt: acc.updatedAt)
                } else {
                    accountForDisplay = Account(id: canonicalId, userId: recipientId, currency: currency, amount: totalBalance, updatedAt: Date())
                }
                list.append(CardWithBalance(card: card, account: accountForDisplay))
            }
            cardsWithBalance = list
            selectedCardWithBalance = list.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept() async {
        guard let recipientId = authService.currentUserId(),
              let cardWithBalance = selectedCardWithBalance,
              let accountId = cardWithBalance.account?.id ?? cardWithBalance.card.accountId else {
            errorMessage = "Select a card to receive into"
            return
        }
        errorMessage = nil
        do {
            try await firestoreService.acceptPendingTransferRequest(
                requestId: requestId,
                recipientId: recipientId,
                recipientAccountId: accountId
            )
            acceptSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reject() async {
        guard let recipientId = authService.currentUserId() else { return }
        errorMessage = nil
        do {
            try await firestoreService.rejectPendingTransferRequest(requestId: requestId, recipientId: recipientId)
            rejectSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
