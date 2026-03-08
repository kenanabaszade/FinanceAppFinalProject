//
//  AcceptTransferViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 23.02.26.
//

import Foundation
import Combine
internal import FirebaseFirestoreInternal

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
    
    var isSenderFlow: Bool {
        guard let r = request, let uid = authService.currentUserId() else { return false }
        return r.fromAccountId.hasPrefix("request_") && r.senderId == uid
    }
    
    var counterpartyLabel: String {
        guard let r = request else { return "" }
        return isSenderFlow ? r.recipientDisplayName : r.senderDisplayName
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
            var req = try await firestoreService.getPendingTransferRequest(requestId: requestId)
            if req == nil {
                try await Task.sleep(nanoseconds: 800_000_000)
                req = try await firestoreService.getPendingTransferRequest(requestId: requestId)
            }
            guard let req = req else {
                errorMessage = "Request not found or expired"
                return
            }
            let isMoneyRequest = req.fromAccountId.hasPrefix("request_")
            let isRecipient = req.recipientId == recipientId
            let isSender = req.senderId == recipientId
            guard isRecipient || (isMoneyRequest && isSender) else {
                errorMessage = "This request is not for you"
                return
            }
            guard req.status == .pending else {
                errorMessage = "This request has already been \(req.status == .accepted ? "accepted" : "rejected")"
                return
            }
            request = req
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        
        guard let req = request else { return }
        let currency = req.currency
        let canonicalAccountId = "\(recipientId)_\(currency)"
        
        var accounts: [Account] = []
        var cards: [Card] = []
        do {
            async let accountsTask = firestoreService.getAccounts(userId: recipientId)
            async let cardsTask = firestoreService.getCards(userId: recipientId, source: .server)
            accounts = try await accountsTask
            cards = try await cardsTask
        } catch {
            errorMessage = nil
            
        }
        
        let accountMap = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
        var list: [CardWithBalance] = []
        
        
        for card in cards where card.id != "placeholder" && card.id != "placeholder2" {
            let cardCurrency = card.currency ?? "AZN"
            guard cardCurrency == currency else { continue }
            let accountId = card.accountId ?? canonicalAccountId
            if list.contains(where: { $0.account?.id == accountId }) { continue }
            let existingAcc = accountMap[accountId] ?? accountMap[canonicalAccountId] ?? accounts.first { $0.currency == currency }
            let balance = existingAcc?.amount ?? 0
            let accountForDisplay = Account(
                id: accountId,
                userId: recipientId,
                currency: currency,
                amount: balance,
                updatedAt: existingAcc?.updatedAt ?? Date()
            )
            list.append(CardWithBalance(card: card, account: accountForDisplay))
        }
        
        let hasCanonical = list.contains(where: { $0.account?.id == canonicalAccountId })
        if !hasCanonical {
            let existingAccount = accountMap[canonicalAccountId] ?? accounts.first { $0.currency == currency }
            let balance = existingAccount?.amount ?? 0
            let accountForDisplay: Account
            if let acc = existingAccount {
                accountForDisplay = Account(id: acc.id, userId: acc.userId, currency: acc.currency, amount: balance, updatedAt: acc.updatedAt)
            } else {
                accountForDisplay = Account(id: canonicalAccountId, userId: recipientId, currency: currency, amount: 0, updatedAt: Date())
            }
            let placeholderCard = Card(
                id: "receive_\(currency)",
                userId: recipientId,
                name: "\(currency) account",
                type: .virtual,
                lastFourDigits: "••••",
                maskedNumber: nil,
                fullNumber: nil,
                expiryDate: nil,
                createdAt: Date(),
                currency: currency,
                accountId: canonicalAccountId,
                brand: nil
            )
            list.append(CardWithBalance(card: placeholderCard, account: accountForDisplay))
        }
        
        cardsWithBalance = list
        selectedCardWithBalance = list.first
    }
    
    func accept() async {
        guard let recipientId = authService.currentUserId(),
              let cardWithBalance = selectedCardWithBalance else {
            errorMessage = "Select a card to receive into"
            return
        }
        
        
        guard let accountId = cardWithBalance.account?.id, !accountId.isEmpty else {
            errorMessage = "Invalid account selected"
            return
        }
        
        errorMessage = nil
        do {
            if let req = request, req.fromAccountId.hasPrefix("request_") {
                
                if isSenderFlow {
                    
                    let recipientAccountId = "\(req.recipientId)_\(req.currency)"
                    try await firestoreService.acceptMoneyRequest(
                        requestId: requestId,
                        senderId: req.senderId,
                        senderAccountId: accountId,
                        recipientAccountId: recipientAccountId
                    )
                } else {
                    
                    try await firestoreService.acceptMoneyRequest(
                        requestId: requestId,
                        senderId: req.senderId,
                        senderAccountId: nil,
                        recipientAccountId: accountId
                    )
                }
            } else {
                
                try await firestoreService.acceptPendingTransferRequest(
                    requestId: requestId,
                    recipientId: recipientId,
                    recipientAccountId: accountId
                )
            }
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
