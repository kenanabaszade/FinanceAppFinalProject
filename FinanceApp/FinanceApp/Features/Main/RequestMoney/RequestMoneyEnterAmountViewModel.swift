//
//  RequestMoneyEnterAmountViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 2.27.26.
//

import Foundation
import Combine
internal import FirebaseFirestoreInternal

@MainActor
final class RequestMoneyEnterAmountViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var requestSuccess = false
    @Published private(set) var errorMessage: String?
    @Published var amountText = ""
    
    let recipient: SendMoneyRecipient
    
    var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    var canRequest: Bool {
        amount > 0
    }
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(recipient: SendMoneyRecipient, authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.recipient = recipient
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func sendRequest() async {
        guard let userId = authService.currentUserId() else { return }
        guard let recipientId = recipient.userId else {
            errorMessage = "This person is not on Mandarin yet. They need to sign up to receive requests."
            return
        }
        guard amount > 0 else {
            errorMessage = "Enter an amount"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let requesterName = await getCurrentUserName() ?? "User"
        errorMessage = nil
        do {
            
            let requestAccountId = "request_\(recipientId)_\(userId)_\(UUID().uuidString)"
            let requestId = try await firestoreService.createPendingTransferRequest(
                senderId: recipientId,
                senderDisplayName: recipient.displayName,
                recipientId: userId,
                recipientDisplayName: requesterName,
                amount: amount,
                currency: "AZN",
                fromAccountId: requestAccountId  
            )
            
            
            let symbol = "₼"
            do {
                try await firestoreService.createNotification(
                    userId: recipientId,
                    title: "\(requesterName) is requesting \(String(format: "%.2f", amount)) \(symbol)",
                    body: "Choose which card to send from",
                    type: "money_request",
                    transactionId: requestId,
                    amount: amount,
                    currency: "AZN"
                )
            } catch {
                print("Failed to create notification: \(error)")
            }
            requestSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func getCurrentUserName() async -> String? {
        guard let uid = authService.currentUserId(), let user = try? await firestoreService.getUser(uid: uid) else { return nil }
        return [user.firstName, user.lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
