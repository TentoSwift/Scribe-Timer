//
//  TimerView.swift
//  Timer
//

import SwiftUI
import Combine

struct TimerView: View {
    @EnvironmentObject var runtime: ExtendedRuntimeController
    @EnvironmentObject var screenSizeStore: ScreenSizeStore
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .orange
    
    @AppStorage("timerShape", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var timerShape: TimerShape = .circle
    
    @State private var isRunningTimer: Bool = true
    @State private var isPossible: Bool = true
    @State private var isPaused2: Bool = false
    
    @State private var remainingTime: Double = 0.0
    @State private var proportion: Double = 0.0
    @Binding var isPresentedTimerView: Bool
     
    let startDate: Date
    let totalTime: Double
    let displayTotalTime: Double
    private let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
    
    private var hasHours: CGFloat {
        if remainingTime >= 60 * 60 * 10 {
            return 0.13
        } else if remainingTime >= 60 * 60 {
            return 0.15
        } else {
            return 0.2
        }
    }
    
    private func totalTimeSize(total: Int) -> CGFloat {
        let hours = total / (60 * 60)
        let minutes = (total % (60 * 60)) / 60
        let seconds = total % 60

        let hasHours = hours > 0
        let hasMinutes = minutes > 0
        let hasSeconds = seconds > 0

        let hoursTwoDigits = hours >= 10
        let minutesTwoDigits = minutes >= 10
        let secondsTwoDigits = seconds >= 10

        // 時間・分・秒がすべてある
        if hasHours && hasMinutes && hasSeconds {
            return 0.06
        }
        // 組み合わせが2つある（時間+分／時間+秒／分+秒）
        else if (hasHours && hasMinutes) || (hasHours && hasSeconds) || (hasMinutes && hasSeconds) {
            // どれかが二桁
            let anyTwoDigits = hoursTwoDigits || minutesTwoDigits || secondsTwoDigits
            // 両方とも二桁（存在する2つの単位について判定）
            let bothTwoDigits: Bool = {
                if hasHours && hasMinutes { return hoursTwoDigits && minutesTwoDigits }
                if hasHours && hasSeconds { return hoursTwoDigits && secondsTwoDigits }
                if hasMinutes && hasSeconds { return minutesTwoDigits && secondsTwoDigits }
                return false
            }()

            if bothTwoDigits {
                return 0.09
            } else if anyTwoDigits {
                return 0.1
            } else {
                return 0.08
            }
        }
        // 秒だけ
        else if hasSeconds && !hasHours && !hasMinutes {
            return 0.16
        }
        // 上記以外（時間だけ／分だけ）
        else {
            return 0.13
        }
    }
    
    private var safeProportion: Double {
        guard displayTotalTime > 0 else { return 0 }
        let p = remainingTime / displayTotalTime
        return min(max(p, 0), 1)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                let ringSize = screenSizeStore.screenWidth * 0.82
                
                switch runtime.status {
                    
                case .scheduled(let date):
                    // date は「鳴動予定のターゲット時刻」
                    switch timerShape {
                    case .circle:
                        CountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2,proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .star:
                        StarCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2,proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .heart:
                        HeartCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2,proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    }
                case .running:
                    switch timerShape {
                    case .circle:
                        CountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: false, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .star:
                        StarCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: false, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .heart:
                        HeartCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: false, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    }
                case .expired:
                    switch timerShape {
                    case .circle:
                        CountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .star:
                        StarCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .heart:
                        HeartCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    }
                case .invalidated:
                    switch timerShape {
                    case .circle:
                        CountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .star:
                        StarCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .heart:
                        HeartCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    }
                case .idle:
                    switch timerShape {
                    case .circle:
                        CountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .star:
                        StarCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    case .heart:
                        HeartCountDownView(totalTime: Int(totalTime), remainingTime: remainingTime, isRunning: true, isPaused: isPaused2, proportion: proportion, size: ringSize, isLuminanceReduced: isLuminanceReduced)
                            .padding(.bottom)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .containerBackground(uiState == .running ? tintColor.color.mix(with: Color.white, by: 0.02) : Color.clear, for: .navigation)
            .onAppear {
                screenSizeStore.updateSize()
                let target = Date().addingTimeInterval(TimeInterval(totalTime))
                runtime.scheduleSmartAlarm(at: target)

                remainingTime = max(0, runtime.remainingTime ?? 0)
                proportion = safeProportion
            }
            .onDisappear {
                timer.upstream.connect().cancel()
                runtime.cancelSmartAlarm()
                isPresentedTimerView = true
            }
            .onReceive(timer) { _ in
                if (movement == "停止") {
                    remainingTime = max(0, runtime.remainingTime ?? 0)
                    withAnimation {
                        proportion = safeProportion
                    }
                }
                if uiState == .expired {
                    remainingTime = 0
                    isPossible = false
                    if scenePhase == .active {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                            if movement == "再度" {
                                dismiss()
                                runtime.cancelSmartAlarm()
                                timer.upstream.connect().cancel()
                            }
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { _ in
                if uiState == .expired {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                        if movement == "再度" {
                            dismiss()
                            runtime.cancelSmartAlarm()
                            timer.upstream.connect().cancel()
                        }
                    }
                }
            }
            .onDisappear {
                isPresentedTimerView.toggle()
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack {
                            Button {
                                runtime.cancelSmartAlarm()
                                timer.upstream.connect().cancel()
                                DispatchQueue.main.async {
                                    dismiss()
                                    runtime.cancelSmartAlarm()
                                }
                            } label: {
                                Label("KEY_CANCEL", systemImage: "xmark")
                                    .foregroundStyle(uiState == .running ? .black : .white)
                            }
                            .tint(.white.opacity(uiState == .running ? 0.8 : 0))
                            .modify { view in
                                if movement == "再度" {
                                    view
                                        .handGestureShortcut(.primaryAction)
                                        .accessibilityQuickAction(style: .outline) {
                                            Button {
                                                runtime.cancelSmartAlarm()
                                                timer.upstream.connect().cancel()
                                                DispatchQueue.main.async {
                                                    dismiss()
                                                    runtime.cancelSmartAlarm()
                                                }
                                            } label: {
                                                Label("KEY_CANCEL", systemImage: "xmark")
                                            }
                                        }
                                } else {
                                    view
                                }
                            }
                        Spacer()
                        if isPossible {
                            Button {
                                switch movement {
                                case "停止":
                                    pause()
                                    isPaused2 = true
                                case "再開":
                                    restart()
                                    isPaused2 = false
                                case "再度":
                                    again()
                                    isPaused2 = false
                                default:
                                    pause()
                                    isPaused2 = true
                                }
                            } label: {
                                Image(systemName: symbol)
                                    .foregroundStyle(disableToggle ||
                                                     (remainingTime < 1 && (movement == "停止" || movement == "再開")) ? .gray.opacity(0.5) : .black)
                            }
                            .tint(disableToggle ||
                                  (remainingTime < 1 && (movement == "停止" || movement == "再開")) ? .clear : (movement == "再度" ? Color.white.opacity(0.8) : tintColor.color))
                            .disabled(
                                disableToggle ||
                                (remainingTime < 1 && (movement == "停止" || movement == "再開"))
                            )
                        }
                    }
                }
                
                
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }
    
    private enum UIState {
        case running      // 実行中（ExtendedRuntime が走っている）
        case paused       // 一時停止（remainingTime を保持している）
        case expired      // 期限切れ
        case idle         // それ以外（未設定など）
    }
    
    private var uiState: UIState {
        if case .running = runtime.status { return .running }
        if case .expired = runtime.status { return .expired }
        // 一時停止は runtime 側は idle/invalidated でも、remainingTime>0 のときに判断
        if remainingTime > 0 { return .paused }
        return .idle
    }
    
    private var movement: String {
        if case .running = uiState { return "再度" }
        // 一時停止は runtime 側は idle/invalidated でも、remainingTime>0 のときに判断
        if remainingTime > 0 && !isRunningTimer { return "再開"}
        if case .expired = uiState { return "再度" }
        return "停止"
    }
    
    private var symbol: String {
        if case .running = uiState { return "arrow.counterclockwise" }
        if case .expired = uiState { return "arrow.counterclockwise" }
        // 一時停止は runtime 側は idle/invalidated でも、remainingTime>0 のときに判断
        if remainingTime > 0 && !isRunningTimer { return "play.fill" }
        return "pause.fill"
    }
    
    private var currentTargetDate: Date? {
        if let d = runtime.scheduledDate { return d }
        switch runtime.status {
        case .scheduled(let d): return d
        case .running: return runtime.scheduledDate   // ExtendedRuntimeController が保持している前提
        default: return startDate
        }
    }
    
    private var canCancel: Bool {
        switch runtime.status {
        case .scheduled, .running: return true
        default: return false
        }
    }
    
    private var disableToggle: Bool {
        switch runtime.status {
        case .invalidated: return true
        default: return false
        }
    }
    // MARK: - View
    @ViewBuilder
    func CountDownView(totalTime: Int, remainingTime: Double, isRunning: Bool, isPaused: Bool, proportion: Double, size: CGFloat, isLuminanceReduced: Bool) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Text(isRunning ? TimeFormatting.clock(from: Int(0)) : String(localized: "KEY_END"))
                    .font(.system(size: size * 0.24))
                    .foregroundStyle(.clear)
                    .monospacedDigit()
                    .padding(.bottom)
                Text(TimeFormatting.hmsLabel(from: Int(displayTotalTime)))
                    .font(.system(size: size * 0.11, weight: .semibold))
                    .foregroundStyle(isRunning ? tintColor.color.mix(with: .white, by: 0.05).opacity(isPaused ? 0.5 : 1.0) : .black)
                    .monospacedDigit()
            }
            VStack(spacing: 0) {
                Text(isRunning ? TimeFormatting.clock(from: Int(remainingTime)) : String(localized: "KEY_END"))
                    .font(.system(size: size * 0.24))
                    .foregroundStyle(isRunning ? (isPaused ? Color.gray : Color.white) : Color.black)
                    .monospacedDigit()
                    .padding(.bottom)
            }
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color(isRunning ? .gray.opacity(0.2) : tintColor.color.mix(with: .black, by: 0.15)), lineWidth: size * 0.035)
                        .frame(width: size, height: size)
                    Circle()
                        .trim(from: 0.0, to: min(proportion + 0.004, 1.0))
                        .stroke(Color.black.opacity(isRunning && !isLuminanceReduced && proportion != 0 ? 0.4 : 0), style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
                        .frame(width: size, height: size)
                        .rotationEffect(Angle(degrees: 270.0))
                    Circle()
                        .trim(from: 0.0, to: min(proportion, 1.0))
                        .stroke(tintColor.color.mix(with: .white, by: 0.1).opacity(!isLuminanceReduced && isRunning ? 1.0 : 0), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: size, height: size)
                        .rotationEffect(Angle(degrees: 270.0))
                }
            }
        }
    }
    
    // StarTimerView
    @ViewBuilder
    func StarCountDownView(totalTime: Int, remainingTime: Double, isRunning: Bool, isPaused: Bool, proportion: Double, size: CGFloat, isLuminanceReduced: Bool) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Text(isRunning ? TimeFormatting.clock(from: Int(0)) : String(localized: "KEY_END"))
                    .font(.system(size: size * hasHours))
                    .foregroundStyle(.clear)
                    .monospacedDigit()
                    .padding(.bottom)
                    .bold()
                Text(TimeFormatting.hmsLabel(from: Int(displayTotalTime)))
                    .font(.system(size: size * totalTimeSize(total: totalTime), weight: .semibold))
                    .foregroundStyle(isRunning ? tintColor.color.mix(with: .white, by: 0.05).opacity(isPaused ? 0.5 : 1.0) : .black)
                    .monospacedDigit()
                    .bold()
            }
            VStack(spacing: 0) {
                Text(isRunning ? TimeFormatting.clock(from: Int(remainingTime)) : String(localized: "KEY_END"))
                    .font(.system(size: size * CGFloat(hasHours)))
                    .foregroundStyle(isRunning ? (isPaused ? Color.gray : Color.white) : Color.black)
                    .monospacedDigit()
                    .padding(.bottom)
                    .bold()
            }
            VStack {
                ZStack {
                    Star()
                        .stroke(Color(isRunning ? .gray.opacity(0.2) : tintColor.color.mix(with: .black, by: 0.15)), lineWidth: size * 0.035)
                        .frame(width: size * 1.2, height: size * 1.17)
                    Star()
                        .trim(from: 0.0, to: min(proportion + 0.004, 1.0))
                        .stroke(Color.black.opacity(isRunning && !isLuminanceReduced && proportion != 0 ? 0.4 : 0), style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
                        .frame(width: size * 1.2, height: size * 1.17)
                    Star()
                        .trim(from: 0.0, to: min(proportion, 1.0))
                        .stroke(tintColor.color.mix(with: .white, by: 0.1).opacity(!isLuminanceReduced && isRunning ? 1.0 : 0), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: size * 1.2, height: size * 1.17)
                }
            }
        }
    }
    
    @ViewBuilder
    func HeartCountDownView(totalTime: Int, remainingTime: Double, isRunning: Bool, isPaused: Bool, proportion: Double, size: CGFloat, isLuminanceReduced: Bool) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Text(isRunning ? TimeFormatting.clock(from: Int(0)) : String(localized: "KEY_END"))
                    .font(.system(size: size * 0.22))
                    .foregroundStyle(.clear)
                    .monospacedDigit()
                    .padding(.bottom)
                Text(TimeFormatting.hmsLabel(from: Int(displayTotalTime)))
                    .font(.system(size: size * 0.11, weight: .semibold))
                    .foregroundStyle(isRunning ? tintColor.color.mix(with: .white, by: 0.05).opacity(isPaused ? 0.5 : 1.0) : .black)
                    .monospacedDigit()
            }
            VStack(spacing: 0) {
                Text(isRunning ? TimeFormatting.clock(from: Int(remainingTime)) : String(localized: "KEY_END"))
                    .font(.system(size: size * 0.24))
                    .foregroundStyle(isRunning ? (isPaused ? Color.gray : Color.white) : Color.black)
                    .monospacedDigit()
                    .padding(.bottom)
            }
            VStack {
                ZStack {
                    Heart()
                        .stroke(Color(isRunning ? .gray.opacity(0.2) : tintColor.color.mix(with: .black, by: 0.15)), lineWidth: size * 0.035)
                        .frame(width: size * 1.1, height: size * 1.1)
                    Heart()
                        .trim(from: 0.0, to: min(proportion + 0.004, 1.0))
                        .stroke(Color.black.opacity(isRunning && !isLuminanceReduced && proportion != 0 ? 0.4 : 0), style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
                        .frame(width: size * 1.1, height: size * 1.1)
                    Heart()
                        .trim(from: 0.0, to: min(proportion, 1.0))
                        .stroke(tintColor.color.mix(with: .white, by: 0.1).opacity(!isLuminanceReduced && isRunning ? 1.0 : 0), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: size * 1.1, height: size * 1.1)
                }
            }
        }
    }
    // MARK: - 停止/再開
    
    /// 停止: 残り秒数を保存してセッションを終了
    private func pause() {
        guard let target = currentTargetDate else {
            remainingTime = 0
            runtime.cancelSmartAlarm()
            return
        }
        // 未来のターゲット時刻との差分（秒）。負数にならないように丸める
        let remain = Int(target.timeIntervalSinceNow.rounded(.down))
        remainingTime = Double(max(0, remain))
        runtime.cancelSmartAlarm()
        isRunningTimer = false
    }
    
    /// 再開: 現在から remainingTime 秒後を新たなターゲットとして再スケジュール
    private func restart() {
        let seconds = max(0, remainingTime)
        let newTarget = Date().addingTimeInterval(TimeInterval(seconds + 0.3))
        runtime.scheduleSmartAlarm(at: newTarget)
        isRunningTimer = true
    }
    
    private func again() {
        let seconds = max(0, totalTime)
        let newtarget = Date().addingTimeInterval(TimeInterval(seconds + 0.85))
            runtime.scheduleSmartAlarm(at: newtarget)
    }
    
}


