//
//  TimerFormatte.swift
//  Timer
//
//  Created by 石野天斗 on 2026/02/09.
//

import Foundation
import SwiftUI

/// 時間表示用ユーティリティ（どこからでも呼べる静的関数群）
public enum TimeFormatting {

    // MARK: - 「1時間2分3秒」などの日本語ラベル
    /// 例: 3661 → "1時間1分1秒" / 3600 → "1時間" / 65 → "1分5秒" / 8 → "8秒"
    @inlinable
    public static func hmsLabel(from totalSeconds: Int) -> String {
        let s = max(0, totalSeconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60

        switch true {
        case h > 0 && m > 0 && sec > 0:
            return "\(h)\(String(localized: "KEY_HOURS"))"
                 + "\(m)\(String(localized: "KEY_MINUTES"))"
                 + "\(sec)\(String(localized: "KEY_SECONDS"))"

        case h > 0 && m > 0:
            return "\(h)\(String(localized: "KEY_HOURS"))"
                 + "\(m)\(String(localized: "KEY_MINUTES"))"

        case h > 0 && sec > 0:
            return "\(h)\(String(localized: "KEY_HOURS"))"
                 + "\(sec)\(String(localized: "KEY_SECONDS"))"

        case h > 0:
            return "\(h)\(String(localized: "KEY_HOURS"))"

        case m > 0 && sec > 0:
            return "\(m)\(String(localized: "KEY_MINUTES"))"
                 + "\(sec)\(String(localized: "KEY_SECONDS"))"

        case m > 0:
            return "\(m)\(String(localized: "KEY_MINUTES"))"

        default:
            return "\(sec)\(String(localized: "KEY_SECONDS"))"
        }
    }

    /// Double 入力オーバーロード（小数は四捨五入して Int に）
    @inlinable
    public static func hmsLabel(from seconds: Double) -> String {
        hmsLabel(from: Int(seconds.rounded()))
    }

    // MARK: - 「1:05:09」などの時計型
    /// 例: 3661 → "1:01:01",  610 → "10:10",  8 → "0:08"
    @inlinable
    public static func clock(from totalSeconds: Int, alwaysHMS: Bool = false) -> String {
        let s = max(0, totalSeconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60

        if alwaysHMS || h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        } else if m > 0 {
            return String(format: "%d:%02d", m, sec)
        } else {
            return String(format: "0:%02d", sec)
        }
    }

    /// Double 入力オーバーロード
    @inlinable
    public static func clock(from seconds: Double, alwaysHMS: Bool = false) -> String {
        clock(from: Int(seconds.rounded()), alwaysHMS: alwaysHMS)
    }

    // MARK: - システムローカライズ（必要に応じて）
    /// DateComponentsFormatter を使ったローカライズ版（例: "1 hr, 2 min, 3 sec" など）
    /// 日本語ロケールなら "1時間2分3秒" になりますが、細かな省略ルールは OS に準拠します。
    public static func localizedAbbreviated(from totalSeconds: Int,
                                            allowedUnits: NSCalendar.Unit = [.hour, .minute, .second],
                                            locale: Locale = .current) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full          // .abbreviated などに変更可
        formatter.allowedUnits = allowedUnits
        formatter.zeroFormattingBehavior = [.dropAll]
        formatter.collapsesLargestUnit = false
        formatter.maximumUnitCount = 3
        formatter.calendar?.locale = locale

        let s = max(0, totalSeconds)
        return formatter.string(from: TimeInterval(s)) ?? hmsLabel(from: s)
    }
}
