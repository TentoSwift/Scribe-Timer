//
//  SelectedTimerView.swift
//  Timer Watch App
//
//  Created by 石野天斗 on 2026/02/09.
//

import SwiftUI

struct SelectedTimerView: View {
    @EnvironmentObject var screenSizeStore: ScreenSizeStore
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .orange
    @AppStorage("timerHistory", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var timerHistoryData: Data = Data()
    @State private var isEdit: Bool = false
    @State private var isPresentedTimerView: Bool = false

    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    // 読み取り専用の履歴（初回のみデフォルトを返す）
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
            ScrollView(.vertical) {
                let buttonSize: Double = screenSizeStore.screenWidth * 0.45
                LazyVGrid(columns: columns) {
                    
                    // 新規作成
                    NavigationLink {
                        NewTimerView()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.black.mix(with: .white, by: 0.2))
                                .frame(width: buttonSize, height: buttonSize)
                            Image(systemName: "plus")
                                .font(.system(size: buttonSize * 0.4, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isEdit)
                    
                    let templateTimer: [Int] = [60, 180, 300, 600, 900]
                    ForEach(templateTimer, id: \.self) { item in
                        VStack {
                            NavigationLink {
                                TimerView(
                                    isPresentedTimerView: $isPresentedTimerView,
                                    startDate: .now,
                                    totalTime: Double(item),
                                    displayTotalTime: Double(item)
                                )
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.black.mix(with: .white, by: 0.2))
                                        .frame(width: buttonSize, height: buttonSize)
                                    Circle()
                                        .stroke(lineWidth: 2)
                                        .foregroundStyle(tintColor.color.mix(with: .white, by: 0.1))
                                        .frame(width: buttonSize * 0.9, height: buttonSize * 0.9)
                                    VStack(spacing: 0) {
                                        Text(formatTime(item))
                                            .font(.system(size: dynamicFontSize(for: formatTime(item), buttonSize: buttonSize), weight: .semibold))
                                            .offset(y: 5)
                                            .foregroundStyle(.white)
                                        Text(largestUnitLabel(from: item))
                                            .font(.system(size: buttonSize * 0.2))
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isEdit) // 編集中は誤タップ防止
                        }
                    }
                    // 履歴ボタン群（インデックスで安定識別）
                    ForEach(Array(timerHistory.sorted().enumerated()), id: \.offset) { index, item in
                        VStack {
                            NavigationLink {
                                TimerView(
                                    isPresentedTimerView: $isPresentedTimerView,
                                    startDate: .now,
                                    totalTime: Double(item),
                                    displayTotalTime: Double(item)
                                )
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.black.mix(with: .white, by: 0.2))
                                        .frame(width: buttonSize, height: buttonSize)
                                    Circle()
                                        .stroke(lineWidth: 2)
                                        .foregroundStyle(tintColor.color.mix(with: .white, by: 0.1))
                                        .frame(width: buttonSize * 0.9, height: buttonSize * 0.9)
                                    VStack(spacing: 0) {
                                        Text(formatTime(item))
                                            .font(.system(
                                                size: dynamicFontSize(
                                                    for: formatTime(item),
                                                    buttonSize: buttonSize
                                                ),
                                                weight: .semibold
                                            ))
                                            .foregroundStyle(.white)
                                            .offset(y: 5)
                                        Text(largestUnitLabel(from: item))
                                            .font(.system(size: buttonSize * 0.2))
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isEdit) // 編集中は誤タップ防止
                        }
                        // 左上の「−」ボタン（編集時のみ）
                        .overlay(alignment: .topLeading) {
                            if isEdit {
                                Button(role: .destructive) {
                                    withAnimation {
                                        removeHistory(value: item)
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: buttonSize * 0.2, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background { Circle().fill(Color.red) }
                                }
                                .buttonStyle(.plain)
                                .zIndex(1)
                                .allowsHitTesting(true)
                            }
                        }
                    }
                }
                .animation(.snappy(duration: 0.28), value: timerHistoryData)
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            isEdit.toggle()
                        }
                    } label: {
                        Text(isEdit ? "KEY_DONE" : "KEY_EDDIT")
                            .font(.system(size: screenSizeStore.screenWidth * 0.1,
                                          weight: isEdit ? .semibold : .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, screenSizeStore.screenWidth * 0.25)
                            .padding(.vertical, screenSizeStore.screenWidth * 0.04)
                    }
                    .buttonStyle(.plain)
                    .modify { view in
                            if #available(watchOS 26.0, *) {
                                view.glassEffect()
                            } else {
                                view
                            }
                        }
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle {
                Text("KEY_TIMER")
                    .foregroundStyle(tintColor.color)
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        // 時のみ
        if hours > 0 && minutes == 0 && secs == 0 {
            return "\(hours)"
        }

        // 時と分のみ
        if hours > 0 && minutes > 0 && secs == 0 {
            return String(format: "%d:%02d", hours, minutes)
        }

        // 時を含む（秒がある場合は h:mm:ss）
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        // 分のみ
        if hours == 0 && minutes > 0 && secs == 0 {
            return "\(minutes)"
        }

        // 分と秒
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }

        // 秒のみ
        return "\(secs)"
    }
    
    // MARK: - 書き込み系ヘルパ（nonmutatingでOK）
    private func writeHistory(_ list: [Int]) {
        if let encoded = try? JSONEncoder().encode(list) {
            timerHistoryData = encoded
        } else {
            timerHistoryData = Data()
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
    private func removeHistory(value: Int) {
        var arr = loadTimerHistory()
        if let idx = arr.firstIndex(of: value) {
            arr.remove(at: idx)
            saveTimerHistory(arr)
        }
    }
}


private func largestUnitLabel(from seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60

    if hours > 0 {
        return String(localized: "KEY_HOURS")
    }
    if minutes > 0 {
        return String(localized: "KEY_MINUTES")
    }
    return String(localized: "KEY_SECONDS")
}

    private func dynamicFontSize(for text: String, buttonSize: Double) -> CGFloat {
        let base = buttonSize * 0.3
        let count = text.count

        switch count {
        case 1...2:
            return base * 1.1
        case 3...5:
            return base * 1.1
        case 6...9:
            return base * 0.7
        default:
            return base * 0.7
        }
    }
