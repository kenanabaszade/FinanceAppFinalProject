//
//  HistoryViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 28.02.26.
//
import Foundation
import Combine

enum HistoryFilter: String, CaseIterable {
    case all = "Hamısı"
    case income = "Gəlir"
    case expense = "Xərc"
    case category = "Kateqoriya"
}

struct HistorySection {
    let title: String
    let transactions: [TransactionRecord]
}

@MainActor
final class HistoryViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published var selectedFilter: HistoryFilter = .all
    @Published private(set) var sections: [HistorySection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var allTransactions: [TransactionRecord] = []
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

    func loadTransactions() async {
        guard let userId = authService.currentUserId() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            allTransactions = try await firestoreService.getRecentTransactions(userId: userId, limit: AppConstants.History.transactionLimit)
            buildSections()
        } catch {
            allTransactions = []
            sections = []
            errorMessage = error.localizedDescription
        }
    }

    func setFilter(_ filter: HistoryFilter) {
        selectedFilter = filter
        buildSections()
    }

    func refreshSections() {
        buildSections()
    }

    private var filteredTransactions: [TransactionRecord] {
        var list = allTransactions
        switch selectedFilter {
        case .all: break
        case .income: list = list.filter { Self.isIncome($0) }
        case .expense: list = list.filter { Self.isExpense($0) }
        case .category: break
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.merchantName.lowercased().contains(q) ||
                String(format: "%.2f", abs($0.amount)).contains(q) ||
                ($0.paymentReference?.lowercased().contains(q) ?? false)
            }
        }
        return list
    }

    private func buildSections() {
        let list = filteredTransactions
        var grouped: [String: [TransactionRecord]] = [:]
        for tx in list {
            let key = sectionKey(for: tx.date)
            grouped[key, default: []].append(tx)
        }
        for key in grouped.keys {
            grouped[key]?.sort { $0.date > $1.date }
        }
        let order = orderedSectionKeys(from: grouped.keys, grouped: grouped)
        sections = order.compactMap { key in
            guard let txs = grouped[key], !txs.isEmpty else { return nil }
            return HistorySection(title: key, transactions: txs)
        }
    }

    private func sectionKey(for date: Date) -> String {
        if calendar.isDateInToday(date) { return "BUGÜN" }
        if calendar.isDateInYesterday(date) { return "DÜNƏN" }
        return dateFormatter.string(from: date).uppercased()
    }

    private func orderedSectionKeys(from keys: Dictionary<String, [TransactionRecord]>.Keys, grouped: [String: [TransactionRecord]]) -> [String] {
        let keyArray = Array(keys)
        var order: [String] = []
        if keyArray.contains("BUGÜN") { order.append("BUGÜN") }
        if keyArray.contains("DÜNƏN") { order.append("DÜNƏN") }
        let other = keyArray.filter { $0 != "BUGÜN" && $0 != "DÜNƏN" }
        let sortedOther = other.sorted { key1, key2 in
            let d1 = grouped[key1]?.first?.date ?? .distantPast
            let d2 = grouped[key2]?.first?.date ?? .distantPast
            return d1 > d2
        }
        return order + sortedOther
    }

    static func isIncome(_ tx: TransactionRecord) -> Bool {
        switch tx.type {
        case .receive, .topUp: return true
        case .send, .purchase, .request, .exchange: return false
        }
    }

    static func isExpense(_ tx: TransactionRecord) -> Bool {
        switch tx.type {
        case .send, .purchase: return true
        case .receive, .topUp, .request, .exchange: return false
        }
    }
}
