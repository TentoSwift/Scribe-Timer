//
//  scribe_widget.swift
//  scribe.widget
//
//  Created by 石野天斗 on 2026/02/16.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), scheduledDate: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), scheduledDate: nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []
        let storedScheduledDate = UserDefaults(suiteName: "group.com.tento.scribe.timer")?.object(forKey: "scheduledDateWidet") as? Date

        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, scheduledDate: storedScheduledDate)
            entries.append(entry)
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let scheduledDate: Date?
}

struct ScribbleAlarmWidgetEntryView : View {
    var entry: Provider.Entry
    
    var images: [Image]

        init(entry: Provider.Entry) {
            self.entry = entry
            self.images = [0, 33, 50, 67, 100, 67, 50, 33].map { i in
                Image(systemName: "gauge.with.dots.needle.\(i)percent")
            }
        }
    
    let ud = UserDefaults(suiteName: "group.com.tento.scribe.timer")
    @AppStorage("scheduledDateWidet", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var scheduledDateWidet: Date = Date()
    @AppStorage("ScribeTimerPro", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var isScribeTimerPro: Bool = false
    
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.isLuminanceReduced) private var isLum
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .blue
    
    @AppStorage("isStartingTimer", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var isStartingTimer: Bool = false

    private var clampedInterval: TimeInterval {
        guard let scheduled = entry.scheduledDate else { return 0 }
        return max(0, scheduled.timeIntervalSince(Date()))
    }

    private var timerEndDate: Date {
        guard let scheduled = entry.scheduledDate else { return Date() }
        // If the scheduled date is in the past, stop at 0 by clamping the end date to now.
        return max(Date(), scheduled)
    }

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            accessoryCircularView()
        case .accessoryInline:
            accessoryInlineView()
        case .accessoryRectangular:
            RectangleWidgetView()
        case .accessoryCorner:
            conerView()
        }
    }
    
    @ViewBuilder
    func accessoryInlineView() -> some View {
        GeometryReader { proxy in
            let size = proxy.size.width
            if isStartingTimer {
                    Image(systemName: "gauge.with.dots.needle.0percent")
                        .font(.system(size: size * 0.9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .foregroundStyle(.secondary)
                if isScribeTimerPro {
                    Text(
                        timerInterval: Date()...timerEndDate,
                        countsDown: true
                    )
                    .font(.system(size: 10))
                    .widgetAccentable()
                }
            } else {
                HStack {
                    Image(systemName: "scribble.variable")
                    Text("ScribbleTimer")
                }
                .widgetAccentable()
            }
        }
    }
    
    @ViewBuilder
    func accessoryCircularView() -> some View {
        Image(systemName: "scribble.variable")
            .foregroundStyle(tintColor.color)
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .widgetAccentable()
            .widgetLabel {
                if isStartingTimer, entry.scheduledDate != nil && isScribeTimerPro {
                    Text(
                        timerInterval: Date()...timerEndDate,
                        countsDown: true
                    )
                }
            }
    }
    
    @ViewBuilder
    func conerView() -> some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let isSmall = proxy.size.width < 40

            Group {
                if isStartingTimer && size < 45 {
                    Image(systemName: "timer")
                            .font(.system(size: size * 0.85))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .foregroundStyle(tintColor.color)
                            .widgetAccentable()
                } else {
                    if isStartingTimer && isScribeTimerPro {
                        ZStack {
                            Text(
                                timerInterval: Date()...timerEndDate,
                                countsDown: true,
                                showsHours: true
                            )
                            .font(.system(size: 10))
                            .foregroundStyle(.black)
                            .monospacedDigit()
                            .frame(width: size, height: size, alignment: .center)
                            .multilineTextAlignment(.center)
                            
                           Circle()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .widgetAccentable()
                        }

                    } else {
                        Image(systemName: "scribble.variable")
                            .foregroundStyle(tintColor.color)
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .widgetAccentable()
                    }
                }
            }
            .widgetLabel {
                if isStartingTimer, entry.scheduledDate != nil && isScribeTimerPro {
                    Text(
                        timerInterval: Date()...timerEndDate,
                        countsDown: true
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    func RectangleWidgetView() -> some View {
            if isStartingTimer, entry.scheduledDate != nil && isScribeTimerPro {
                VStack(alignment: .leading) {
                    Text("KEY_SCRIBETIMER")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(tintColor.color)
                    Text(timerInterval: Date()...timerEndDate,
                         countsDown: true, showsHours: true)
                    .multilineTextAlignment(.center)
                }
                    .font(.title)
            } else {
                HStack {
                    Image(systemName: "scribble.variable")
                        .foregroundStyle(tintColor.color)
                        .widgetAccentable()
                        .font(.largeTitle)
                    Spacer()
                    Text("KEY_SCRIBETIMER")
                }
            }
    }
   
    
    @ViewBuilder
    func WidgetLabelView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "scribble.variable")
                .widgetAccentable()
                .font(.largeTitle)
                .widgetLabel {
                    if isStartingTimer, entry.scheduledDate != nil {
                        Text(timerInterval: .now...timerEndDate,
                             countsDown: true)
                    }
                }
        }
    }
}

struct ScribbleAlarmWidget: Widget {
    let kind: String = "ScribbleAlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScribbleAlarmWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
    }
}


//
//  ScribbleAlarmWidgetControl.swift
//  ScribbleAlarmWidget
//
//  Created by 石野天斗 on 2026/02/11.
//

@main
struct ScribbleAlarmWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScribbleAlarmWidget()
    }
}

