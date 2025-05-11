//
//  ResultsView.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import SwiftUI

struct ResultsView: View {
    @StateObject private var viewModel: ResultsViewModel
    @Environment(\.dismiss) var dismiss
    
    @Binding var navigationPath: NavigationPath
    @State private var scrollToLanguage = false
    @State private var scrollToTranslation = false
    
    init(capturedImage: UIImage?, translationResult: TranslationResponse? = nil, navigationPath: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: ResultsViewModel(image: capturedImage, translationResult: translationResult))
        _navigationPath = navigationPath
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        navigationPath.append("history")
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.black)
                
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            if let image = viewModel.capturedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray, lineWidth: 2)
                                    )
                                    .padding(16)
                            }
                            
                            Spacer(minLength: 20)
                            
                            if !viewModel.languageString.isEmpty {
                                TerminalView(
                                    text: viewModel.languageString,
                                    animateOnce: true,
                                    animationDelay: 0.05,
                                    pauseAtEnd: 1.0,
                                    terminalWidth: UIScreen.main.bounds.width - 32,
                                    textColor: .green,
                                    backgroundColor: Color(UIColor.darkGray),
                                    borderColor: .green
                                )
                                .id("languageTerminal")
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation {
                                            scrollToLanguage = true
                                            scrollProxy.scrollTo("languageTerminal", anchor: .center)
                                        }
                                    }
                                }
                            }
                            
                            Spacer(minLength: 20)
                            
                            TerminalView(
                                text: viewModel.translationResult?.translatedText ?? "Translation not available",
                                animateOnce: true,
                                animationDelay: 0.025,
                                pauseAtEnd: 1.0,
                                terminalWidth: UIScreen.main.bounds.width - 32,
                                fontSize: 18,
                                textColor: .green,
                                backgroundColor: Color(UIColor.darkGray),
                                borderColor: .green,
                                showBlinkingCursor: false
                            )
                            .id("translationTerminal")
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                            .fixedSize(horizontal: false, vertical: true)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        scrollToTranslation = true
                                        scrollProxy.scrollTo("translationTerminal", anchor: .bottom)
                                    }
                                }
                                
                                let textToAnimate = viewModel.translationResult?.translatedText ?? "Translation not available"
                                let animationCharDelay = 0.15
                                let animationPauseAtEnd = 1.0
                                let estimatedAnimationDuration = Double(textToAnimate.count) * animationCharDelay + animationPauseAtEnd
                                let timerInvalidationDelay = estimatedAnimationDuration + 0.5
                                let scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
                                    withAnimation {
                                        scrollProxy.scrollTo("translationTerminal", anchor: .bottom)
                                    }
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + timerInvalidationDelay) {
                                    scrollTimer.invalidate()
                                }
                                RunLoop.main.add(scrollTimer, forMode: .common)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .onChange(of: scrollToLanguage) { newValue, _ in
                        if newValue {
                            withAnimation {
                                scrollProxy.scrollTo("languageTerminal", anchor: .center)
                            }
                        }
                    }
                    .onChange(of: scrollToTranslation) { newValue, _ in
                        if newValue {
                            withAnimation {
                                scrollProxy.scrollTo("translationTerminal", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.refreshImage()
        }
    }
}

#Preview {
    ResultsView(capturedImage: UIImage(systemName: "photo"), navigationPath: .constant(NavigationPath.init()))
}
