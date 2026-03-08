//
//  EnterAmountViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 28.02.26.
//


import Foundation
import Combine
internal import FirebaseFirestoreInternal

struct CardWithBalance: Identifiable {
    let card: Card
    let account: Account?
    var balance: Double { account?.amount ?? 0 }
    var id: String { card.id }
    var currency: String { card.currency ?? "AZN" }
}

@MainActor
final class EnterAmountViewModel: ObservableObject {
    @Published private(set) var cardsWithBalance: [CardWithBalance] = []
    @Published private(set) var isLoading = true
    @Published private(set) var transferSuccess = false
    @Published private(set) var errorMessage: String?
    @Published var amountText = ""
    @Published var selectedCardWithBalance: CardWithBalance?
    
    let recipient: SendMoneyRecipient
    
    var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    var canSend: Bool {
        amount > 0 && selectedCardWithBalance != nil && (selectedCardWithBalance?.balance ?? 0) >= amount
    }
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(recipient: SendMoneyRecipient, authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.recipient = recipient
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func loadCardsAndAccounts() async {
        guard let userId = authService.currentUserId() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let (accounts, cards) = try await (
                firestoreService.getAccounts(userId: userId),
                firestoreService.getCards(userId: userId, source: .server)
            )
            let accountMap = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
            var list: [CardWithBalance] = []
            
            var cardsByAccount: [String: [Card]] = [:]
            for card in cards where card.id != "placeholder" && card.id != "placeholder2" && !card.isBlocked {
                let currency = card.currency ?? "AZN"
                
                
                let accountId = card.accountId ?? "\(userId)_\(currency)"
                cardsByAccount[accountId, default: []].append(card)
            }
            
            
            for (accountId, accountCards) in cardsByAccount {
                let currency = accountCards.first?.currency ?? "AZN"
                let acc = accountMap[accountId] ?? accountMap["\(userId)_\(currency)"]
                let balance = acc?.amount ?? 0
                let accountForDisplay = Account(
                    id: accountId,
                    userId: userId,
                    currency: currency,
                    amount: balance,
                    updatedAt: acc?.updatedAt ?? Date()
                )
                if let firstCard = accountCards.first {
                    list.append(CardWithBalance(card: firstCard, account: accountForDisplay))
                }
            }
            cardsWithBalance = list
            selectedCardWithBalance = list.first
        } catch {
            cardsWithBalance = []
            errorMessage = "Could not load cards"
        }
    }
    
    func sendTransfer() async {
        guard let userId = authService.currentUserId() else { return }
        guard let recipientId = recipient.userId else {
            errorMessage = "This person is not on Mandarin yet. They need to sign up to receive money."
            return
        }
        guard let cardWithBalance = selectedCardWithBalance else {
            errorMessage = "Please select a card"
            return
        }
        guard !cardWithBalance.card.isBlocked else {
            errorMessage = "This card is blocked. Unblock it in Card Management to send money."
            return
        }
        guard let fromAccountId = cardWithBalance.account?.id ?? cardWithBalance.card.accountId, !fromAccountId.isEmpty else {
            errorMessage = "This card has no linked account"
            return
        }
        guard amount > 0 else {
            errorMessage = "Enter an amount"
            return
        }
        guard cardWithBalance.balance >= amount else {
            errorMessage = "Insufficient balance"
            return
        }
        let senderName = await getCurrentUserName() ?? "User"
        errorMessage = nil
        do {
            _ = try await firestoreService.createPendingTransferRequest(
                senderId: userId,
                senderDisplayName: senderName,
                recipientId: recipientId,
                recipientDisplayName: recipient.displayName,
                amount: amount,
                currency: cardWithBalance.currency,
                fromAccountId: fromAccountId
            )
            transferSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func getCurrentUserName() async -> String? {
        guard let uid = authService.currentUserId(), let user = try? await firestoreService.getUser(uid: uid) else { return nil }
        return [user.firstName, user.lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
