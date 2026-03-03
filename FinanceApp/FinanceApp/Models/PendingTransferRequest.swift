//
//  PendingTransferRequest.swift
//  FinanceApp
//

import Foundation
import FirebaseFirestore

enum PendingTransferStatus: String, Codable {
    case pending
    case accepted
    case rejected
    case expired
}

struct PendingTransferRequest {
    let id: String
    let senderId: String
    let senderDisplayName: String
    let recipientId: String
    let recipientDisplayName: String
    let amount: Double
    let currency: String
    let fromAccountId: String
    var status: PendingTransferStatus
    var recipientAccountId: String?
    let createdAt: Date

    var isPending: Bool { status == .pending }
}
