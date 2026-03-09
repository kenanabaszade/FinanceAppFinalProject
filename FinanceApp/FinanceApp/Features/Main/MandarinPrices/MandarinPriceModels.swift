//
//  MandarinPriceModels.swift
//  FinanceApp
//
   
import Foundation
 

struct MandarinPriceItem: Decodable {
    let id: Int
    let store: String
    let product: String
    let price: String
    let mass: String?
    let brand: String?
    let created_at: String
}

struct PricesResponse: Decodable {
    let prices: [MandarinPriceItem]
}
 
struct LatestStorePrice: Identifiable {
    let store: String
    let displayName: String
    let pricePerKg: Double
    let date: Date
    let imageName: String
    var id: String { store }
}
 
enum MandarinStoreMapping {
    static func displayName(for store: String) -> String {
        switch store.lowercased() {
        case "e-meyve": return "E-Meyve"
        case "arazmarket": return "Araz Supermarket"
        case "bazarstore": return "Bazarstore"
        default: return store
        }
    }

    static func imageName(for store: String) -> String {
        switch store.lowercased() {
        case "e-meyve": return "emeyve"
        case "arazmarket": return "araz"
        case "bazarstore": return "bazarstore"
        default: return ""
        }
    }
}
 
private let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

private let isoFormatterNoFraction: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()

private func parseCreatedAt(_ s: String) -> Date {
    isoFormatter.date(from: s) ?? isoFormatterNoFraction.date(from: s) ?? .distantPast
}

func latestPricesByStore(from response: PricesResponse) -> [LatestStorePrice] {
    let grouped = Dictionary(grouping: response.prices) { $0.store }
    return grouped.compactMap { store, items -> LatestStorePrice? in
        guard let latest = items.max(by: { parseCreatedAt($0.created_at) < parseCreatedAt($1.created_at) }) else { return nil }
        let priceValue = Double(latest.price) ?? 0
        let perKg: Double
        if let mass = latest.mass?.lowercased() {
            if mass.hasPrefix("0.5") || mass == "0.5kg" {
                perKg = priceValue * 2
            } else {
                perKg = priceValue
            }
        } else {
            perKg = priceValue
        }
        let date = parseCreatedAt(latest.created_at)
        return LatestStorePrice(
            store: latest.store,
            displayName: MandarinStoreMapping.displayName(for: latest.store),
            pricePerKg: perKg,
            date: date,
            imageName: MandarinStoreMapping.imageName(for: latest.store)
        )
    }
}

func averagePricePerKg(from latest: [LatestStorePrice]) -> Double? {
    guard !latest.isEmpty else { return nil }
    let sum = latest.reduce(0.0) { $0 + $1.pricePerKg }
    return sum / Double(latest.count)
}
 
#if DEBUG
private func debugLog(_ message: String) { print("[MandarinPrices] \(message)") }
#else
private func debugLog(_ message: String) {}
#endif

enum MandarinPricesService {
    static let pricesURL = URL(string: "http://130.185.118.30:3000/prices")!

    static func fetchPrices() async throws -> [LatestStorePrice] {
        debugLog("Fetching: \(pricesURL.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: pricesURL)
        if let http = response as? HTTPURLResponse {
            debugLog("HTTP status: \(http.statusCode)")
        }
        let rawString = String(data: data, encoding: .utf8)
        let preview = rawString.map { String($0.prefix(800)) } ?? "nil"
        debugLog("Response preview: \(preview)")

        do {
            let responseModel = try JSONDecoder().decode(PricesResponse.self, from: data)
            let result = latestPricesByStore(from: responseModel)
            debugLog("Decoded \(responseModel.prices.count) items -> \(result.count) stores")
            return result
        } catch {
            debugLog("Decode error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    debugLog("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    debugLog("Type mismatch \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    debugLog("Value not found \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    debugLog("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    break
                }
            }
            throw error
        }
    }
}
