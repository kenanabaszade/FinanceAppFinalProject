//
//  AppNotification.swift
//  FinanceApp
//

import Foundation

enum NotificationType: String, Codable {
    case transferReceived = "transfer_received"
    case transferSent = "transfer_sent"
    case payment = "payment"
    case topUp = "top_up"
    case generic = "generic"
}

struct NotificationPayload: Codable {
    let userId: String
    let title: String
    var body: String?
    var read: Bool
    var type: String?
    var transactionId: String?
    var amount: Double?
    var currency: String?
    let createdAt: Date
}

struct NotificationRecord {
    let id: String
    let userId: String
    let title: String
    var body: String?
    var read: Bool
    var type: String?
    var transactionId: String?
    var amount: Double?
    var currency: String?
    let createdAt: Date

    init(id: String, payload: NotificationPayload) {
        self.id = id
        self.userId = payload.userId
        self.title = payload.title
        self.body = payload.body
        self.read = payload.read
        self.type = payload.type
        self.transactionId = payload.transactionId
        self.amount = payload.amount
        self.currency = payload.currency
        self.createdAt = payload.createdAt
    }
}
