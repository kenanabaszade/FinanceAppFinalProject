//
//  Account.swift
//  FinanceApp
//
//  Created by Macbook on 06.02.26.
//
import Foundation
import FirebaseFirestore

struct AccountPayload: Codable {
    let userId: String
    let currency: String
    var amount: Double
    var updatedAt: Date
}

struct Account {
    let id: String			
    let userId: String
    let currency: String
    var amount: Double
    var updatedAt: Date

    init(id: String, payload: AccountPayload) {
        self.id = id
        self.userId = payload.userId
        self.currency = payload.currency
        self.amount = payload.amount
        self.updatedAt = payload.updatedAt
    }

    init(id: String, userId: String, currency: String, amount: Double, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.currency = currency
        self.amount = amount
        self.updatedAt = updatedAt
    }
}
