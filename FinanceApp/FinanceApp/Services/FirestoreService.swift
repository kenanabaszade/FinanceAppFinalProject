import Foundation
import FirebaseFirestore

/// Parameters for a peer-to-peer money transfer.
struct TransferRequest {
    let senderId: String
    let recipientId: String
    let senderDisplayName: String
    let recipientDisplayName: String
    let amount: Double
    let currency: String
    /// Sender's account document ID to debit from (e.g. from selected card’s accountId).
    let fromAccountId: String
    /// Recipient's chosen account to receive into. If nil, uses recipientId_currency.
    let recipientAccountId: String?
}

protocol FirestoreServiceProtocol {
    func saveUser(_ user: User) async throws
    func getUser(uid: String) async throws -> User?
    func updateUser(_ user: User) async throws
    func getAllRecipients(excludingUserId: String) async throws -> [User]
    func getAccounts(userId: String) async throws -> [Account]
    func getCards(userId: String, source: FirestoreSource?) async throws -> [Card]
    /// Creates an account and a linked card; returns the new Card.
    func addCard(userId: String, name: String, type: CardType, brand: CardBrand, fullNumber: String, expiryDate: String, currency: String) async throws -> Card
    /// Deletes a card from Firestore. Does not delete the linked account (balance may remain).
    func deleteCard(cardId: String, userId: String) async throws
    func getRecentTransactions(userId: String, limit: Int) async throws -> [TransactionRecord]
    func getUnreadNotificationsCount(userId: String) async throws -> Int
    func createNotification(userId: String, title: String, body: String?, type: String?, transactionId: String?, amount: Double?, currency: String?) async throws
    func getNotifications(userId: String, limit: Int) async throws -> [NotificationRecord]
    func markNotificationAsRead(notificationId: String) async throws
    func markAllNotificationsAsRead(userId: String) async throws
    /// Transfer money from sender’s account to recipient’s account. Creates transaction records for both.
    func transfer(_ request: TransferRequest) async throws
    func createPendingTransferRequest(senderId: String, senderDisplayName: String, recipientId: String, recipientDisplayName: String, amount: Double, currency: String, fromAccountId: String) async throws -> String
    func getPendingTransferRequests(recipientId: String) async throws -> [PendingTransferRequest]
    func getPendingTransferRequest(requestId: String) async throws -> PendingTransferRequest?
    func acceptPendingTransferRequest(requestId: String, recipientId: String, recipientAccountId: String) async throws
    func rejectPendingTransferRequest(requestId: String, recipientId: String) async throws
    func topUp(userId: String, accountId: String, amount: Double, currency: String) async throws
    /// Deduct from user's account for a payment (e.g. bill, merchant). Creates a transaction record.
    func payFromAccount(userId: String, accountId: String, amount: Double, currency: String, merchantName: String, category: String, reference: String?) async throws
}

enum FirestoreCollection {
    static let users = "users"
    static let accounts = "accounts"
    static let cards = "cards"
    static let transactions = "transactions"
    static let notifications = "notifications"
    static let pendingTransferRequests = "pending_transfer_requests"
}

class FirestoreService: FirestoreServiceProtocol {
    private let db = Firestore.firestore()

    func saveUser(_ user: User) async throws {
        let documentRef = db.collection(FirestoreCollection.users).document(user.uid)
        try documentRef.setData(from: user.toPayload())
    }

    func getUser(uid: String) async throws -> User? {
        let document = try await db.collection(FirestoreCollection.users).document(uid).getDocument()
        guard document.exists else { return nil }
        let payload = try document.data(as: UserPayload.self)
        return User(uid: document.documentID, payload: payload)
    }

    func updateUser(_ user: User) async throws {
        var payload = user.toPayload()
        payload.updatedAt = Date()
        let documentRef = db.collection(FirestoreCollection.users).document(user.uid)
        try documentRef.setData(from: payload, merge: true)
    }

    func getAllRecipients(excludingUserId: String) async throws -> [User] {
        let snapshot = try await db.collection(FirestoreCollection.users).getDocuments(source: .server)
        let allDocs = snapshot.documents
        let others = allDocs.filter { $0.documentID != excludingUserId }
        var users: [User] = []
        for doc in others {
            if let user = decodeUserDocument(doc) {
                users.append(user)
            }
        }
        #if DEBUG
        print("[SendMoney] Firestore users: total docs=\(allDocs.count), excluding self=\(others.count), decoded=\(users.count). Current uid=\(excludingUserId)")
        #endif
        return users
    }

    private func decodeUserDocument(_ doc: DocumentSnapshot) -> User? {
        let docId = doc.documentID
        if let payload = try? doc.data(as: UserPayloadLenient.self) {
            return User(uid: docId, payload: payload.toUserPayload(fallbackUid: docId))
        }
        guard let data = doc.data() else { return nil }
        let fallback = Date()
        func str(_ key: String, _ key2: String? = nil) -> String? {
            (data[key] as? String) ?? (key2.flatMap { data[$0] as? String })
        }
        let payload = UserPayload(
            uid: docId,
            email: str("email"),
            firstName: str("firstName", "first_name"),
            lastName: str("lastName", "last_name"),
            phone: str("phone"),
            profileImageURL: str("profileImageURL", "profile_image_url"),
            profileImageBase64: str("profileImageBase64", "profile_image_base64"),
            country: str("country"),
            countryCode: str("countryCode", "country_code"),
            dateOfBirth: (data["dateOfBirth"] as? Timestamp ?? data["date_of_birth"] as? Timestamp)?.dateValue(),
            isEmailVerified: data["isEmailVerified"] as? Bool ?? data["is_email_verified"] as? Bool,
            onboardingStep: data["onboardingStep"] as? Int ?? data["onboarding_step"] as? Int,
            purposes: data["purposes"] as? [String],
            selectedPlan: str("selectedPlan", "selected_plan"),
            cardType: str("cardType", "card_type"),
            hasCard: data["hasCard"] as? Bool ?? data["has_card"] as? Bool,
            pinSet: data["pinSet"] as? Bool ?? data["pin_set"] as? Bool,
            createdAt: (data["createdAt"] as? Timestamp ?? data["created_at"] as? Timestamp)?.dateValue() ?? fallback,
            updatedAt: (data["updatedAt"] as? Timestamp ?? data["updated_at"] as? Timestamp)?.dateValue() ?? fallback
        )
        return User(uid: docId, payload: payload)
    }

    func getAccounts(userId: String) async throws -> [Account] {
        let snapshot = try await db.collection(FirestoreCollection.accounts)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return try snapshot.documents.map { doc in
            let payload = try doc.data(as: AccountPayload.self)
            return Account(id: doc.documentID, payload: payload)
        }
    }

    func getCards(userId: String, source: FirestoreSource? = nil) async throws -> [Card] {
        var query = db.collection(FirestoreCollection.cards)
            .whereField("userId", isEqualTo: userId)
        let snapshot: QuerySnapshot
        if let src = source {
            snapshot = try await query.getDocuments(source: src)
        } else {
            snapshot = try await query.getDocuments()
        }
        let cards = try snapshot.documents.map { doc in
            let payload = try doc.data(as: CardPayload.self)
            return Card(id: doc.documentID, payload: payload)
        }
        return cards.sorted { $0.createdAt > $1.createdAt }
    }

    func addCard(userId: String, name: String, type: CardType, brand: CardBrand, fullNumber: String, expiryDate: String, currency: String) async throws -> Card {
        let now = Date()
        // Use deterministic ID so transfer can find/update the same account (userId_currency)
        let accountDocId = "\(userId)_\(currency)"
        let accountRef = db.collection(FirestoreCollection.accounts).document(accountDocId)
        let existingDoc = try await accountRef.getDocument()
        if !existingDoc.exists {
            let accountPayload = AccountPayload(userId: userId, currency: currency, amount: 0, updatedAt: now)
            try accountRef.setData(from: accountPayload)
        }

        let lastFour = String(fullNumber.suffix(4))
        let maskedNumber = "••••  ••••  ••••  \(lastFour)"
        let cardRef = db.collection(FirestoreCollection.cards).document()
        let cardPayload = CardPayload.forAddCard(
            userId: userId,
            name: name,
            type: type,
            brand: brand,
            fullNumber: fullNumber,
            lastFourDigits: lastFour,
            maskedNumber: maskedNumber,
            expiryDate: expiryDate,
            createdAt: now,
            currency: currency,
            accountId: accountRef.documentID
        )
        try cardRef.setData(from: cardPayload)
        return Card(id: cardRef.documentID, payload: cardPayload)
    }

    func deleteCard(cardId: String, userId: String) async throws {
        let ref = db.collection(FirestoreCollection.cards).document(cardId)
        let doc = try await ref.getDocument()
        guard doc.exists,
              let data = doc.data(),
              let docUserId = data["userId"] as? String,
              docUserId == userId else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Card not found or access denied"])
        }
        try await ref.delete()
    }

    func getRecentTransactions(userId: String, limit: Int = 20) async throws -> [TransactionRecord] {
        let snapshot = try await db.collection(FirestoreCollection.transactions)
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.map { doc in
            let payload = try doc.data(as: TransactionPayload.self)
            return TransactionRecord(id: doc.documentID, payload: payload)
        }
    }

    func getUnreadNotificationsCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection(FirestoreCollection.notifications)
            .whereField("userId", isEqualTo: userId)
            .whereField("read", isEqualTo: false)
            .getDocuments()
        return snapshot.documents.count
    }

    func createNotification(userId: String, title: String, body: String?, type: String?, transactionId: String?, amount: Double?, currency: String?) async throws {
        let ref = db.collection(FirestoreCollection.notifications).document()
        var data: [String: Any] = [
            "userId": userId,
            "title": title,
            "read": false,
            "createdAt": Timestamp(date: Date())
        ]
        if let b = body { data["body"] = b }
        if let t = type { data["type"] = t }
        if let tid = transactionId { data["transactionId"] = tid }
        if let a = amount { data["amount"] = a }
        if let c = currency { data["currency"] = c }
        try await ref.setData(data)
    }

    func getNotifications(userId: String, limit: Int = 50) async throws -> [NotificationRecord] {
        let snapshot = try await db.collection(FirestoreCollection.notifications)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        var results: [NotificationRecord] = []
        for doc in snapshot.documents {
            if let record = decodeNotification(doc: doc) {
                results.append(record)
            }
        }
        return results
    }

    private func decodeNotification(doc: DocumentSnapshot) -> NotificationRecord? {
        guard let data = doc.data() else { return nil }
        guard let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let read = data["read"] as? Bool else { return nil }
        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else if let date = data["createdAt"] as? Date {
            createdAt = date
        } else {
            return nil
        }
        let body = data["body"] as? String
        let type = data["type"] as? String
        let transactionId = data["transactionId"] as? String
        let amount = data["amount"] as? Double
        let currency = data["currency"] as? String
        let payload = NotificationPayload(
            userId: userId,
            title: title,
            body: body,
            read: read,
            type: type,
            transactionId: transactionId,
            amount: amount,
            currency: currency,
            createdAt: createdAt
        )
        return NotificationRecord(id: doc.documentID, payload: payload)
    }

    func markNotificationAsRead(notificationId: String) async throws {
        let ref = db.collection(FirestoreCollection.notifications).document(notificationId)
        try await ref.updateData(["read": true])
    }

    func markAllNotificationsAsRead(userId: String) async throws {
        let snapshot = try await db.collection(FirestoreCollection.notifications)
            .whereField("userId", isEqualTo: userId)
            .whereField("read", isEqualTo: false)
            .getDocuments()
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["read": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func transfer(_ request: TransferRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction({ [weak self] (transaction: FirebaseFirestore.Transaction, errorPointer: NSErrorPointer) in
                guard let self = self else {
                    errorPointer?.pointee = NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])
                    return nil
                }
                do {
                    let accounts = self.db.collection(FirestoreCollection.accounts)
                    let transactionsCol = self.db.collection(FirestoreCollection.transactions)
                    let senderAccountRef = accounts.document(request.fromAccountId)

                    let senderDoc = try transaction.getDocument(senderAccountRef)
                    guard senderDoc.exists,
                          let senderData = senderDoc.data(),
                          let senderUserId = senderData["userId"] as? String,
                          senderUserId == request.senderId,
                          let currency = senderData["currency"] as? String,
                          currency == request.currency,
                          let currentAmount = senderData["amount"] as? Double else {
                        errorPointer?.pointee = NSError(domain: "Transfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid sender account"])
                        return nil
                    }
                    guard currentAmount >= request.amount else {
                        errorPointer?.pointee = NSError(domain: "Transfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Insufficient balance"])
                        return nil
                    }

                    // Recipient's chosen account, or default userId_currency
                    let recipientDocId = request.recipientAccountId ?? "\(request.recipientId)_\(request.currency)"
                    let recipientAccountRef = accounts.document(recipientDocId)
                    let recipientDoc = try transaction.getDocument(recipientAccountRef)
                    if let chosenId = request.recipientAccountId {
                        guard recipientDoc.exists,
                              let recData = recipientDoc.data(),
                              let recUserId = recData["userId"] as? String,
                              recUserId == request.recipientId,
                              let recCurrency = recData["currency"] as? String,
                              recCurrency == request.currency else {
                            errorPointer?.pointee = NSError(domain: "Transfer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid recipient account"])
                            return nil
                        }
                    }
                    let recipientCurrentAmount: Double
                    if recipientDoc.exists, let data = recipientDoc.data(), let amt = data["amount"] as? Double {
                        recipientCurrentAmount = amt
                    } else {
                        recipientCurrentAmount = 0
                    }

                    let now = Date()
                    let newSenderAmount = currentAmount - request.amount
                    transaction.updateData([
                        "amount": newSenderAmount,
                        "updatedAt": Timestamp(date: now)
                    ], forDocument: senderAccountRef)

                    let newRecipientAmount = recipientCurrentAmount + request.amount
                    if recipientDoc.exists {
                        transaction.updateData([
                            "amount": newRecipientAmount,
                            "updatedAt": Timestamp(date: now)
                        ], forDocument: recipientAccountRef)
                    } else {
                        transaction.setData([
                            "userId": request.recipientId,
                            "currency": request.currency,
                            "amount": newRecipientAmount,
                            "updatedAt": Timestamp(date: now)
                        ], forDocument: recipientAccountRef)
                    }

                    let date = Timestamp(date: now)
                    let senderTxRef = transactionsCol.document()
                    let senderTxPayload: [String: Any] = [
                        "userId": request.senderId,
                        "amount": -request.amount,
                        "currency": request.currency,
                        "merchantName": request.recipientDisplayName,
                        "counterpartyUserId": request.recipientId,
                        "type": TransactionType.send.rawValue,
                        "date": date,
                        "createdAt": date
                    ]
                    transaction.setData(senderTxPayload, forDocument: senderTxRef)

                    let recipientTxRef = transactionsCol.document()
                    let recipientTxPayload: [String: Any] = [
                        "userId": request.recipientId,
                        "amount": request.amount,
                        "currency": request.currency,
                        "merchantName": request.senderDisplayName,
                        "counterpartyUserId": request.senderId,
                        "type": TransactionType.receive.rawValue,
                        "date": date,
                        "createdAt": date
                    ]
                    transaction.setData(recipientTxPayload, forDocument: recipientTxRef)

                    let symbol = request.currency == "AZN" ? "₼" : (request.currency == "USD" ? "$" : request.currency)
                    let notifRef = self.db.collection(FirestoreCollection.notifications).document()
                    let notifPayload: [String: Any] = [
                        "userId": request.recipientId,
                        "title": "You received \(String(format: "%.2f", request.amount)) \(symbol) from \(request.senderDisplayName)",
                        "read": false,
                        "createdAt": date,
                        "type": NotificationType.transferReceived.rawValue,
                        "transactionId": recipientTxRef.documentID,
                        "amount": request.amount,
                        "currency": request.currency
                    ]
                    transaction.setData(notifPayload, forDocument: notifRef)

                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }) { _, error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func createPendingTransferRequest(senderId: String, senderDisplayName: String, recipientId: String, recipientDisplayName: String, amount: Double, currency: String, fromAccountId: String) async throws -> String {
        let ref = db.collection(FirestoreCollection.pendingTransferRequests).document()
        let now = Date()
        let data: [String: Any] = [
            "senderId": senderId,
            "senderDisplayName": senderDisplayName,
            "recipientId": recipientId,
            "recipientDisplayName": recipientDisplayName,
            "amount": amount,
            "currency": currency,
            "fromAccountId": fromAccountId,
            "status": PendingTransferStatus.pending.rawValue,
            "createdAt": Timestamp(date: now)
        ]
        try await ref.setData(data)
        let symbol = currency == "AZN" ? "₼" : (currency == "USD" ? "$" : currency)
        try await createNotification(
            userId: recipientId,
            title: "\(senderDisplayName) wants to send you \(String(format: "%.2f", amount)) \(symbol)",
            body: "Choose which card to receive into",
            type: "transfer_request",
            transactionId: ref.documentID,
            amount: amount,
            currency: currency
        )
        return ref.documentID
    }

    func getPendingTransferRequests(recipientId: String) async throws -> [PendingTransferRequest] {
        let snapshot = try await db.collection(FirestoreCollection.pendingTransferRequests)
            .whereField("recipientId", isEqualTo: recipientId)
            .whereField("status", isEqualTo: PendingTransferStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc -> PendingTransferRequest? in
            let data = doc.data()
            guard let senderId = data["senderId"] as? String,
                  let senderDisplayName = data["senderDisplayName"] as? String,
                  let recipientId = data["recipientId"] as? String,
                  let recipientDisplayName = data["recipientDisplayName"] as? String,
                  let amount = data["amount"] as? Double,
                  let currency = data["currency"] as? String,
                  let fromAccountId = data["fromAccountId"] as? String,
                  let statusStr = data["status"] as? String,
                  let status = PendingTransferStatus(rawValue: statusStr) else { return nil }
            let createdAt: Date
            if let ts = data["createdAt"] as? Timestamp {
                createdAt = ts.dateValue()
            } else { return nil }
            let recipientAccountId = data["recipientAccountId"] as? String
            return PendingTransferRequest(
                id: doc.documentID,
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                recipientId: recipientId,
                recipientDisplayName: recipientDisplayName,
                amount: amount,
                currency: currency,
                fromAccountId: fromAccountId,
                status: status,
                recipientAccountId: recipientAccountId,
                createdAt: createdAt
            )
        }
    }

    func getPendingTransferRequest(requestId: String) async throws -> PendingTransferRequest? {
        let doc = try await db.collection(FirestoreCollection.pendingTransferRequests).document(requestId).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        guard let senderId = data["senderId"] as? String,
              let senderDisplayName = data["senderDisplayName"] as? String,
              let recipientId = data["recipientId"] as? String,
              let recipientDisplayName = data["recipientDisplayName"] as? String,
              let amount = data["amount"] as? Double,
              let currency = data["currency"] as? String,
              let fromAccountId = data["fromAccountId"] as? String,
              let statusStr = data["status"] as? String,
              let status = PendingTransferStatus(rawValue: statusStr),
              let ts = data["createdAt"] as? Timestamp else { return nil }
        let recipientAccountId = data["recipientAccountId"] as? String
        return PendingTransferRequest(
            id: doc.documentID,
            senderId: senderId,
            senderDisplayName: senderDisplayName,
            recipientId: recipientId,
            recipientDisplayName: recipientDisplayName,
            amount: amount,
            currency: currency,
            fromAccountId: fromAccountId,
            status: status,
            recipientAccountId: recipientAccountId,
            createdAt: ts.dateValue()
        )
    }

    func rejectPendingTransferRequest(requestId: String, recipientId: String) async throws {
        let ref = db.collection(FirestoreCollection.pendingTransferRequests).document(requestId)
        let doc = try await ref.getDocument()
        guard doc.exists,
              let data = doc.data(),
              (data["recipientId"] as? String) == recipientId,
              (data["status"] as? String) == PendingTransferStatus.pending.rawValue else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid or already processed request"])
        }
        try await ref.updateData(["status": PendingTransferStatus.rejected.rawValue])
    }

    func acceptPendingTransferRequest(requestId: String, recipientId: String, recipientAccountId: String) async throws {
        let ref = db.collection(FirestoreCollection.pendingTransferRequests).document(requestId)
        let doc = try await ref.getDocument()
        guard doc.exists,
              let data = doc.data(),
              let senderId = data["senderId"] as? String,
              let senderDisplayName = data["senderDisplayName"] as? String,
              let recipientDisplayName = data["recipientDisplayName"] as? String,
              let amount = data["amount"] as? Double,
              let currency = data["currency"] as? String,
              let fromAccountId = data["fromAccountId"] as? String,
              let statusStr = data["status"] as? String,
              statusStr == PendingTransferStatus.pending.rawValue else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid or already processed request"])
        }
        let transferReq = TransferRequest(
            senderId: senderId,
            recipientId: recipientId,
            senderDisplayName: senderDisplayName,
            recipientDisplayName: recipientDisplayName,
            amount: amount,
            currency: currency,
            fromAccountId: fromAccountId,
            recipientAccountId: recipientAccountId
        )
        try await transfer(transferReq)
        try await ref.updateData([
            "status": PendingTransferStatus.accepted.rawValue,
            "recipientAccountId": recipientAccountId
        ])
    }

    func topUp(userId: String, accountId: String, amount: Double, currency: String) async throws {
        let accountRef = db.collection(FirestoreCollection.accounts).document(accountId)
        let doc = try await accountRef.getDocument()
        guard doc.exists,
              let data = doc.data(),
              let accountUserId = data["userId"] as? String,
              accountUserId == userId,
              let accountCurrency = data["currency"] as? String,
              accountCurrency == currency,
              let currentAmount = data["amount"] as? Double else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid account"])
        }
        let now = Date()
        let newAmount = currentAmount + amount
        try await accountRef.updateData([
            "amount": newAmount,
            "updatedAt": Timestamp(date: now)
        ])
        let txRef = db.collection(FirestoreCollection.transactions).document()
        let txPayload: [String: Any] = [
            "userId": userId,
            "amount": amount,
            "currency": currency,
            "merchantName": "Top Up",
            "type": TransactionType.topUp.rawValue,
            "date": Timestamp(date: now),
            "createdAt": Timestamp(date: now)
        ]
        try await txRef.setData(txPayload)
        let symbol = currency == "AZN" ? "₼" : (currency == "USD" ? "$" : currency)
        try await createNotification(
            userId: userId,
            title: "Account topped up with \(String(format: "%.2f", amount)) \(symbol)",
            body: nil,
            type: NotificationType.topUp.rawValue,
            transactionId: txRef.documentID,
            amount: amount,
            currency: currency
        )
    }

    func payFromAccount(userId: String, accountId: String, amount: Double, currency: String, merchantName: String, category: String, reference: String?) async throws {
        let accountRef = db.collection(FirestoreCollection.accounts).document(accountId)
        let doc = try await accountRef.getDocument()
        guard doc.exists,
              let data = doc.data(),
              let accountUserId = data["userId"] as? String,
              accountUserId == userId,
              let accountCurrency = data["currency"] as? String,
              accountCurrency == currency,
              let currentAmount = data["amount"] as? Double else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid account"])
        }
        guard currentAmount >= amount else {
            throw NSError(domain: "FirestoreService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Insufficient balance"])
        }
        let now = Date()
        let newAmount = currentAmount - amount
        try await accountRef.updateData([
            "amount": newAmount,
            "updatedAt": Timestamp(date: now)
        ])
        let txRef = db.collection(FirestoreCollection.transactions).document()
        var txPayload: [String: Any] = [
            "userId": userId,
            "amount": -amount,
            "currency": currency,
            "merchantName": merchantName,
            "category": category,
            "type": TransactionType.purchase.rawValue,
            "date": Timestamp(date: now),
            "createdAt": Timestamp(date: now)
        ]
        if let ref = reference, !ref.isEmpty {
            txPayload["paymentReference"] = ref
        }
        try await txRef.setData(txPayload)
        let symbol = currency == "AZN" ? "₼" : (currency == "USD" ? "$" : currency)
        try await createNotification(
            userId: userId,
            title: "Payment of \(String(format: "%.2f", amount)) \(symbol) for \(merchantName)",
            body: nil,
            type: NotificationType.payment.rawValue,
            transactionId: txRef.documentID,
            amount: amount,
            currency: currency
        )
    }
}

