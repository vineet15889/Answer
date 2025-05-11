//
//  MeshGradientLoadingView.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import SwiftUI

struct MeshGradientLoadingView: View {
    @State private var animationPhase = 0.0
    @State private var typewriterText: String = ""
    @State private var typewriterIndex: Int = 0
    @State private var showCursor = true
    
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    let typewriterTimer = Timer.publish(every: 0.20, on: .main, in: .common).autoconnect()
    let cursorBlinkTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    let processingText = "Processing..."
    let colors: [Color] = [.blue, .purple, .pink, .orange, .yellow, .green]
    
    private let terminalWidth: CGFloat = 190
    
    var body: some View {
        mainContentView
            .onReceive(timer) { _ in
                animationPhase += 0.02
            }
            .onReceive(typewriterTimer) { _ in
                handleTypewriterAnimation()
            }
            .onReceive(cursorBlinkTimer) { _ in
                // Blink the cursor
                withAnimation {
                    showCursor.toggle()
                }
            }
    }
    
    private var mainContentView: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            meshGradientView
            VStack {
                Spacer()
                terminalView
                    .padding(.bottom, 50)
            }
        }
    }
    
    private var meshGradientView: some View {
        ZStack {
            ForEach(0..<5) { index in
                gradientCircle(for: index)
            }
        }
        .blur(radius: 30)
    }
    
    private func gradientCircle(for index: Int) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        colors[index % colors.count],
                        colors[index % colors.count].opacity(0)
                    ]),
                    center: .center,
                    startRadius: 5,
                    endRadius: 300
                )
            )
            .frame(width: 600, height: 600)
            .offset(
                x: sin(animationPhase + Double(index) * 0.5) * 100,
                y: cos(animationPhase + Double(index) * 0.5) * 100
            )
            .blendMode(.screen)
    }
    
    private var terminalView: some View {
        TerminalView(
            text: processingText,
            animateOnce: false,
            animationDelay: 0.10,
            pauseAtEnd: 1.0,
            terminalWidth: terminalWidth,
            terminalHeight: 50,
            fontSize: 18,
            textColor: .green,
            backgroundColor: .black,
            borderColor: .green
        )
    }
    
    private func handleTypewriterAnimation() {
        if typewriterIndex <= processingText.count {
            // Still typing the current word
            let index = processingText.index(processingText.startIndex, offsetBy: typewriterIndex)
            typewriterText = String(processingText[..<index])
            typewriterIndex += 1
        } else {
            // Reset to start typing again
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Even longer pause at the end
                typewriterIndex = 0
                typewriterText = ""
            }
        }
    }
}

struct MeshGradientLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        MeshGradientLoadingView()
    }
}
