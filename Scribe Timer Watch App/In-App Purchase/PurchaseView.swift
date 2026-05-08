//
//  PurchaseView.swift
//  ScribbleTimer
//
//  Created by 石野天斗 on 2026/02/12.
//

import SwiftUI
import StoreKit

struct IAPView: View {
    @Environment(\.dismiss) private var dismiss
    private let productID = "com.tento.scribe.timer.ScribeTimerPro"
    @State private var loaded = false
    @State private var errorText: String?
    @State private var selectionTip: Int = 0
    @EnvironmentObject var purchaseManager: PurchaseManager

    var body: some View {
        Group {
            if loaded {
                ScrollView {
                    if purchaseManager.isPro {
                            Text("KEY_PURCHASED")
                                .bold()
                                .foregroundStyle(.tint)
                    }

                    ProductView(id: productID)

                    Button("KEY_RESTORATION") {
                        Task {
                            await restore()
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("KEY_INTRODUCTION_FUNCTION")
                            .bold()
                        Image(systemName: "paintpalette.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                        Text("KEY_CAN_CHANGE_COLOR")
                            .fontWeight(.semibold)
                        
                        Image(systemName: "heart.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.pink)
                            .multilineTextAlignment(.center)
                         Text("KEY_CAN_CHANGE_TIMERDESIGHN")
                            .fontWeight(.semibold)
                       
                        Image("apple.haptics")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        Text("KEY_CAN_CHANGE_VIBERATION")
                            .fontWeight(.semibold)
                        
                        Image("widget.smart.stack")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                        Text("KEY_CAN_WIDGET_TIMER")
                            .fontWeight(.semibold)
                        
                        Image(systemName: "hourglass.badge.eye")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                        Text("KEY_CAN_CHANGE_DELAY")
                            .fontWeight(.semibold)
                    }
                }
            } else if let errorText {
                Text("KEY_ERROR_STOREKIT")
                Text(errorText).font(.footnote).opacity(0.7)
            } else {
                ProgressView()
            }
        }
        .onChange(of: purchaseManager.isPro) {
            dismiss()
        }
        .task {
            do {
                let products = try await Product.products(for: [productID])
                if products.isEmpty {
                    errorText = "Product not found: \(productID)"
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
