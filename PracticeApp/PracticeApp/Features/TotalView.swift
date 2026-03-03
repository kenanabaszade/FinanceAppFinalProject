//
//  TotalView.swift
//  PracticeApp
//
//  Created by Macbook on 08.02.26.
//


import SwiftUI

struct TotalView:View {
    @Binding var totalAmount: Double
    var body: some View {
        VStack {
            Text("Total Balance")
            Text("$ \(String(format: "%.2f", totalAmount))")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
}