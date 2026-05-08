//
//  PurchaseManager.swift
//  Scribe Timer Watch App
//
//  Created by 石野天斗 on 2026/02/16.
//

import StoreKit
import Combine
import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {
    @AppStorage("ScribeTimerPro", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var isScribeTimerPro: Bool = false
    @Published var isPro: Bool = false
    
    private let productID = "com.tento.scribe.timer.ScribeTimerPro"
    
    init() {
        Task {
            await checkPurchased()
            await observeTransactions()
        }
    }
    
    // 起動時チェック
    func checkPurchased() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                isPro = true
                isScribeTimerPro = true
                return
            }
        }
        isPro = false
        isScribeTimerPro = false
    }
    
    func observeTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                
                isPro = true
                isScribeTimerPro = true
                
                await transaction.finish()
            }
        }
    }
}

