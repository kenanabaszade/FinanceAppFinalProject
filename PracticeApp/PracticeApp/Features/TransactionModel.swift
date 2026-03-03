//
//  TransactionModel.swift
//  PracticeApp
//
//  Created by Macbook on 08.02.26.
//
import Foundation
struct TransactionModel : Identifiable{
    var id: UUID = UUID()
    
    let image : String
    let title : String
    let subtitle: String
    let price : Double
}
