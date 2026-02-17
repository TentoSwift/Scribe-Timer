//
//  LocalizedString.swift
//  Timer
//
//  Created by 石野天斗 on 2026/02/10.
//

import SwiftUI

enum TimeUnitMode: String, CaseIterable, Hashable {
    case hours
    case minutes
    case seconds
    
    var title: LocalizedStringResource {
        switch self {
        case .hours: return "KEY_HOURS"
        case .minutes: return "KEY_MINUTES"
        case .seconds: return "KEY_SECONDS"
        }
    }
    
    var rank: Int {
        switch self {
        case .hours:
            return 0
        case .minutes:
            return 1
        case .seconds:
            return 2
        }
    }
}

