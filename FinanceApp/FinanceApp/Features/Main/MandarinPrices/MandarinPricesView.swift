//
//  MandarinPricesView.swift
//  FinanceApp
//
 

import SwiftUI
import UIKit
 
enum MandarinSortOrder: String, CaseIterable {
    case ascending = "Artan sırala"
    case descending = "Azalan sırala"
}
 
private func formattedDate(_ date: Date) -> String {
    let cal = Calendar.current
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    if cal.isDateInToday(date) {
        return "BU GÜN, \(timeFormatter.string(from: date))"
    } else if cal.isDateInYesterday(date) {
        return "DÜNƏN, \(timeFormatter.string(from: date))"
    } else {
        let df = DateFormatter()
        df.dateFormat = "dd.MM, HH:mm"
        return df.string(from: date).uppercased()
    }
}
 
struct MandarinPricesView: View {
    @State private var items: [LatestStorePrice] = []
    @State private var sortOrder: MandarinSortOrder = .ascending
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var loadTask: Task<Void, Never>?

    private var sortedItems: [LatestStorePrice] {
        switch sortOrder {
        case .ascending: return items.sorted { $0.pricePerKg < $1.pricePerKg }
        case .descending: return items.sorted { $0.pricePerKg > $1.pricePerKg }
        }
    }

    private var averagePrice: Double? {
        averagePricePerKg(from: items)
    }

    private var mandarinOrange: Color { Color(uiColor: AppConstants.Colors.mandarinOrange) }
    private var cardBackground: Color { Color(uiColor: AppConstants.Colors.authCardBackground) }
    private var titleColor: Color { Color(uiColor: AppConstants.Colors.authTitle) }
    private var subtitleColor: Color { Color(uiColor: AppConstants.Colors.authSubtitle) }
    private var cornerRadius: CGFloat { AppConstants.Sizes.cornerRadius }
    private var spacing: CGFloat { AppConstants.Spacing.medium }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: AppConstants.Colors.authBackground)
                    .ignoresSafeArea()

                if isLoading && items.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(mandarinOrange)
                        Text("Yüklənir...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(subtitleColor)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage, items.isEmpty {
                    VStack(spacing: 16) {
                        Text(error)
                            .font(.system(size: 15))
                            .foregroundColor(subtitleColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Yenidən cəhd edin") {
                            loadPrices()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(mandarinOrange)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: spacing) {
                            averageCard
                            sortPills
                            listContent
                        }
                        .padding(.horizontal, spacing)
                        .padding(.bottom, 24)
                    }
                    .refreshable { await refreshPrices() }
                }
            }
            .navigationTitle("Mandarin Qiymətləri")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear { loadPrices() }
        }
    }

    private var averageCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("GÜNÜN ORTALAMASI")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(mandarinOrange)
                if let avg = averagePrice {
                    Text(String(format: "%.2f ₼ /kg", avg))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(titleColor)
                } else {
                    Text("— ₼ /kg")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(titleColor)
                }
            }
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 24))
                .foregroundColor(mandarinOrange)
                .frame(width: 44, height: 44)
                .background(mandarinOrange.opacity(0.2))
                .cornerRadius(10)
        }
        .padding(spacing)
        .background(cardBackground)
        .cornerRadius(cornerRadius)
    }

    private var sortPills: some View {
        HStack(spacing: 10) {
            ForEach(MandarinSortOrder.allCases, id: \.self) { order in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sortOrder = order
                    }
                } label: {
                    Text(order.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(sortOrder == order ? .white : titleColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(sortOrder == order ? mandarinOrange : cardBackground)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedItems) { item in
                marketRow(item)
            }
        }
    }

    private func marketRow(_ item: LatestStorePrice) -> some View {
        HStack(spacing: 12) {
            storeImage(item.imageName)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(titleColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f ₼", item.pricePerKg))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(titleColor)
                Text(formattedDate(item.date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(subtitleColor)
            }
        }
        .padding(12)
        .background(cardBackground)
        .cornerRadius(cornerRadius)
    }

    @ViewBuilder
    private func storeImage(_ imageName: String) -> some View {
        if !imageName.isEmpty, let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: "building.2.fill")
                .font(.system(size: 24))
                .foregroundColor(subtitleColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: AppConstants.Colors.authInputBackground))
        }
    }

    private func loadPrices() {
        loadTask?.cancel()
        loadTask = Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            do {
                let result = try await MandarinPricesService.fetchPrices()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        items = result
                    }
                }
            } catch {
                await MainActor.run {
                    #if DEBUG
                    errorMessage = "Məlumat yüklənə bilmədi.\n\(error.localizedDescription)"
                    #else
                    errorMessage = "Məlumat yüklənə bilmədi."
                    #endif
                }
            }
        }
    }

    private func refreshPrices() async {
        do {
            let result = try await MandarinPricesService.fetchPrices()
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    items = result
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Məlumat yenilənə bilmədi."
            }
        }
    }
}

#if DEBUG
struct MandarinPricesView_Previews: PreviewProvider {
    static var previews: some View {
        MandarinPricesView()
    }
}
#endif
