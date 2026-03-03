import Foundation
import Combine

@MainActor
final class TopUpViewModel: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published var selectedAccount: Account?
    @Published var amountText = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = true
    @Published private(set) var topUpSuccess = false

    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }

    func loadAccounts() async {
        guard let userId = authService.currentUserId() else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            accounts = try await firestoreService.getAccounts(userId: userId)
            if selectedAccount == nil || !accounts.contains(where: { $0.id == selectedAccount?.id }) {
                selectedAccount = accounts.first
            }
        } catch {
            accounts = []
            errorMessage = "Could not load accounts"
        }
    }

    func addMoney() async {
        guard let userId = authService.currentUserId() else { return }
        guard let account = selectedAccount else {
            errorMessage = "Please select an account"
            return
        }
        guard amount > 0 else {
            errorMessage = "Enter an amount"
            return
        }
        errorMessage = nil
        do {
            try await firestoreService.topUp(userId: userId, accountId: account.id, amount: amount, currency: account.currency)
            topUpSuccess = true
            amountText = ""
            let updated = Account(id: account.id, userId: account.userId, currency: account.currency, amount: account.amount + amount, updatedAt: Date())
            if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
                accounts[idx] = updated
            }
            selectedAccount = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearSuccess() {
        topUpSuccess = false
    }
}
