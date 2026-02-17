//
//  Scribe_TimerApp.swift
//  Scribe Timer Watch App
//
//  Created by 石野天斗 on 2026/02/15.
//

import SwiftUI
import WidgetKit
import Combine

@main
struct ScribbleTimer_Watch_AppApp: App {
    @StateObject private var screenSizeStore = ScreenSizeStore()
    @WKApplicationDelegateAdaptor(ExtensionDelegate.self) var appDelegate
    @StateObject private var runtime = ExtendedRuntimeController()
    @StateObject private var purchaseManager = PurchaseManager()
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .blue
    
    @AppStorage("isStartingTimer", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var isStartingTimer: Bool = false
    
    @AppStorage("scheduledDateWidet", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var scheduledDateWidet: Date = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .environmentObject(screenSizeStore)
                .environmentObject(runtime)
                .tint(tintColor.color)
                .task {
                    runtime.restoreIfNeeded()
                }
                .onChange(of: tintColor) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}
