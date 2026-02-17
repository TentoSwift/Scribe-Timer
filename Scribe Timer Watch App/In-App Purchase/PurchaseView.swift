//
//  PurchaseView.swift
//  ScribbleTimer
//
//  Created by 石野天斗 on 2026/02/12.
//

import SwiftUI
import StoreKit

struct IAPView: View {
    private let productID = "com.tento.scribe.timer_scribetimerpro"
    @State private var loaded = false
    @State private var errorText: String?
    @State private var selectionTip: Int = 0
    @EnvironmentObject var purchaseManager: PurchaseManager

    var body: some View {
        Group {
            if loaded {
                ScrollView {
                    HStack {
                        Image(systemName: "heart")
                            .foregroundStyle(.red)
                        Image(systemName: "star")
                            .foregroundStyle(.yellow)
                        Image("apple.haptics")
                    }
                    .font(.headline)
                    .bold()

                    ProductView(id: productID)

                    Button("KEY_RESTORATION") {
                        Task {
                            await restore()
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                    .buttonStyle(.plain)
                }
            } else if let errorText {
                Text("KEY_ERROR_STOREKIT")
                Text(errorText).font(.footnote).opacity(0.7)
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                let products = try await Product.products(for: [productID])
                if products.isEmpty {
                    errorText = "error"
                } else {
                    loaded = true
                }
            } catch {
                errorText = error.localizedDescription
            }
        }
    }

    private func restore() async {
        do {
            try await AppStore.sync()
            await purchaseManager.checkPurchased()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
