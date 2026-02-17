//
//  ScreenSizeStore.swift
//  Timer
//
//  Created by 石野天斗 on 2026/02/09.
//

import SwiftUI
import Combine

final class ScreenSizeStore: ObservableObject {
    @Published var screenWidth: CGFloat = 0
    @Published var screenHeight: CGFloat = 0

    init() { updateSize() }

    func updateSize() {
        let screenBounds = WKInterfaceDevice.current().screenBounds
        self.screenWidth = screenBounds.width
        self.screenHeight = screenBounds.height
    }
}
