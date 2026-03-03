//
//  Card.swift
//  FinanceApp
//

import Foundation
import FirebaseFirestore

enum CardType: String, Codable {
    case physical
    case virtual
}

enum CardBrand: String, Codable {
    case visa
    case mastercard
}

struct CardPayload: Codable {
    let userId: String
    let name: String
    let type: CardType
    let lastFourDigits: String
    var maskedNumber: String?
    var fullNumber: String?
    var expiryDate: String?
    let createdAt: Date
    var currency: String?
    var accountId: String?
    var brand: CardBrand?
}

extension CardPayload {
    static func forAddCard(
        userId: String,
        name: String,
        type: CardType,
        brand: CardBrand,
        fullNumber: String,
        lastFourDigits: String,
        maskedNumber: String,
        expiryDate: String,
        createdAt: Date,
        currency: String,
        accountId: String
    ) -> CardPayload {
        CardPayload(
            userId: userId,
            name: name,
            type: type,
            lastFourDigits: lastFourDigits,
            maskedNumber: maskedNumber,
            fullNumber: fullNumber,
            expiryDate: expiryDate,
            createdAt: createdAt,
            currency: currency,
            accountId: accountId,
            brand: brand
        )
    }
}

struct Card {
    let id: String
    let userId: String
    let name: String
    let type: CardType
    let lastFourDigits: String
    var maskedNumber: String?
    var fullNumber: String?
    var expiryDate: String?
    let createdAt: Date
    var currency: String?
    var accountId: String?
    var brand: CardBrand?

    init(id: String, payload: CardPayload) {
        self.id = id
        self.userId = payload.userId
        self.name = payload.name
        self.type = payload.type
        self.lastFourDigits = payload.lastFourDigits
        self.maskedNumber = payload.maskedNumber
        self.fullNumber = payload.fullNumber
        self.expiryDate = payload.expiryDate
        self.createdAt = payload.createdAt
        self.currency = payload.currency
        self.accountId = payload.accountId
        self.brand = payload.brand
    }

    init(
        id: String,
        userId: String,
        name: String,
        type: CardType,
        lastFourDigits: String,
        maskedNumber: String? = nil,
        fullNumber: String? = nil,
        expiryDate: String? = nil,
        createdAt: Date,
        currency: String? = nil,
        accountId: String? = nil,
        brand: CardBrand? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.lastFourDigits = lastFourDigits
        self.maskedNumber = maskedNumber
        self.fullNumber = fullNumber
        self.expiryDate = expiryDate
        self.createdAt = createdAt
        self.currency = currency
        self.accountId = accountId
        self.brand = brand
    }

    func toPayload() -> CardPayload {
        CardPayload(
            userId: userId,
            name: name,
            type: type,
            lastFourDigits: lastFourDigits,
            maskedNumber: maskedNumber,
            fullNumber: fullNumber,
            expiryDate: expiryDate,
            createdAt: createdAt,
            currency: currency,
            accountId: accountId,
            brand: brand
        )
    }
}
