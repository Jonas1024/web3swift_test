//
//  ViewModel.swift
//  web3swift_test
//
//  Created by Jianrong Fan on 2024/7/30.
//

import SwiftUI
import web3swift
import Web3Core
import BigInt

class Web3ViewModel: ObservableObject  {
    
    
    let url = "http://127.0.0.1:7545"
    var fromAddress: String = ""
    let toAddress = "0xC0B05B621Ab20123bfC52186708444c783351e69"
    let contractAddressHex = "0x1862e9A6a536074A2C617c49862234b87b7d5ef6"
    
    var web3: Web3!
    
    func setup() async {
        do {
            var tempMnemonics = try? BIP39.generateMnemonics(bitsOfEntropy: 256, language: .english)
            tempMnemonics = "chronic nice lyrics student online garden boy gate anger scene elevator chair"

            let tempWalletAddress = try? BIP32Keystore(mnemonics: tempMnemonics!, password: "", prefixPath: "m/44'/60'/0'/0")
            guard let walletAddress = tempWalletAddress?.addresses?.first else {
                return
            }
            
            self.fromAddress = walletAddress.address
            
            let keystoreManager = KeystoreManager([tempWalletAddress!])
            let httpProvider = try await Web3HttpProvider(url: URL(string: url)!, network: Networks.fromInt(1337), keystoreManager: keystoreManager)
            self.web3 = Web3(provider: httpProvider)
            print(self.web3!)
            
        } catch {
            print(error)
        }
    }
    
    
    func gasPrice() async -> BigUInt {
        do {
            let price = try await self.web3.eth.gasPrice()
            return price
        } catch {
            print(error)
            return BigUInt()
        }
    }
    
    func getBalance(adress: String) async -> BigUInt {
        guard let ethAdress = EthereumAddress(from: adress) else {
            return BigUInt()
        }
        
        do {
            let balance = try await self.web3.eth.getBalance(for: ethAdress)
            return balance
        } catch {
            print(error)
            return BigUInt()
        }
    }
    
    func signAndSendTx(amount: BigUInt, toAdress: String) async -> String? {
        guard EthereumAddress(from: toAdress) != nil else {
            return nil
        }
        
        do {
            let gasPrice = try await self.web3.eth.gasPrice()
            
            var gastx = CodableTransaction(
                type: .eip1559,
                to: EthereumAddress(self.toAddress)!,
                chainID: 1337,
                value: amount
            )
            gastx.from = EthereumAddress(self.fromAddress)!
            let gas =  try await self.web3.eth.estimateGas(for: gastx)
            let nonce = try await self.web3.eth.getTransactionCount(for: EthereumAddress(self.fromAddress)!)
            
            var tx = CodableTransaction(
                type: .eip1559,
                to: EthereumAddress(self.toAddress)!,
                nonce: nonce,
                chainID: 1337,
                value: amount,
                gasLimit: gas,
                maxFeePerGas: Utilities.parseToBigUInt("21", units: .gwei),
                maxPriorityFeePerGas: Utilities.parseToBigUInt("1", units: .gwei),
                gasPrice: gasPrice
            )
            
            try Web3Signer.signTX(transaction: &tx,
                                  keystore: self.web3.provider.attachedKeystoreManager!,
                                  account: EthereumAddress(self.fromAddress)!,
                                  password: "")
            
            let data = tx.encode(for: .transaction)
            let result: TransactionSendingResult = try await self.web3.eth.send(raw: data!)
            print(result)
            return result.transaction.description
        } catch {
            print(error)
            return nil
        }
    }
    
    func writeToContractFunction() async -> String? {
        guard let contractAddress = EthereumAddress(contractAddressHex) else {
            return nil
        }
        do {
            guard let contract = self.web3.contract(abiJson, at: contractAddress) else {
                return nil
            }
            contract.transaction = CodableTransaction(type: .eip1559, to: contractAddress)
            
            let parameters: [Any] = [BigUInt.randomInteger(withMaximumWidth: 200),
                                     BigUInt(0),
                                     BigUInt(2),
                                     true,
                                     BigUInt(1),
                                     Data()]
            let writeOperation = contract.createWriteOperation("transitStateGeneric", parameters: parameters)!
            writeOperation.transaction.from = EthereumAddress(self.fromAddress)!
            
            let result = try await writeOperation.writeToChain(password: "", policies: Policies(gasLimitPolicy: .manual(3000000)), sendRaw: true)
            
            print(result.hash)
            return result.hash
        } catch {
            print(error)
            return nil
        }
    }
    
    func readFromContractFunction() async -> [String: Any]? {
        do {
            guard let contract = self.web3.contract(abiJson, at: EthereumAddress(contractAddressHex)!) else {
                return nil
            }
            contract.transaction = CodableTransaction(type: .eip1559, to: EthereumAddress(contractAddressHex)!)
            
            let method = "getGISTProof"
            let holderDIDBigIntString: BigUInt = BigUInt(stringLiteral: "123")
            let readOperation = contract.createReadOperation(method, parameters: [holderDIDBigIntString])!
            
            readOperation.transaction.from = EthereumAddress(self.fromAddress)!
            let tokenBalanceResponse = try await readOperation.callContractMethod()
            
            print(tokenBalanceResponse)
            return tokenBalanceResponse
        } catch {
            print(error)
            return nil
        }
    }
    
    func convertHexStringToNormalString(hexString:String)->String!{
      if let data = hexString.data(using: .utf8){
          return String.init(data:data, encoding: .utf8)
      }else{ return nil}
    }
}
