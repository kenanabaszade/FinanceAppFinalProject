//
//  Double.swift
//  PracticeApp
//
//  Created by Macbook on 08.02.26.
//
import Foundation
extension Double {
    func currency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? String(format:"$%0.2f", self)
    }
}
