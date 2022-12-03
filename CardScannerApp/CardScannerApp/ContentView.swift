//
//  ContentView.swift
//  CardScannerApp
//
//  Created by Michal Ziobro on 03/12/2022.
//

import SwiftUI
import CardScanner

struct ContentView: View {

    @State private var cardNumber = "?"
    @State private var holder = "?"
    @State private var expiryDate = "?"

    @State private var showCardScanner = false

    var body: some View {
        VStack {
            Text("Card number: ")
            Text(cardNumber)


            Text("Expiry date: ").padding(.top, 8)
            Text(expiryDate)


            Text("Card holder: ").padding(.top, 8)
            Text(holder)


            Button("Scan Card") {
                showCardScanner = true
            }
            .padding(.top, 20)
        }
        .padding()
        .sheet(isPresented: $showCardScanner) {
            cardScannerView
        }
    }

    private var cardScannerView: some View {
        CardScanner(firstNameSuggestion: "Tim", lastNameSuggestion: "Cook") { cardNumber, expiryDate, holder in
            self.cardNumber = cardNumber ?? "not found"
            self.holder = holder ?? "not found"
            self.expiryDate = expiryDate ?? "not found"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
