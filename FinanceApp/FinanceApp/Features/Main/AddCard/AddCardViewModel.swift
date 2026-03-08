//
//  AddCardViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 23.02.26.
//

import Foundation
import Combine

enum AddCardStep {
    case chooseType
    case preview
}

struct AddCardPreview {
    let brand: CardBrand
    let maskedNumber: String
    let expiryDate: String
    let type: CardType
}

private let addCardCurrency = "AZN"

@MainActor
final class AddCardViewModel: ObservableObject {
    @Published private(set) var step: AddCardStep = .chooseType
    @Published private(set) var previewCard: AddCardPreview?
    @Published private(set) var isLoading = false
    @Published private(set) var didFinish = false
    @Published var errorMessage: String?
    
    @Published var selectedType: CardType = .virtual
    
    private var generatedFullNumber: String = ""
    private var generatedExpiry: String = ""
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func start() {
        step = .chooseType
        previewCard = nil
        selectedType = .virtual
    }
    
    func selectType(_ type: CardType) {
        selectedType = type
    }
    
    func continueFromType() {
        let brand: CardBrand = Bool.random() ? .visa : .mastercard
        generatedFullNumber = CardNumberGenerator.generateNumber(brand: brand)
        generatedExpiry = CardNumberGenerator.generateExpiryDate()
        let lastFour = String(generatedFullNumber.suffix(4))
        let masked = "••••  ••••  ••••  \(lastFour)"
        previewCard = AddCardPreview(
            brand: brand,
            maskedNumber: masked,
            expiryDate: generatedExpiry,
            type: selectedType
        )
        step = .preview
    }
    
    func goBack() {
        step = .chooseType
        previewCard = nil
    }
    
    func saveCard() async {
        guard let userId = authService.currentUserId() else {
            errorMessage = "Not signed in"
            return
        }
        guard let preview = previewCard else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await firestoreService.addCard(
                userId: userId,
                name: "Mandarin",
                type: selectedType,
                brand: preview.brand,
                fullNumber: generatedFullNumber,
                expiryDate: generatedExpiry,
                currency: addCardCurrency
            )
            didFinish = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
