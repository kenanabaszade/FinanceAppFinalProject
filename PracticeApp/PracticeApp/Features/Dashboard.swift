import SwiftUI

struct Dashboard: View {
    @State var totalAmount: Double = 3565.86
    @State var cardCode: String = "5282 3456 7890 1289"
    @State var expired: String = "09/25"
    @State var selection: [String] = ["me", "you"]
    
    @State var currentBalance: Double = 5750.20
    @State var accNumber: String = "5750.20"
    
    @State var transaction : [TransactionModel] = [
        TransactionModel(image: "gear", title: "abb", subtitle: "food", price: 10.0),
        TransactionModel(image: "person", title: "kapital", subtitle: "electronic", price: 32.0),
        TransactionModel(image: "star", title: "abb", subtitle: "product", price: 23.0),
        TransactionModel(image: "gear", title: "abb", subtitle: "food", price: 40.0),
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                TotalView(totalAmount: $totalAmount)
                
                NavigationLink(destination: {
                    CardDetailView(accNumber:accNumber)
                }, label: {
                    CardView(cardCode: $cardCode, expired: $expired, currentBalance: $currentBalance)
                })
                
               
                
                Picker()
                 
                List(transaction) { item in
                    NavigationLink {
                        Text("detail")
                    } label: {
                        SingleTransaction(transaction: item)
                    }
                }
                .ignoresSafeArea(.container,edges: .bottom)
            }.toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        print("menu tapped")
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
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
}
 
