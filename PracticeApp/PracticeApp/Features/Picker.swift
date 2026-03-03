//
//  Picker.swift
//  PracticeApp
//
//  Created by Macbook on 08.02.26.
//
import SwiftUI
struct Picker : View {
    var body: some View {
        HStack{
            Text("Debit")
                .padding()
                .font(Font.headline)
                .background(.white)
                .clipShape(Capsule()) 
            Text("Credit")
                .padding()
                .foregroundStyle(.white)
        }.padding()
        
        .frame(width: .infinity,height: 60)
        
        .background(.purple)
        
        .clipShape(Capsule())
        
        .padding()
         
    }
}
