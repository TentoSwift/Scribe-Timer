import SwiftUI
import CoreGraphics
import CoreML
import UIKit

struct Time: Hashable {
    var count: Int
    var timeUnitMode: TimeUnitMode
}

struct ContentView: View {
    @EnvironmentObject private var screenSizeStore: ScreenSizeStore
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .orange
    @AppStorage("inputDelay", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var inputDelay: Double = 0.4
    @AppStorage("isStartingTimer", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var isStartingTimer: Bool = false
    @AppStorage("scheduledDateWidet", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var scheduledDateWidet: Date = Date()
    @AppStorage("totalTimeSeconds", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var totalTimeSeconds: Double = 0.0
    @AppStorage("timerHistory", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var timerHistoryData = Data()
    @AppStorage("hasShownOnboarding", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var hasShownOnboarding: Bool = false
    @State private var currentLine: [CGPoint] = []
    @State private var lines: [[CGPoint]] = []
    @State private var showOver24Alert: Bool = false
    
    @State private var currentDigits: [Int] = []
    @State private var recognizedValue: Int = 0
    @State private var recognizedText: String = ""
    
    @State private var isPresentedNewTimerView: Bool = false
    @State private var isPresentedTimerView: Bool = false
    @State private var tab: Int = 0
    @State private var selectedTimerMode: TimeUnitMode = .minutes
    
    @State private var path = NavigationPath()
    
    @State private var isNoInput: Bool = false
    
    @State private var inputTime: [Time] = []
    
    @State private var recognitionWorkItem: DispatchWorkItem?
    
    @State private var previewDigit: Int? = nil
    @State private var drawCounter: Int = 0
    @State private var isPresented: Bool = false
    
    private let targetSize = CGSize(width: 28, height: 28)
    
    private func startTimer() {
        if !inputTime.isEmpty {
            let totalSeconds = calculateTotalSeconds()
            
            if totalSeconds > 86400 {
                showOver24Alert = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPresentedTimerView.toggle()
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
                TabView(selection: $tab) {
                    InputView()
                        .tag(0)
                    SelectedTimerView()
                        .tag(1)
                    SettingsView()
                        .tag(2)
                }
                .background {
                    VStack {
                        Button {
                            if !inputTime.isEmpty {
                                startTimer()
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 30)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .ignoresSafeArea()
                        }
                        .opacity(0)
                    }
                    .modify { view in
                        if tab == 0 && !inputTime.isEmpty {
                            view
                            .handGestureShortcut(.primaryAction)
                            .accessibilityQuickAction(style: .prompt) {
                                Button{
                                    startTimer()
                                }label: {
                                    Text("KEY_START")
                                }
                            }
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.black)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                    }
                    NavigationLink(isActive: $isPresentedTimerView) {
                        TimerView(
                            isPresentedTimerView: $isPresentedTimerView,
                            startDate: .now,
                            totalTime: calculateTotalSeconds(),
                            displayTotalTime: totalTimeSeconds
                        )
                    } label: {
                        Text("")
                    }
                    .opacity(0)
                }
                .navigationDestination(isPresented: $isPresented) {
                    OnbordingView(isOnbord: true, isPresented: $isPresented)
                        .navigationBarBackButtonHidden()
                }
                .sheet(isPresented: $isPresentedNewTimerView) {
                    NavigationStack {
                        NewTimerView()
                            .toolbarVisibility(.hidden, for: .navigationBar)
                    }
                }
                .tabViewStyle(.verticalPage)
                .onAppear {
                    if !hasShownOnboarding {
                        isPresented.toggle()
                    }
                    inputTime = []
                    if isStartingTimer {
                        isPresentedTimerView = true
                    }
                }
                .onChange(of: tab) {
                    // no-op
                }
                .onChange(of: inputTime) {
                    totalTimeSeconds = calculateTotalSeconds()
                }
                .alert("KEY_ALEART_24OVER", isPresented: $showOver24Alert) {
                    Button("OK", role: .cancel) { }
                }
                .toolbar { bottomToolbar }
        }
      
    }
    
    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            HStack {
                if tab == 0 {
                    ForEach(Array(TimeUnitMode.allCases), id: \.self) { timer in
                        Button {
                            withAnimation {
                                selectedTimerMode = timer
                            }
                        } label: {
                            Text(timer.title)
                        }
                        .modify { view in
                            if #available(watchOS 26.0, *) {
                                view.foregroundStyle(.white.opacity(0.8))
                            } else {
                                view.foregroundStyle(.white)
                            }
                        }
                        .tint(selectedTimerMode == timer || isNoInput ? tintColor.color : Color.clear)
                        .disabled(isDisabled(mode: timer) || isNoInput)
                    }

                    Button(action: {
                        withAnimation {
                            lines = []
                            currentDigits = []
                            recognizedValue = 0
                            recognizedText = ""
                            if !inputTime.isEmpty {
                                _ = inputTime.removeLast()
                            }
                        }
                    }) {
                        Image(systemName: "delete.left.fill")
                            .foregroundColor(tintColor.color)
                    }
                    .tint(.clear)
                    .disabled(inputTime.isEmpty && tab == 0)
                }
            }
        }
    }
    
    @ViewBuilder
    func InputView() -> some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                    
                    Path { path in
                        for line in lines {
                            addPoints(to: &path, points: line)
                        }
                        addPoints(to: &path, points: currentLine)
                    }
                    .stroke(tintColor.color,
                            style: StrokeStyle(lineWidth: 12,
                                               lineCap: .round,
                                               lineJoin: .round))
                    VStack(alignment: .leading) {
                                            HStack(spacing: 0) {
                                                // ★修正: previewDigit がある場合も表示するように条件を変更
                                                if tab == 0 && (!inputTime.isEmpty || previewDigit != nil) {
                                        
                                                        HStack(alignment: .lastTextBaseline) {
                                                            ForEach(previewDisplayTimes, id: \.timeUnitMode) { time in
                                                                Text("\(time.count)")
                                                                    .bold()
                                                                    +
                                                                Text(time.timeUnitMode.title)
                                                            }
                                                        }
                                                        .foregroundStyle(tintColor.color.opacity(0.8))
                                                        .onTapGesture {
                                                            if !inputTime.isEmpty {
                                                                let totalSeconds = calculateTotalSeconds()
                                                                
                                                                if totalSeconds > 86400 {
                                                                    showOver24Alert = true
                                                                } else {
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                                        isPresentedTimerView.toggle()
                                                                    }
                                                                }
                                                            }
                                                        }
                                                }
                                                Spacer()
                                            }
                                            .padding()
                                            Spacer()
                                        }
                    .padding()
                    .onChange(of: isPresentedTimerView) { old, new in
                        let seconds = Int(calculateTotalSeconds())
                        recordTimerStart(totalSeconds: seconds)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                   startTimer()
                }
                
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // 1. 確定待ちタイマーをキャンセル
                            recognitionWorkItem?.cancel()
                            
                            // 2. 線の描画データを更新
                            currentLine.append(value.location)
                            
                            drawCounter += 1
                            if drawCounter % 5 == 0 {
                                let currentStrokes = lines
                                let currentSegment = currentLine
                                let size = geometry.size
                                
                                DispatchQueue.global(qos: .userInteractive).async {
                                    let allLines = currentStrokes + [currentSegment]
                                    
                                    if let digit = self.recognizeNumber(from: allLines, in: size) {
                                        // 結果の更新はメインスレッドで
                                        DispatchQueue.main.async {
                                            // まだ書いている途中（指を離していない）場合のみ更新
                                            if !self.currentLine.isEmpty {
                                                withAnimation(.linear(duration: 0.1)) {
                                                    self.previewDigit = digit
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            // 指を離したらカウンタをリセット
                            drawCounter = 0
                            
                            // (既存のノイズ判定処理...)
                            let xs = currentLine.map { $0.x }
                            let ys = currentLine.map { $0.y }
                            let width = (xs.max() ?? 0) - (xs.min() ?? 0)
                            let height = (ys.max() ?? 0) - (ys.min() ?? 0)
                            
                            if width < 20 && height < 20 {
                                currentLine = []
                                previewDigit = nil // ノイズならプレビューも消す
                                return
                            }
                            
                            lines.append(currentLine)
                            
                            // 描画用の currentLine は少し遅れて消す（見た目のつながりのため）
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                currentLine = []
                            }
                            tab = 0
                            
                            // ★確定処理の予約
                            let workItem = DispatchWorkItem {
                                if let digit = recognizeNumber(from: lines, in: geometry.size) {
                                    
                                    // --- 追加: 全体で6桁制限 ---
                                    let currentTotalDigitCount = combinedDisplayTimes
                                        .map { String($0.count) }
                                        .joined()
                                        .count
                                    
                                    // すでに6桁なら追加しない
                                    guard currentTotalDigitCount < 6 else {
                                        lines = []
                                        withAnimation {
                                            previewDigit = nil
                                        }
                                        return
                                    }
                                    
                                    let isDigitCountOK = isDigitCountValid(adding: digit, mode: selectedTimerMode)
                                
                                    if isDigitCountOK {
                                        currentDigits.append(digit)
                                        let valueString = currentDigits.map(String.init).joined()
                                        recognizedValue = Int(valueString) ?? 0
                                        
                                        let time = Time(count: recognizedValue, timeUnitMode: selectedTimerMode)
                                        inputTime.append(time)
                                        checkAndAutoSwitchUnit()
                                        
                                        currentDigits = []
                                        recognizedValue = 0
                                        recognizedText = allTimeText()
                                    }
                                }
                                
                                lines = []
                                withAnimation {
                                    previewDigit = nil
                                }
                            }
                            
                            self.recognitionWorkItem = workItem
                            DispatchQueue.main.asyncAfter(deadline: .now() + inputDelay, execute: workItem)
                        }
                )
            }
            .cornerRadius(10)
            .ignoresSafeArea()
        }
    }
    
    private func saveTimerHistory(_ arr: [Int]) {
        if let data = try? JSONEncoder().encode(arr) {
            timerHistoryData = data
        }
    }
    
    private func loadTimerHistory() -> [Int] {
        guard !timerHistoryData.isEmpty,
              let decoded = try? JSONDecoder().decode([Int].self, from: timerHistoryData)
        else {
            return []
        }
        return decoded
    }
    
    private func recordTimerStart(totalSeconds: Int, maxCount: Int = 4) {
        var arr = loadTimerHistory()
        
        // 0秒は保存しない
        guard totalSeconds > 0 else { return }
        
        // 既にあれば削除（重複防止）
        if let index = arr.firstIndex(of: totalSeconds) {
            arr.remove(at: index)
        }
        arr.insert(totalSeconds, at: 0)
        
        // 最大件数制限
        if arr.count > maxCount {
            arr = Array(arr.prefix(maxCount))
        }
        
        saveTimerHistory(arr)
    }
    
    private func calculateTotalSeconds() -> Double {
        var total: Double = 0
        
        for time in combinedDisplayTimes {
            switch time.timeUnitMode {
            case .hours:
                total += Double(time.count * 3600) // 1時間は3600秒
            case .minutes:
                total += Double(time.count * 60)   // 1分は60秒
            case .seconds:
                total += Double(time.count)        // 秒はそのまま
            }
        }
        return total
    }
    
        private var combinedDisplayTimes: [Time] {
            return createCombinedTimes(from: inputTime)
        }
        
        private var previewDisplayTimes: [Time] {
            var tempInput = inputTime
            
            // 入力中の数字があれば、一時的に配列の末尾に追加して計算する
            if let digit = previewDigit {
                let tempTime = Time(count: digit, timeUnitMode: selectedTimerMode)
                tempInput.append(tempTime)
            }
            
            return createCombinedTimes(from: tempInput)
        }
        
        // ★追加: 結合ロジックを関数化（共通化）
        private func createCombinedTimes(from source: [Time]) -> [Time] {
            var result: [Time] = []
            
            for time in source {
                if let lastIndex = result.indices.last,
                   result[lastIndex].timeUnitMode == time.timeUnitMode {
                    
                    let combinedString = "\(result[lastIndex].count)\(time.count)"
                    if let combinedCount = Int(combinedString) {
                        result[lastIndex].count = combinedCount
                    }
                } else {
                    result.append(time)
                }
            }
            return result
        }
    
    /// 桁数制限（上位の単位がある時は2桁まで）をチェックする関数
    private func isDigitCountValid(adding digit: Int, mode: TimeUnitMode) -> Bool {
        // 1. 現在選択しているモードの、すでに入力された数字を取得して結合
        let currentModeTimes = inputTime.filter { $0.timeUnitMode == mode }
        let currentString = currentModeTimes.map { String($0.count) }.joined()
        
        // 2. 新しい数字を足してみる（シミュレーション）
        let newString = currentString + String(digit)
        
        // 文字列を数値に変換（念のため）
        guard let newValue = Int(newString) else { return false }
        
        // 3. 上位の単位が存在するかチェック
        let hasHours = inputTime.contains { $0.timeUnitMode == .hours }
        let hasMinutes = inputTime.contains { $0.timeUnitMode == .minutes }
        
        // 4. ルール判定
        switch mode {
        case .hours:
            // 時間は桁数制限なし（24時間制限の方で弾かれるため）
            return true
            
        case .minutes:
            // 時間があるなら、分は2桁(99)まで
            if hasHours {
                return newValue < 100 // 100以上（3桁）はダメ
            }
            return true
            
        case .seconds:
            if hasHours || hasMinutes {
                return newValue < 100 // 100以上（3桁）はダメ
            }
            return true
        }
    }
    
    /// 新しい数字を追加した場合の合計秒数を予測する関数
    private func predictTotalSeconds(adding digit: Int, mode: TimeUnitMode) -> Double {
        // 1. 仮の入力配列を作成（現在の配列 + 新しい数字）
        // ※ここでは結合処理はせず、単純に末尾に追加します（実際の入力フローと同じ状態にするため）
        var tempInput = inputTime
        tempInput.append(Time(count: digit, timeUnitMode: mode))
        
        // 2. combinedDisplayTimes と全く同じロジックで「表示上の数値」に結合する
        // これをやらないと "1", "1", "1" が "111" ではなく "3" や "12" として計算されてしまう
        var combined: [Time] = []
        
        for time in tempInput {
            if let lastIndex = combined.indices.last,
               combined[lastIndex].timeUnitMode == time.timeUnitMode {
                
                // 文字列として結合 (例: "11" + "1" = "111")
                let combinedString = "\(combined[lastIndex].count)\(time.count)"
                
                // Intの範囲内なら更新（オーバーフロー対策）
                if let combinedCount = Int(combinedString) {
                    combined[lastIndex].count = combinedCount
                }
            } else {
                combined.append(time)
            }
        }
        
        // 3. 正しい秒数に換算
        var total: Double = 0
        for t in combined {
            switch t.timeUnitMode {
            case .hours:   total += Double(t.count * 3600)
            case .minutes: total += Double(t.count * 60)
            case .seconds: total += Double(t.count)
            }
        }
        
        return total
    }
    
    private func checkAndAutoSwitchUnit() {
        // 現在のモードの入力値（文字列）を取得
        let currentModeTimes = inputTime.filter { $0.timeUnitMode == selectedTimerMode }
        let combinedString = currentModeTimes.map { String($0.count) }.joined()
        
        // 入力が2桁（文字数が2）以上になったら判定
        if combinedString.count >= 2 {
            withAnimation {
                switch selectedTimerMode {
                case .hours:
                    // 時間は2桁打ったら、無条件で「分」へ
                    selectedTimerMode = .minutes
                    
                case .minutes:
                    // ★ここがポイント
                    // 「時間」がすでに入力されているかチェック
                    let hasHours = inputTime.contains { $0.timeUnitMode == .hours }
                    
                    if hasHours {
                        // 時間があるなら、分は2桁まで。次は「秒」へ
                        selectedTimerMode = .seconds
                    } else {
                        // 時間がないなら（例：120分）、自動遷移しない（または3桁まで待つなど）
                    }
                    
                case .seconds:
                    // 秒の次はなし
                    break
                }
            }
        }
    }
    
    func isDisabled(mode: TimeUnitMode) -> Bool {
        guard let lastUnit = inputTime.last?.timeUnitMode else { return false }
        
        // 1. 逆戻り禁止
        if mode.rank < lastUnit.rank { return true }
        
        // 2. 同じ単位の連続入力制限
        if mode == lastUnit {
            let displayCount = combinedDisplayTimes.last(where: { $0.timeUnitMode == mode })?.count ?? 0
            let digitCount = String(displayCount).count
            
            // --- 上位の単位があるかチェック ---
            // 自分よりランクが低い（数字が小さい＝上位）単位が含まれているか
            let hasHigherUnit = inputTime.contains { $0.timeUnitMode.rank < mode.rank }
            
            if hasHigherUnit {
                return digitCount >= 2
            } else {
                return false
            }
        }
        
        return false
    }
    
    private func addPoints(to path: inout Path, points: [CGPoint]) {
        guard let first = points.first else { return }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
    }
    
    // 引数で線データを受け取るバージョンを追加
    private func recognizeNumber(from targetLines: [[CGPoint]], in size: CGSize) -> Int? {
        guard let uiImage = createImage(from: targetLines, size: size) else {
            return nil
        }
        // ... (以下既存と同じML処理) ...
        guard let pixelBuffer = resizeUIImageToPixelBuffer(uiImage, size: targetSize) else { return nil }
        // ...
        do {
            let config = MLModelConfiguration()
            let model = try MNISTClassifier(configuration: config)
            let prediction = try model.prediction(image: pixelBuffer)
            return Int(prediction.classLabel)
        } catch {
            return nil
        }
    }
    
    // 引数で線データを受け取るバージョンを追加
    private func createImage(from targetLines: [[CGPoint]], size: CGSize) -> UIImage? {
        // ... (中身は既存の self.lines を targetLines に変えるだけ) ...
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(12.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for line in targetLines { // ここを引数の変数に変える
            guard let first = line.first else { continue }
            context.move(to: first)
            for point in line.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func resizeUIImageToPixelBuffer(_ image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_OneComponent8,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let pb = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }
        
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pb),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
        
        guard let cgImage = image.cgImage else { return nil }
        context?.interpolationQuality = .high
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        return pb
    }
    
    private func allTimeText() -> String {
        var parts: [String] = []
        
        for t in inputTime {
            parts.append("\(t.count)\(t.timeUnitMode.title)")
        }
        
        return parts.joined()
    }
}
