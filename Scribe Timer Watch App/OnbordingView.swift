//
//  OnbordingView.swift
//  Scribe Timer Watch App
//
//  Created by 石野天斗 on 2026/02/18.
//

import SwiftUI

struct OnbordingView: View {
    var isOnbord: Bool
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var screenSizeStore: ScreenSizeStore
    @AppStorage("hasShownOnboarding", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var hasShownOnboarding: Bool = false
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .orange
    @State private var tabNumber: Int = 0
    @Binding var isPresented: Bool
    
    private var imageSize: CGFloat {
        return screenSizeStore.screenWidth * 0.6
    }
    private var fontSize: CGFloat {
        return screenSizeStore.screenWidth * 0.1
    }
    
    private func action() {
        withAnimation {
            let lastIndex = isOnbord ? 4 : 3
            if tabNumber < lastIndex {
                tabNumber += 1
            } else {
                isPresented.toggle()
            }
        }
    }
    
    var body: some View {
        TabView(selection: $tabNumber) {
            
            if isOnbord {
                hellowView()
                    .tag(0)
            }
            
            firstView()
                .navigationTitle {
                    Text("KEY_HOWTO")
                        .foregroundStyle(tintColor.color)
                }
                .tag(isOnbord ? 1 : 0)
            
            secondView()
                .navigationTitle {
                    Text("KEY_HOWTO")
                        .foregroundStyle(tintColor.color)
                }
                .tag(isOnbord ? 2 : 1)
            thirdView()
                .navigationTitle {
                    Text("KEY_HOWTO")
                        .foregroundStyle(tintColor.color)
                }
                .tag(isOnbord ? 3 : 2)
            if !purchaseManager.isPro {
                IAPView()
                    .tag(isOnbord ? 4 : 3)
            }
        }
        .onAppear {
            hasShownOnboarding = true
        }
        .onChange(of: purchaseManager.isPro) {
            if tabNumber == 4 {
                isPresented.toggle()
            }
        }
        .ignoresSafeArea()
        .tabViewStyle(.page(indexDisplayMode: .never))
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                   action()
                } label: {
                    HStack {
                        Spacer()
                        Text(
                            tabNumber == 0 && isOnbord
                            ? "KEY_START_ONBORDING"
                            : (tabNumber < (isOnbord ? 4 : 3) ? "KEY_NEXT" : "KEY_DONTNOW")
                        )
                        .foregroundStyle(
                            tabNumber < (isOnbord ? 4 : 3)
                            ? Color.black
                            : .secondary
                        )
                        Spacer()
                    }
                    .padding()
                }
                .accessibilityQuickAction(style: .outline) {
                    Button{
                        action()
                    }label: {
                            Text(
                                tabNumber == 0 && isOnbord
                                ? "KEY_START_ONBORDING"
                                : (tabNumber < (isOnbord ? 4 : 3) ? "KEY_NEXT" : "KEY_DONTNOW")
                            )
                    }
                }
                .handGestureShortcut(.primaryAction)
                .modify { view in
                    let lastIndex = isOnbord ? 4 : 3
                    if tabNumber < lastIndex {
                        view.tint(tintColor.color)
                    } else {
                        view.tint(.clear)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func hellowView() -> some View {
        VStack(alignment: .center) {
            Image("ScribeTimerIconImage")
                .resizable()
                .scaledToFit()
                .frame(minWidth: imageSize * 0.3)
                .padding()
            Spacer()
            Text("KEY_HELLO_SCRIBETIMER")
                .font(.system(size: fontSize))
                .bold()
                .multilineTextAlignment(.center)
            Text("KEY_INTRODUCTION")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func firstView() -> some View {
        VStack(alignment: .center) {
            Image("OnbordingView_Image2")
                .resizable()
                .scaledToFit()
                .frame(minWidth: imageSize)
                .cornerRadius(3)
                .padding()
                .overlay(alignment: .bottomTrailing) {
                    Image("hand.draw.and.line.dotted.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange.mix(with: .white, by: 0.5))
                }
            Spacer()
            Text("KEY_ONBORDING1")
                .font(.system(size: fontSize))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func secondView() -> some View {
        VStack(alignment: .center) {
            Image("OnbordingView_Image1")
                .resizable()
                .scaledToFit()
                .frame(minWidth: imageSize)
                .cornerRadius(3)
                .padding()
                .overlay(alignment: .bottomTrailing) {
                    Image("hand.draw.and.line.dotted.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange.mix(with: .white, by: 0.5))
                }
            Spacer()
            Text("KEY_ONBORDING2")
                .font(.system(size: fontSize))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func thirdView() -> some View {
        VStack(alignment: .center) {
                Image(systemName: "hand.tap.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.orange.mix(with: .white, by: 0.5), .white)
                .symbolEffect(.bounce, options: .speed(0.2))
                .font(.system(size: imageSize * 0.5))
                .overlay(alignment: .bottomTrailing) {
                    Image("hand.side.pinch.fill")
                        .foregroundStyle(.orange.mix(with: .white, by: 0.5), .white)
                }
            Spacer()
            Text("KEY_ONBORDING3")
                .font(.system(size: fontSize))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }
    
}


struct HintView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var screenSizeStore: ScreenSizeStore
    @AppStorage("hasShownOnboarding", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var hasShownOnboarding: Bool = false
    @AppStorage("tintColor", store: UserDefaults(suiteName: "group.com.tento.scribe.timer")) private var tintColor: TintColor = .orange
    @State private var tabNumber: Int = 0
    @Binding var isPresented: Bool
    
    private var imageSize: CGFloat {
        return screenSizeStore.screenWidth * 0.6
    }
    private var fontSize: CGFloat {
        return screenSizeStore.screenWidth * 0.1
    }
    
    private func action() {
        withAnimation {
            if purchaseManager.isPro {
                if tabNumber == 2 {
                    isPresented.toggle()
                } else {
                tabNumber += 1
                }
            } else {
                if tabNumber == 3 {
                    isPresented.toggle()
                } else {
                    tabNumber += 1
                }
            }
        }
    }
    
    var body: some View {
        TabView(selection: $tabNumber) {
            firstView()
                .tag(0)
            secondView()
                .tag(1)
            thirdView()
                .tag(2)
            if !purchaseManager.isPro {
                IAPView()
                    .tag(3)
            }
        }
        .onChange(of: purchaseManager.isPro) {
            if tabNumber == 3 {
                isPresented.toggle()
            }
        }
        .ignoresSafeArea()
        .tabViewStyle(.page(indexDisplayMode: .never))
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                   action()
                } label: {
                    HStack {
                        Spacer()
                        Text(
                           tabNumber < 3 ? "KEY_NEXT" : "KEY_DONTNOW"
                        )
                        .foregroundStyle(
                            tabNumber < 3
                            ? Color.black
                            : .secondary
                        )
                        Spacer()
                    }
                    .padding()
                }
                .handGestureShortcut(.primaryAction)
                .accessibilityQuickAction(style: .outline) {
                    Button{
                        action()
                    }label: {
                        Text(
                           tabNumber < 3 ? "KEY_NEXT" : "KEY_DONTNOW"
                        )
                    }
                }
                .modify { view in
                    let lastIndex = 3
                    if tabNumber < lastIndex {
                        view.tint(tintColor.color)
                    } else {
                        view.tint(.clear)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func hellowView() -> some View {
        VStack(alignment: .center) {
            Image("ScribeTimerIconImage")
                .resizable()
                .scaledToFit()
                .frame(minWidth: imageSize * 0.3)
                .padding()
            Spacer()
            Text("KEY_HELLO_SCRIBETIMER")
                .font(.system(size: fontSize))
                .bold()
                .multilineTextAlignment(.center)
            Text("KEY_INTRODUCTION")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func firstView() -> some View {
        VStack(alignment: .center) {
            Image("OnbordingView_Image2")
                .resizable()
                .scaledToFit()
                .frame(minWidth: imageSize)
                .cornerRadius(3)
                .padding()
                .overlay(alignment: .bottomTrailing) {
                    Image("hand.draw.and.line.dotted.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange.mix(with: .white, by: 0.5))
                }
            Spacer()
            Text("KEY_ONBORDING1")
                .font(.system(size: fontSize))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func secondView() -> some View {
        VStack(alignment: .center) {
            Image("OnbordingView_Image1")
                .resizable()
                .scaledToFit()
                .frame(minWidth: imageSize)
                .cornerRadius(3)
                .padding()
                .overlay(alignment: .bottomTrailing) {
                    Image("hand.draw.and.line.dotted.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange.mix(with: .white, by: 0.5))
                }
            Spacer()
            Text("KEY_ONBORDING2")
                .font(.system(size: fontSize))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func thirdView() -> some View {
        VStack(alignment: .center) {
            Image(systemName: "hand.tap.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.orange.mix(with: .white, by: 0.5), .white)
                .symbolEffect(.bounce, options: .speed(0.2))
                .font(.system(size: imageSize * 0.5))
                .padding()
                .overlay(alignment: .bottomTrailing) {
                    Image("hand.side.pinch.fill")
                        .foregroundStyle(.orange.mix(with: .white, by: 0.5), .white)
                }
            Spacer()
            Text("KEY_ONBORDING3")
                .font(.system(size: fontSize))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }
    
}
