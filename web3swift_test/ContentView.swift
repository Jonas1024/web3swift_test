//
//  ContentView.swift
//  web3swift_test
//
//  Created by Jianrong Fan on 2024/7/30.
//

import SwiftUI
import web3swift
import Web3Core

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .task {
            do {
                let web3 = try await Web3HttpProvider(url: URL(string: "http://127.0.0.1:7545")!, network: nil)
                print(web3)
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
