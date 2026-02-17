//
//  Shape.swift
//  Timer
//
//  Created by 石野天斗 on 2026/02/10.
//

import SwiftUI

enum TimerShape: String, CaseIterable {
    case circle
    case star
    case heart
    
    var title: LocalizedStringKey {
        switch self {
        case .circle:
            return "KEY_CIRCLE"
        case .star:
            return "KEY_STAR"
        case .heart:
            return "KEY_HEART"
        }
    }
    
    var symbol: String {
        switch self {
        case .circle:
            return "circle.fill"
        case .star:
            return "star.fill"
        case .heart:
            return "heart.fill"
        }
    }
}
