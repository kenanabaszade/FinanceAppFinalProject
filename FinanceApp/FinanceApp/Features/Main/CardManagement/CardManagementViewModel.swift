//
//  CardManagementViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 1.03.26.
//

import Foundation
import Combine
internal import FirebaseFirestoreInternal

@MainActor
final class CardManagementViewModel: ObservableObject {
    
    @Published private(set) var cards: [Card] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func loadCards() async {
        guard let userId = authService.currentUserId() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            cards = try await firestoreService.getCards(userId: userId, source: .server)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func setBlocked(card: Card, isBlocked: Bool) async {
        guard let userId = authService.currentUserId() else { return }
        do {
            try await firestoreService.updateCardBlocked(cardId: card.id, userId: userId, isBlocked: isBlocked)
            if let idx = cards.firstIndex(where: { $0.id == card.id }) {
                cards[idx] = card.with(isBlocked: isBlocked)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteCard(_ card: Card) async throws {
        guard let userId = authService.currentUserId() else { return }
        try await firestoreService.deleteCard(cardId: card.id, userId: userId)
        cards.removeAll { $0.id == card.id }
    }
}
