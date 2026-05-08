import Foundation
import WidgetKit
import SwiftUI
import WatchKit
import Combine

final class ExtensionDelegate: NSObject, WKApplicationDelegate {
    weak var runtime: ExtendedRuntimeController?

    func handle(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        extendedRuntimeSession.delegate = runtime
        runtime?.resumeFromSystem(with: extendedRuntimeSession)
    }

}


/// アラームの状態
enum SmartAlarmStatus {
    case idle
    case scheduled(Date)                 // 予約中（未来の日時）
    case running(since: Date)            // セッション起動中（発火）
    case expired                         // 満了
    case invalidated(reason: WKExtendedRuntimeSessionInvalidationReason?, error: Error?)
}

final class ExtendedRuntimeController: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {

    // 公開プロパティ
    @Published private(set) var scheduledDate: Date?
    @Published private(set) var status: SmartAlarmStatus = .idle
    
    @AppStorage("isStartingTimer", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var isStartingTimer: Bool = false
    
    @AppStorage("scheduledDateWidet", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var scheduledDateWidet: Date = Date()

    private var session: WKExtendedRuntimeSession?
    private let maxInterval: TimeInterval = 36 * 60 * 60
    private let storageKey = "SmartAlarm.scheduledDate"

    // MARK: - 予約/取得API

    /// 現在のアラーム（予約日時）を返す。running へ移行後は nil。
    var currentAlarmDate: Date? {
        if case .scheduled(let d) = status { return d }
        return scheduledDate
    }

    /// 予約中であれば残り時間（秒）。未予約は nil。
    var remainingTime: TimeInterval? {
        guard let d = currentAlarmDate else { return nil }
        return max(0, d.timeIntervalSinceNow)
    }

    /// 36時間以内の任意の日時にスケジュール
    func scheduleSmartAlarm(at date: Date) {
        let now = Date()
        let maxFuture = now.addingTimeInterval(maxInterval)
        guard date > now, date <= maxFuture else {
            print("SmartAlarm: 日時は現在より未来、かつ36時間以内にしてください。")
            return
        }

        // 既存セッションは終了
        session?.invalidate()
        session = nil

        let s = WKExtendedRuntimeSession()
        s.delegate = self
        session = s
        scheduledDate = date
        status = .scheduled(date)

        // 復元用に保存
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: storageKey)

        // 未来時刻に開始
        s.start(at: date)
        print("SmartAlarm: scheduled at \(date)")
        isStartingTimer = true
        scheduledDateWidet = date
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 予約キャンセル
    func cancelSmartAlarm() {
        session?.invalidate()
        session = nil
        scheduledDate = nil
        status = .idle
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("SmartAlarm: cancelled")
        isStartingTimer = false
        scheduledDateWidet = Date()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 起動時などに復元
    func restoreIfNeeded() {
        guard let ts = UserDefaults.standard.value(forKey: storageKey) as? TimeInterval else {
            status = .idle
            return
        }
        let date = Date(timeIntervalSince1970: ts)
        let now = Date()
        guard date > now, date <= now.addingTimeInterval(maxInterval) else {
            scheduledDate = nil
            status = .idle
            UserDefaults.standard.removeObject(forKey: storageKey)
            print("SmartAlarm: restore skipped (expired or out of range)")
            return
        }

        session?.invalidate()
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        session = s
        scheduledDate = date
        status = .scheduled(date)
        s.start(at: date)
        print("SmartAlarm: restored schedule at \(date)")
    }

    // MARK: - システムからの復帰（WKExtensionDelegate.handle）

    func resumeFromSystem(with incoming: WKExtendedRuntimeSession) {
        self.session = incoming
        self.status = .running(since: Date())
        self.scheduledDate = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        triggerAlarmHaptic()
        print("SmartAlarm: resumed from system")
    }

    // MARK: - WKExtendedRuntimeSessionDelegate

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("SmartAlarm: didStart")
        status = .running(since: Date())
        scheduledDate = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        triggerAlarmHaptic()
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("SmartAlarm: willExpire")
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        print("SmartAlarm: didInvalidate reason=\(reason) error=\(String(describing: error))")
        if case .running = status {
            status = .expired
        } else if case .scheduled = status {
            status = .invalidated(reason: reason, error: error)
        } else {
            status = .invalidated(reason: reason, error: error)
        }
        scheduledDate = nil
        session = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Alarm（選択パターンを使用）

    /// 設定で選ばれたパターンを読み出して鳴らす
    private func triggerAlarmHaptic() {
        // 1) まずカスタムパターン群（JSON保存）を読み出し
        var allPatterns: [CustomNotification] = []
        if let json = UserDefaults.standard.string(forKey: PatternStore.customListKey),
           let decoded = PatternStore.decode(json) {
            allPatterns = decoded
        }
        // 2) 既定パターンも後ろに足す（ID衝突時は先勝ちにしたいので既定は後ろ）
        allPatterns.append(contentsOf: DefaultPatterns.all)

        // 3) 選択中IDを取得（なければ既定の1つを採用）
        let selectedId = UserDefaults.standard.string(forKey: PatternStore.selectedKey)
            ?? DefaultPatterns.notificationAndClick.id

        // 4) 実際に使うパターンを決定
        let pattern = allPatterns.first { $0.id == selectedId } ?? DefaultPatterns.notificationAndClick

        // 5) 再生
        HapticsManager.shared.play(on: session, pattern: pattern)
        
        isStartingTimer = false
        WidgetCenter.shared.reloadAllTimelines()
    }
}


// 利用するハプティクスの種類
enum HapticKind: String, CaseIterable, Codable, Identifiable {
    case notification, click, success, failure, retry, start, stop
    var id: String { rawValue }
    var wkType: WKHapticType {
        switch self {
        case .notification: return .notification
        case .click:        return .click
        case .success:      return .success
        case .failure:      return .failure
        case .retry:        return .retry
        case .start:        return .start
        case .stop:         return .stop
        }
    }
    var label: String {
        switch self {
        case .notification: return "通知"
        case .click:        return "クリック"
        case .success:      return "成功"
        case .failure:      return "失敗"
        case .retry:        return "リトライ"
        case .start:        return "開始"
        case .stop:         return "停止"
        }
    }
}

// パターン1ステップ（次までの待機秒を含む）
struct HapticStep: Codable, Equatable, Identifiable {
    let id: UUID = UUID()
    var type: HapticKind
    var delayToNext: TimeInterval
}

// 振動パターン
struct CustomNotification: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var steps: [HapticStep]
}

// 既定パターン群
enum DefaultPatterns {
    static let notificationAndClick = CustomNotification(
        id: "default.notificationAndClick",
        name: "KEY_DEFAULT",
        steps: [
            HapticStep(type: .notification, delayToNext: 0.4),
            HapticStep(type: .failure,        delayToNext: 0.1),
            HapticStep(type: .failure,        delayToNext: 0.1),
            HapticStep(type: .failure,        delayToNext: 0.1),
        ]
    )

    static let continuousClick = CustomNotification(
        id: "default.continuousClick",
        name: "KEY_WEAK",
        steps: [ HapticStep(type: .click, delayToNext: 0.35) ]
    )

    static let strongThenWeak = CustomNotification(
        id: "default.strongThenWeak",
        name: "KEY_STRESS",
        steps: [
            HapticStep(type: .failure, delayToNext: 0.8),
            HapticStep(type: .click,   delayToNext: 0.2),
            HapticStep(type: .click,   delayToNext: 0.2),
            HapticStep(type: .click,   delayToNext: 0.2)
        ]
    )
    
    static let retry = CustomNotification(
        id: "retry",
        name: "KEY_RETRY",
        steps: [
            HapticStep(type: .retry, delayToNext: 0.2),
            HapticStep(type: .retry,   delayToNext: 0.2),
            HapticStep(type: .retry,   delayToNext: 0.2),
            HapticStep(type: .retry,   delayToNext: 0.2)
        ]
    )
    
    static let stop = CustomNotification(
        id: "stop",
        name: "KEY_STOP",
        steps: [
            HapticStep(type: .stop, delayToNext: 0.2),
            HapticStep(type: .stop,   delayToNext: 0.2),
            HapticStep(type: .stop,   delayToNext: 0.2),
            HapticStep(type: .stop,   delayToNext: 0.2)
        ]
    )
    
    static let rr = CustomNotification(
        id: "rr",
        name: "KEY_MIX",
        steps: [
            HapticStep(type: .success, delayToNext: 0.2),
            HapticStep(type: .click,   delayToNext: 0.2),
            HapticStep(type: .start,   delayToNext: 0.2),
            HapticStep(type: .retry,   delayToNext: 0.2)
        ]
    )

    static let all: [CustomNotification] = [
        notificationAndClick,
        continuousClick,
        strongThenWeak,
        retry,
        stop,
        rr
    ]
}

// UserDefaultsキーとJSONユーティリティ
enum PatternStore {
    static let selectedKey = "selectedHapticPatternId"        // 選択中ID
    static let customListKey = "customHapticPatternsJSON"     // カスタム配列のJSON

    static func encode(_ patterns: [CustomNotification]) -> String? {
        let enc = JSONEncoder()
        return (try? enc.encode(patterns)).flatMap { String(data: $0, encoding: .utf8) }
    }
    static func decode(_ json: String) -> [CustomNotification]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([CustomNotification].self, from: data)
    }
}

/// 選択中パターンに従い、notifyUser(repeatHandler:) でループ再生
final class HapticsManager {
    static let shared = HapticsManager()
    private init() {}

    func play(on session: WKExtendedRuntimeSession?, pattern: CustomNotification) {
        guard let session, !pattern.steps.isEmpty else { return }
        var index = -1
        session.notifyUser(hapticType: .notification) { p in
            index = (index + 1) % pattern.steps.count
            let step = pattern.steps[index]
            p.pointee = step.type.wkType
            return step.delayToNext
        }
    }
}
