//
//  Modify.swift
//  Timer
//
//  Created by 石野天斗 on 2026/02/10.
//

import SwiftUI

extension View {
    func modify<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> some View {
        transform(self)
    }
}
