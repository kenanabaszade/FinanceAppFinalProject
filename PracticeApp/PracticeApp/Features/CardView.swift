//
//  CardView.swift
//  PracticeApp
//
//  Created by Macbook on 08.02.26.
//


import SwiftUI

struct CardView:View {
    @Binding var cardCode: String
    @Binding var expired: String
    @Binding var currentBalance: Double
    var body: some View {
        ZStack {
            Image("cardimg")
                .overlay {
                    VStack{
                        HStack(alignment:.top){
                            VStack(alignment:.leading) {
                                Text("Current Balance")
                                    .foregroundStyle(Color.white.opacity(0.7))
                                Text("$ \(String(format: "%.2f", currentBalance))")
                                    .foregroundStyle(Color.white)
                                    .font(.largeTitle)
                            }
                            .padding()

                            Spacer()
                            Image(.mastercardLogo)
                        }
                        Spacer()
                        HStack {
                            Text(cardCode)
                                .foregroundStyle(Color.white)
                            Spacer()
                            Text(expired)
                                .foregroundStyle(Color.white)
                        }
                        .padding()
                    }
                    .padding(20)
                        
                }
        }
    }
}
