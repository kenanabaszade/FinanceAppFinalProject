//
//  SingleTransaction.swift
//  PracticeApp
//
//  Created by Macbook on 08.02.26.
//
 import SwiftUI
struct SingleTransaction : View {
     var transaction : TransactionModel
    
    var body: some View {
        HStack {
            Image(systemName: transaction.image)
                .resizable()
                .frame(width: 40,height: 40)
                
            VStack {
                Text(transaction.title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(transaction.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(transaction.price.currency())")
                .monospacedDigit()
            
                
        }
    }
}
