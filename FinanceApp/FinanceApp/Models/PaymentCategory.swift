//
//  PaymentCategory.swift
//  FinanceApp
//
//  Created by Macbook on 15.02.26.
//

import UIKit
 
enum PaymentInputKind {
    case phoneWithPrefix(prefixes: [String])
    case singleLine(placeholder: String, keyboardNumber: Bool)

    var isPrefix: Bool {
        if case .phoneWithPrefix = self { return true }
        return false
    }
}

struct PaymentCategory {
    let id: String
    let name: String
    let systemImageName: String
    let cashbackPercent: Int?
    let inputLabel: String
    let inputKind: PaymentInputKind

    static let all: [PaymentCategory] = [
        PaymentCategory(
            id: "mobile",
            name: "Mobile operators",
            systemImageName: "iphone.and.arrow.forward",
            cashbackPercent: 2,
            inputLabel: "Phone number",
            inputKind: .phoneWithPrefix(prefixes: ["+994 50", "+994 51", "+994 55", "+994 70", "+994 77", "+994 99", "+994 10"])
        ),
        PaymentCategory(
            id: "utilities",
            name: "Utilities",
            systemImageName: "house.fill",
            cashbackPercent: 2,
            inputLabel: "Subscriber ID",
            inputKind: .singleLine(placeholder: "e.g. 12345678", keyboardNumber: true)
        ),
        PaymentCategory(
            id: "bank",
            name: "Bank services",
            systemImageName: "creditcard.fill",
            cashbackPercent: nil,
            inputLabel: "Card or account number",
            inputKind: .singleLine(placeholder: "e.g. 1234 5678 9012 3456", keyboardNumber: true)
        ),
        PaymentCategory(
            id: "transport",
            name: "Transport",
            systemImageName: "bus.fill",
            cashbackPercent: nil,
            inputLabel: "Transport card number",
            inputKind: .singleLine(placeholder: "e.g. BakuCard number", keyboardNumber: true)
        ),
        PaymentCategory(
            id: "fines",
            name: "Fines",
            systemImageName: "doc.badge.gearshape",
            cashbackPercent: nil,
            inputLabel: "Fine number",
            inputKind: .singleLine(placeholder: "e.g. fine reference number", keyboardNumber: true)
        ),
        PaymentCategory(
            id: "internet",
            name: "Internet & TV",
            systemImageName: "wifi",
            cashbackPercent: nil,
            inputLabel: "Account / contract number",
            inputKind: .singleLine(placeholder: "e.g. contract number", keyboardNumber: true)
        ),
        PaymentCategory(
            id: "insurance",
            name: "Insurance",
            systemImageName: "shield.fill",
            cashbackPercent: nil,
            inputLabel: "Policy number",
            inputKind: .singleLine(placeholder: "e.g. policy number", keyboardNumber: true)
        ),
        PaymentCategory(
            id: "other",
            name: "Other payments",
            systemImageName: "square.grid.2x2.fill",
            cashbackPercent: nil,
            inputLabel: "Reference or description",
            inputKind: .singleLine(placeholder: "Optional reference", keyboardNumber: false)
        )
    ]
}

struct PaymentShortcut {
    let id: String
    let name: String
    let subtitle: String?
    let systemImageName: String
    let categoryId: String
}
