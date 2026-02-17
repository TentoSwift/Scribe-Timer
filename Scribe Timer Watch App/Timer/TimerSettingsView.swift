//
//  TimerSettingsView.swift
//  Timer Watch App
//
//  Created by 石野天斗 on 2026/02/09.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    // 現在選択中のパターンID
    @AppStorage(PatternStore.selectedKey) private var selectedPatternId: String = DefaultPatterns.notificationAndClick.id
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .blue
    
    @AppStorage("timerShape", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var timerShape: TimerShape = .circle
    @AppStorage("inputDelay", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var inputDelay: Double = 0.4
    // パターン一覧（AppStorageにJSONで保存しても良いですが、まずは固定配列＋カスタム一時追加にしています）
    @State private var patterns: [CustomNotification]
    
    // セッションを使って試しに鳴らす場合は、外側から渡す or @EnvironmentObject などに置き換えてください
    var runtimeSession: WKExtendedRuntimeSession?
    
    init(initialPatterns: [CustomNotification] = DefaultPatterns.all, runtimeSession: WKExtendedRuntimeSession? = nil) {
        _patterns = State(initialValue: initialPatterns)
        self.runtimeSession = runtimeSession
    }
    
    private var isPro: Bool {
        purchaseManager.isPro
    }
    
    private let layout: [GridItem] = Array(repeating: .init(.flexible(minimum: 2, maximum: 2)), count: 2)
    
    var body: some View {
        List {
            NavigationLink("Scribe Timer Pro") {
                IAPView()
            }
            .bold()
            NavigationLink {
                HStack {
                    Text(inputDelay, format: .number.precision(.fractionLength(0...2)))
                    Text(LocalizedStringKey("KEY_SECONDS"))
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .font(.largeTitle)
                .bold()
                Stepper("", value: $inputDelay, in: 0.1...1, step: 0.1)
                    .buttonStyle(.plain)
                    .navigationTitle {
                        Text("KEY_INPUTDELAY")
                            .foregroundStyle(tintColor.color)
                    }
            } label: {
                settingButtonLabel(title: "KEY_INPUTDELAY", image: "hourglass.badge.eye", color: .orange, isImage: false)
            }
            NavigationLink {
                List {
                    Section {
                        ForEach(patterns) { item in
                            let isBool = selectedPatternId == item.id
                            Button {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        selectedPatternId = item.id
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                    }
                                    Spacer()
                                    Image(systemName: isBool ? "checkmark.circle.fill" : "circle.fill")
                                        .contentTransition(.symbolEffect(.replace))
                                        .foregroundStyle(tintColor.color.opacity(isBool ? 1.0 : 0))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
                .disabled(!isPro)
                .navigationTitle{
                    Text("KEY_VIBRATION")
                        .foregroundStyle(tintColor.color)
                }
            } label: {
                settingButtonLabel(title: "KEY_ALARM_VIBRATION", image: "apple.haptics", color: .red, isImage: true)
            }
            
            NavigationLink {
                List {
                    Section {
                        ForEach(TimerShape.allCases, id: \.self) { shape in
                            Button {
                                withAnimation {
                                    timerShape = shape
                                }
                            } label: {
                                HStack {
                                    Image(systemName: shape.symbol)
                                    Text(shape.title)
                                    Spacer()
                                    Image(systemName: shape == timerShape ? "checkmark.circle.fill" : "circle.fill")
                                        .contentTransition(.symbolEffect(.replace))
                                        .foregroundStyle(tintColor.color.opacity(shape == timerShape ? 1.0 : 0))
                                }
                            }
                        }
                    }
                }
                .disabled(!isPro)
                .navigationTitle {
                    Text("KEY_DESIGHN")
                        .foregroundStyle(tintColor.color)
                }
            } label: {
                    settingButtonLabel(title: "KEY_TIMERSHAPE", image: timerShape.symbol, color: .green, isImage: false)
            }
            
            NavigationLink {
                List {
                    Section {
                        ForEach(TintColor.allCases, id: \.self) { colorCase in
                            Button {
                                withAnimation {
                                    tintColor = colorCase
                                }
                            } label: {
                                Label(colorCase.title, systemImage: colorCase == tintColor ? "checkmark.circle.fill" : "circle.fill")
                                    .foregroundColor(colorCase.color)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                    }
                    .padding()
                }
                .disabled(!isPro)
                .navigationTitle {
                    Text("KEY_COLOR")
                        .foregroundStyle(.tint)
                }
            } label: {
                settingButtonLabel(title: "KEY_PRIMARYCOLOR", image: "", color: tintColor.color, isImage: false)
            }
            
        }
        .navigationTitle {
            Text("KEY_SETTINGS")
                .foregroundStyle(.tint)
        }
    }
    
}

@ViewBuilder
private func settingButtonLabel(title: String, image: String, color: Color, isImage: Bool) -> some View {
    let iconSize: CGFloat = 13
    let containerSize: CGFloat = 18
    
    HStack {
        Group {
            if isImage {
                Image(image)
                    .resizable()
                    .bold()
                    .scaledToFit()
            } else {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: iconSize, height: iconSize)
        .frame(width: containerSize, height: containerSize)
        .background(
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            color.mix(with: .white, by: 0.3),
                            color
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        Text(LocalizedStringKey(title))
        Spacer()
    }
}
