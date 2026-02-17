//
//  TimeMode.swift
//  Timer
//
//  Created by 石野天斗 on 2026/02/09.
//

import Foundation

enum TimerMode {
    case hours
    case minutes
    case seconds
    
    var title: String {
        switch self {
        case .hours:
            return "H"
        case .minutes:
            return "M"
        case .seconds:
            return "S"
        }
    }
}
