//
//  NotificationsViewModel.swift
//  FinanceApp
//

import Foundation
import Combine

struct NotificationSection {
    let title: String
    let notifications: [NotificationRecord]
}

@MainActor
final class NotificationsViewModel: ObservableObject {

    @Published private(set) var sections: [NotificationSection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var unreadCount = 0

    private var allNotifications: [NotificationRecord] = []
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "az_AZ")
        f.dateFormat = "d MMMM"
        return f
    }()

    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }

    func loadNotifications() async {
        guard let userId = authService.currentUserId() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            allNotifications = try await firestoreService.getNotifications(userId: userId, limit: AppConstants.Notifications.limit)
            buildSections()
            unreadCount = try await firestoreService.getUnreadNotificationsCount(userId: userId)
        } catch {
            allNotifications = []
            sections = []
            unreadCount = 0
            errorMessage = Self.friendlyErrorMessage(for: error)
        }
    }

    func markAsRead(_ notification: NotificationRecord) async {
        guard !notification.read else { return }
        guard let userId = authService.currentUserId() else { return }
        do {
            try await firestoreService.markNotificationAsRead(notificationId: notification.id)
            if let idx = allNotifications.firstIndex(where: { $0.id == notification.id }) {
                let n = allNotifications[idx]
                allNotifications[idx] = NotificationRecord(
                    id: n.id,
                    payload: NotificationPayload(
                        userId: n.userId,
                        title: n.title,
                        body: n.body,
                        read: true,
                        type: n.type,
                        transactionId: n.transactionId,
                        amount: n.amount,
                        currency: n.currency,
                        createdAt: n.createdAt
                    )
                )
            }
            buildSections()
            unreadCount = try await firestoreService.getUnreadNotificationsCount(userId: userId)
        } catch {}
    }

    func markAllAsRead() async {
        guard let userId = authService.currentUserId() else { return }
        do {
            try await firestoreService.markAllNotificationsAsRead(userId: userId)
            allNotifications = allNotifications.map { n in
                NotificationRecord(
                    id: n.id,
                    payload: NotificationPayload(
                        userId: n.userId,
                        title: n.title,
                        body: n.body,
                        read: true,
                        type: n.type,
                        transactionId: n.transactionId,
                        amount: n.amount,
                        currency: n.currency,
                        createdAt: n.createdAt
                    )
                )
            }
            buildSections()
            unreadCount = 0
        } catch {}
    }

    func refreshUnreadCount() async {
        guard let userId = authService.currentUserId() else { return }
        do {
            unreadCount = try await firestoreService.getUnreadNotificationsCount(userId: userId)
        } catch {}
    }

    private func buildSections() {
        var grouped: [String: [NotificationRecord]] = [:]
        for n in allNotifications {
            let key = sectionKey(for: n.createdAt)
            grouped[key, default: []].append(n)
        }
        for key in grouped.keys {
            grouped[key]?.sort { $0.createdAt > $1.createdAt }
        }
        let order = orderedSectionKeys(from: grouped.keys, grouped: grouped)
        sections = order.compactMap { key in
            guard let list = grouped[key], !list.isEmpty else { return nil }
            return NotificationSection(title: key, notifications: list)
        }
    }

    private func sectionKey(for date: Date) -> String {
        if calendar.isDateInToday(date) { return "BUGÜN" }
        if calendar.isDateInYesterday(date) { return "DÜNƏN" }
        return dateFormatter.string(from: date).uppercased()
    }

    private static func friendlyErrorMessage(for error: Error) -> String {
        let msg = error.localizedDescription
        if msg.lowercased().contains("index") || msg.contains("requires an index") {
            return "Firestore index is required. Create it in Firebase Console → Firestore → Indexes. See Docs/Notifications-Center-Setup.md for details."
        }
        return msg
    }

    private func orderedSectionKeys(from keys: Dictionary<String, [NotificationRecord]>.Keys, grouped: [String: [NotificationRecord]]) -> [String] {
        let keyArray = Array(keys)
        var order: [String] = []
        if keyArray.contains("BUGÜN") { order.append("BUGÜN") }
        if keyArray.contains("DÜNƏN") { order.append("DÜNƏN") }
        let other = keyArray.filter { $0 != "BUGÜN" && $0 != "DÜNƏN" }
        let sortedOther = other.sorted { key1, key2 in
            let d1 = grouped[key1]?.first?.createdAt ?? .distantPast
            let d2 = grouped[key2]?.first?.createdAt ?? .distantPast
            return d1 > d2
        }
        return order + sortedOther
    }
}
