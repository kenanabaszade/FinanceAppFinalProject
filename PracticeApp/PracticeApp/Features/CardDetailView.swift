//
//  CardDetailView.swift
//  PracticeApp
//
//  Created by Macbook on 08.02.26.
//

import SwiftUI

struct CardDetailView : View {
    @State var totalAmount: Double = 3565.86
    @State var cardCode: String = "5282 3456 7890 1289"
    @State var expired: String = "09/25"
    @State var selection: [String] = ["me", "you"]
    @Environment(\.dismiss) var dismiss
    @State var accNumber : String
    @State var currentBalance: Double = 5750.20
    var body: some View {
        NavigationStack {
            VStack {
                VStack (alignment: .leading,spacing: 10){
                    Text("Total balance")
                        .font(.headline)
                        .fontWeight(.regular)
                    Text("Send money")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text("Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.")
                }
                
                
                
                CardView(cardCode: $cardCode, expired: $expired, currentBalance: $currentBalance)
                
                HStack {
                    Text("To")
                    Rectangle().frame(height: 1)
                }
               
                HStack {
                    
                    Text("Account number")
                    
                    TextField("Account number", text: $accNumber)
                               .textFieldStyle(.roundedBorder)
                               .padding()
                   
                }
                
                  HStack {
                    
                      Text("Account number")
                      
                      TextField("Account number", text: $accNumber)
                                 .textFieldStyle(.roundedBorder)
                                 .padding()
                      
                }
                
                  HStack {
                    
                      Text("Account number")
                      
                      SecureField("Password", text: $accNumber)
                                  .textFieldStyle(.roundedBorder)
                                  .padding()
                                    
                }
                
                Button {
                    print("send")
                } label : {
                    Text("Send money")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                        .padding(15)
                        .background(.purple)
                        .clipShape(Capsule())
                }
                
                HStack {
                    VStack (alignment: .leading){
                        Text("Avaible balance")
                            .font(.caption)
                            .fontWeight(.regular)
                        Text("$ 1710.12")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                    }
                    Spacer()
                    Button {
                        print("click")
                    } label : {
                        Text("Add fund")
                            .buttonBorderShape(.circle)
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(.black.opacity(0.1))
                .clipShape(.capsule)
              
                
            }.padding()
            
            
        }.padding()
        .toolbar {
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    print("menu tapped")
                } label: {
                    Image(systemName: "person.circle")
                }
                
            }
        }
        
    }
}

