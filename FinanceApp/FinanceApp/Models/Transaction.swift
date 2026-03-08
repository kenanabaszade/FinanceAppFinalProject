//
//  Transaction.swift
//  FinanceApp
//
//  Created by Macbook on 23.02.26.
//

import Foundation
import FirebaseFirestore

enum TransactionType: String, Codable {
    case send
    case receive
    case request
    case topUp
    case exchange
    case purchase
}

struct TransactionPayload: Codable {
    let userId: String
    let amount: Double
    let currency: String
    let merchantName: String
    var category: String?
    var counterpartyUserId: String? 
    var paymentReference: String?
    let type: TransactionType
    let date: Date
    let createdAt: Date
}
 
struct TransactionRecord {
    let id: String
    let userId: String
    let amount: Double
    let currency: String
    let merchantName: String
    var category: String?
    var counterpartyUserId: String?
    var paymentReference: String?
    let type: TransactionType
    let date: Date
    let createdAt: Date

    init(id: String, payload: TransactionPayload) {
        self.id = id
        self.userId = payload.userId
        self.amount = payload.amount
        self.currency = payload.currency
        self.merchantName = payload.merchantName
        self.category = payload.category
        self.counterpartyUserId = payload.counterpartyUserId
        self.paymentReference = payload.paymentReference
        self.type = payload.type
        self.date = payload.date
        self.createdAt = payload.createdAt
    }

    init(
        id: String,
        userId: String,
        amount: Double,
        currency: String,
        merchantName: String,
        category: String? = nil,
        counterpartyUserId: String? = nil,
        paymentReference: String? = nil,
        type: TransactionType,
        date: Date,
        createdAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.currency = currency
        self.merchantName = merchantName
        self.category = category
        self.counterpartyUserId = counterpartyUserId
        self.paymentReference = paymentReference
        self.type = type
        self.date = date
        self.createdAt = createdAt
    }
}
