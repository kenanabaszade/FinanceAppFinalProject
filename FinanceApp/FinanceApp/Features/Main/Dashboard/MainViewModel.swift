//
//  MainViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 10.02.26.
//

import Foundation
import Combine
internal import FirebaseFirestoreInternal

@MainActor
final class MainViewModel: ObservableObject {
    
    @Published private(set) var user: User?
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var cards: [Card] = []
    @Published private(set) var recentTransactions: [TransactionRecord] = []
    @Published private(set) var unreadNotificationsCount: Int = 0
    @Published private(set) var isLoading = false
    
    @Published var selectedCurrency: String = "AZN"
    @Published var balanceVisible: Bool = true
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func loadUser() async {
        guard let uid = authService.currentUserId() else {
            user = nil
            return
        }
        if let cached = UserCache.shared.getCachedUser(uid: uid) {
            user = cached
        }
        do {
            var fetched = try await firestoreService.getUser(uid: uid)
            if fetched == nil {
                var newUser = User(uid: uid)
                newUser.email = authService.currentUserEmail()
                try await firestoreService.saveUser(newUser)
                fetched = newUser
            }
            user = fetched
            if let fetched = fetched {
                UserCache.shared.setCachedUser(fetched)
            }
        } catch {
            user = UserCache.shared.getCachedUser(uid: uid)
        }
    }
    
    func loadDashboard() async {
        guard let uid = authService.currentUserId() else { return }
        if let cached = UserCache.shared.getCachedUser(uid: uid) {
            user = cached
        }
        isLoading = true
        defer { isLoading = false }
        
        do {
            var fetchedUser = try await firestoreService.getUser(uid: uid)
            if fetchedUser == nil {
                var newUser = User(uid: uid)
                newUser.email = authService.currentUserEmail()
                try await firestoreService.saveUser(newUser)
                fetchedUser = newUser
            }
            if let fetchedUser = fetchedUser {
                user = fetchedUser
                UserCache.shared.setCachedUser(fetchedUser)
            }
        } catch {
            print("loadDashboard: failed to load user –", error)
        }
        
        do {
            accounts = try await firestoreService.getAccounts(userId: uid)
        } catch {
            print("loadDashboard: failed to load accounts –", error)
        }
        
        do {
            cards = try await firestoreService.getCards(userId: uid, source: .server)
        } catch {
            print("loadDashboard: failed to load cards –", error)
        }
        
        do {
            recentTransactions = try await firestoreService.getRecentTransactions(userId: uid, limit: 20)
        } catch {
            print("loadDashboard: failed to load recent transactions –", error)
        }
        
        do {
            unreadNotificationsCount = try await firestoreService.getUnreadNotificationsCount(userId: uid)
        } catch {
            print("loadDashboard: failed to load unread notifications –", error)
        }
    }
    
    var displayName: String {
        guard let user = user else { return "—" }
        let fullName = [user.firstName, user.lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return fullName.isEmpty ? "User" : fullName
    }
    
    var displayEmail: String {
        user?.email ?? "—"
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    
    func totalBalanceForCurrency(_ currency: String) -> Double {
        accounts.filter { $0.currency == currency }.reduce(0) { $0 + $1.amount }
    }
    
    func balanceForAccount(_ accountId: String?) -> Double {
        guard let accountId = accountId, !accountId.isEmpty,
              let account = accounts.first(where: { $0.id == accountId }) else { return 0 }
        return account.amount
    }
    
    func accountForCurrency(_ currency: String) -> Account? {
        guard let uid = authService.currentUserId() else {
            return accounts.first { $0.currency == currency }
        }
        let canonicalId = "\(uid)_\(currency)"
        return accounts.first { $0.id == canonicalId } ?? accounts.first { $0.currency == currency }
    }
    
    var displayedBalance: String {
        guard balanceVisible else { return "••••••••" }
        let amount = totalBalanceForCurrency(selectedCurrency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "0.00"
    }
    
    var currencySymbol: String {
        switch selectedCurrency {
        case "AZN": return "₼"
        case "USD": return "$"
        default: return selectedCurrency + " "
        }
    }
    
    func refreshUnreadNotificationsCount() async {
        guard let uid = authService.currentUserId() else { return }
        do {
            unreadNotificationsCount = try await firestoreService.getUnreadNotificationsCount(userId: uid)
        } catch {}
    }
    
}
