//
//  NewTimerView.swift
//  Timer Watch App
//
//  Created by 石野天斗 on 2026/02/09.
//

import SwiftUI
import Combine

struct TimerModel {
    var hour: Int
    var minutes: Int
    var seconds: Int

    var totalSeconds: Int {
        (hour * 3600) + (minutes * 60) + seconds
    }
}


struct NewTimerView: View {
    @EnvironmentObject var runtime: ExtendedRuntimeController
    @EnvironmentObject var screenSizeStore: ScreenSizeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("timerHistory", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var timerHistoryData = Data()
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .orange
    @State private var isPresentedSettingsView: Bool = false
    @State private var isPresentedTimerView: Bool = false
    @State private var date = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
   
    @State private var DisplayTime: DisplayTimer = DisplayTimer(hour: 0, minutes: 1, seconds: 0)
    
    //タイマー保存
    @AppStorage("timerHour") private var timerHour: Int = 0
    @AppStorage("timerMinutes") private var timerMinutes: Int = 1
    @AppStorage("timerSeconds") private var timerSeconds: Int = 0
    @AppStorage("totalTime") private var totalTime: Int = 0
    
    private var timer: TimerModel {
        get { TimerModel(hour: timerHour, minutes: timerMinutes, seconds: timerSeconds) }
        set {
            timerHour = newValue.hour
            timerMinutes = newValue.minutes
            timerSeconds = newValue.seconds
        }
    }

    private func confirmTimer(_ t: DisplayTimer) -> Bool {
        t.hour == 0 && t.minutes == 0 && t.seconds == 0
    }
    
    private var timerHistory: [Int] {
        if timerHistoryData.isEmpty {
            return []
        }
        if let decoded = try? JSONDecoder().decode([Int].self, from: timerHistoryData) {
            return decoded
        }
        return []
    }

    var body: some View {
        NavigationStack {
                    VStack {
                        // 時・分・秒ピッカー
                        HStack(alignment: .center, spacing: 3) {
                            Picker(selection: $DisplayTime.hour) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text("\(h)")
                                        .tag(h)
                                        .font(.title2)
                                }
                            } label: {
                                Text("KEY_HOURS_LONG")
                                    .foregroundStyle(.green)
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            
                            Text(":")
                                .font(.title2)
                                .offset(y: 6)
                            Picker(selection: $DisplayTime.minutes) {
                                ForEach(0..<60, id: \.self) { m in
                                    Text("\(m)")
                                        .tag(m)
                                        .font(.title2)
                                }
                            } label: {
                                Text("KEY_MINUTES_LONG")
                                    .foregroundStyle(.green)
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            Text(":")
                                .font(.title2)
                                .offset(y: 5)
                            Picker(selection: $DisplayTime.seconds) {
                                ForEach(0..<60, id: \.self) { s in
                                    Text("\(s)")
                                        .tag(s)
                                        .font(.title2)
                                }
                            } label: {
                                Text("KEY_SECONDS_LONG")
                                    .foregroundStyle(.green)
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                        }
                            NavigationLink {
                                TimerView(isPresentedTimerView: $isPresentedTimerView, startDate: .now, totalTime: Double(DisplayTime.totalSeconds), displayTotalTime: Double(DisplayTime.totalSeconds))
                            } label: {
                                Text("KEY_START")
                                    .foregroundStyle(confirmTimer(DisplayTime) ? Color.gray : tintColor.color)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                if !confirmTimer(DisplayTime) {
                                    recordTimerStart(totalSeconds: DisplayTime.totalSeconds)
                                }
                            })
                        .disabled(confirmTimer(DisplayTime))
                    }
                    .frame(height: screenSizeStore.screenHeight * 0.68)
                    .padding(.top)
                    .onAppear {
                        if !isPresentedTimerView {
                            let totalTime: [Int] = loadTimerHistory()
                            let s = totalTime.first
                            let h = (s ?? 60) / 3600
                            let m = ((s ?? 60) % 3600) / 60
                            let sec = (s ?? 60) % 60
                            DisplayTime = DisplayTimer(hour: h, minutes: m, seconds: sec)
                        }
                    }
                    .onChange(of: isPresentedTimerView) { i in
                        if i {
                            dismiss()
                            isPresentedTimerView = false
                          
                        }
                    }
        }
    }
    private func loadTimerHistory() -> [Int] {
        if timerHistoryData.isEmpty { return [] }
        return (try? JSONDecoder().decode([Int].self, from: timerHistoryData)) ?? []
    }

    private func saveTimerHistory(_ arr: [Int]) {
        if let data = try? JSONEncoder().encode(arr) {
            timerHistoryData = data
        }
    }

    // 追加：「開始」時に記録
    private func recordTimerStart(totalSeconds: Int, maxCount: Int = 4) {
        let templateTimer: [Int] = [60, 180, 300, 600, 900]
        var arr = loadTimerHistory()
        
        // TemplateTimerに含まれている場合は記録しない
           guard !templateTimer.contains(totalSeconds) else {
               return
           }
        
        if let i = arr.firstIndex(of: totalSeconds) {
            arr.remove(at: i)  
        }
        
        arr.insert(totalSeconds, at: 0) // 先頭に追加（最新を前へ）
        if arr.count > maxCount {
            arr = Array(arr.prefix(maxCount))
        }
        saveTimerHistory(arr)
    }
    /// 進捗（0.0〜1.0）。ここでは「36時間を最大」とした相対進捗。
    private func progress(remain: TimeInterval) -> Double {
        let max = 36.0 * 3600.0
        let clamped = min(remain, max)
        return 1.0 - (clamped / max)
    }

}

struct DisplayTimer {
    var hour: Int
    var minutes: Int
    var seconds: Int
    
    var totalSeconds: Int {
        (hour * 3600) + (minutes * 60) + seconds
    }
}
