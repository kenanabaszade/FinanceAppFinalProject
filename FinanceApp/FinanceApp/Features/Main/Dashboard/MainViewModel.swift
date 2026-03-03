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
            let fetched = try await firestoreService.getUser(uid: uid)
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
            async let userTask = firestoreService.getUser(uid: uid)
            async let accountsTask = firestoreService.getAccounts(userId: uid)
            async let cardsTask = firestoreService.getCards(userId: uid, source: .server)
            async let transactionsTask = firestoreService.getRecentTransactions(userId: uid, limit: 20)
            async let unreadTask = firestoreService.getUnreadNotificationsCount(userId: uid)

            let fetchedUser = try await userTask
            user = fetchedUser
            if let fetchedUser = fetchedUser {
                UserCache.shared.setCachedUser(fetchedUser)
            }
            accounts = try await accountsTask
            cards = try await cardsTask
            recentTransactions = try await transactionsTask
            unreadNotificationsCount = try await unreadTask
        } catch {
            user = authService.currentUserId().flatMap { UserCache.shared.getCachedUser(uid: $0) }
            accounts = []
            cards = []
            recentTransactions = []
            unreadNotificationsCount = 0
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

    /// Sum of balances for all accounts in the given currency (handles duplicate accounts from migration).
    func totalBalanceForCurrency(_ currency: String) -> Double {
        accounts.filter { $0.currency == currency }.reduce(0) { $0 + $1.amount }
    }

    /// Single account for currency; prefers canonical "userId_currency" for transfer/card linking.
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
