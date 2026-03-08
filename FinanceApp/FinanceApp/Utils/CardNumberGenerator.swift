//
//  CardNumberGenerator.swift
//  FinanceApp
//

import Foundation
 
enum CardNumberGenerator {
 
    static func luhnCheckDigit(for digits: String) -> Character {
        let digitsArray = digits.compactMap { $0.wholeNumberValue }
        var sum = 0
        let reversed = digitsArray.reversed()
        for (index, digit) in reversed.enumerated() {
            var value = digit
            if index % 2 == 1 {
                value *= 2
                if value > 9 { value -= 9 }
            }
            sum += value
        }
        let check = (10 - (sum % 10)) % 10
        return Character(Unicode.Scalar(48 + check)!)
    }
 
    static func generateNumber(brand: CardBrand) -> String {
        let prefix: String
        let lengthAfterPrefix: Int
        switch brand {
        case .visa:
            prefix = "4"
            lengthAfterPrefix = 14
        case .mastercard:
            let prefixes = ["51", "52", "53", "54", "55"]
            prefix = prefixes.randomElement()!
            lengthAfterPrefix = 13
        }
        var digits = prefix
        for _ in 0..<lengthAfterPrefix {
            digits += String(Int.random(in: 0...9))
        }
        digits += String(luhnCheckDigit(for: digits))
        return digits
    }
 
    static func generateExpiryDate() -> String {
        let calendar = Calendar.current
        let now = Date()
        let yearOffset = Int.random(in: 2...5)
        guard let future = calendar.date(byAdding: .year, value: yearOffset, to: now) else {
            let components = calendar.dateComponents([.month, .year], from: now)
            let y = (components.year ?? 0) + 3
            let m = components.month ?? 6
            return String(format: "%02d/%02d", m, y % 100)
        }
        let components = calendar.dateComponents([.month, .year], from: future)
        let month = components.month ?? 1
        let year = (components.year ?? 0) % 100
        return String(format: "%02d/%02d", month, year)
    }
}
