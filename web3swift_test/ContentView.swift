//
//  ContentView.swift
//  web3swift_test
//
//  Created by Jianrong Fan on 2024/7/30.
//

import SwiftUI
import web3swift
import Web3Core
import BigInt

struct ContentView: View {
    
    @ObservedObject var viewModel = Web3ViewModel()
    @State var gasPrice: BigUInt = 0
    @State var balance: BigUInt = 0
    @State var txHash = ""
    @State var writeContractFunctionTxHash = ""
    @State var readContractFunctionResult: [String: Any] = [:]
    
    var body: some View {
        ScrollView{
            VStack(spacing:20) {
                getPriceNode
                
                balanceNode
                
                signAndSendTxNode
                
                writeToContractFunctionNode
                
                readFromContractFunctionNode
            }
        }
        .padding()
        .task {
            await viewModel.setup()
        }
    }
    
    var getPriceNode: some View {
        Group{
            Button {
                Task{
                    gasPrice = await viewModel.gasPrice()
                }
            } label: {
                Text("Get gas price")
            }
            
            Text("gat price: \(gasPrice)")
        }
    }
    
    var balanceNode: some View {
        Group{
            Button {
                Task{
                    balance = await viewModel.getBalance(adress: self.viewModel.fromAddress)
                }
            } label: {
                Text("Get Balance of Specified Account")
            }
            
            Text("balance: \(String(describing: Double(balance) / pow(10, 18)))")
        }
    }
    
    var signAndSendTxNode: some View {
        Group{
            Button {
                Task{
                    txHash = await viewModel.signAndSendTx(amount: Utilities.parseToBigUInt("0.1", units: .ether)!, toAdress: self.viewModel.toAddress) ?? ""
                }
            } label: {
                Text("Sign & Send Tx")
            }
            
            Text("tx hash: \(txHash)")
        }
    }
    
    var writeToContractFunctionNode: some View {
        Group{
            Button {
                Task{
                    writeContractFunctionTxHash = await viewModel.writeToContractFunction() ?? "Error"
                }
            } label: {
                Text("write To Contract Functions")
            }
            
            Text("result: \(writeContractFunctionTxHash)")
        }
    }
    
    var readFromContractFunctionNode: some View {
        Group{
            Button {
                Task{
                    readContractFunctionResult = await viewModel.readFromContractFunction() ?? [:]
                }
            } label: {
                Text("Read Data from Contract Functions")
            }
            
            Text("result: \(readContractFunctionResult)")
        }
    }
    
    
    
    
}

#Preview {
    ContentView()
}
