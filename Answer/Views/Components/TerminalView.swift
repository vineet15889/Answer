//
//  TerminalView.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import SwiftUI

struct TerminalView: View {
    @State private var typewriterText: String = ""
    @State private var typewriterIndex: Int = 0
    @State private var showCursor = true
    @State private var isAnimating = false
    @State private var cursorBlinkCount = 0
    
    // Configuration options
    var text: String
    var animateOnce: Bool = true
    var animationDelay: Double = 0.2
    var pauseAtEnd: Double = 1.0
    var terminalWidth: CGFloat = 200
    var terminalHeight: CGFloat? = nil
    var fontSize: CGFloat = 18
    var textColor: Color = .green
    var backgroundColor: Color = Color(UIColor.darkGray)
    var borderColor: Color = .green
    var showBlinkingCursor: Bool = true
    
    private let cursorBlinkTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: terminalWidth, height: terminalHeight)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(borderColor.opacity(0.5), lineWidth: 1)
                )
            
            HStack {
                ZStack(alignment: .topLeading) {
                    Text(typewriterText)
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .foregroundColor(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                    
                    GeometryReader { geometry in
                        if showBlinkingCursor && (typewriterIndex < text.count || (cursorBlinkCount < 4 && typewriterIndex == text.count)) {
                            let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
                            let lines = typewriterText.components(separatedBy: .newlines)
                            
                            let currentLastLineContent = lines.last ?? ""
                            let xCursorOffset = (currentLastLineContent as NSString).size(withAttributes: [.font: font]).width
                            
                            let numberOfPreviousLines = max(0, lines.count - 1)
                            let yCursorOffset = CGFloat(numberOfPreviousLines) * font.lineHeight
                            
                            Text(showCursor ? "█" : " ")
                                .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                .foregroundColor(textColor)
                                .offset(x: xCursorOffset, y: yCursorOffset)
                        }
                    }
                }
                .frame(width: terminalWidth - 32, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Spacer(minLength: 16)
            }
            .frame(width: terminalWidth)
        }
        .fixedSize(horizontal: true, vertical: true)
        .onAppear {
            startAnimation()
        }
        .onReceive(cursorBlinkTimer) { _ in
            if showBlinkingCursor && (typewriterIndex < text.count || cursorBlinkCount < 4) {
                withAnimation {
                    showCursor.toggle()
                    
                    if typewriterIndex == text.count && showCursor {
                        cursorBlinkCount += 1
                    }
                }
            }
        }
    }
    
    private func startAnimation() {
        isAnimating = true
        typewriterIndex = 0
        typewriterText = ""
        cursorBlinkCount = 0
        
        animateNextCharacter()
    }
    
    private func animateNextCharacter() {
        guard isAnimating, typewriterIndex <= text.count else { return }
        
        if typewriterIndex == text.count {
            typewriterText = text
            
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseAtEnd) {
                if animateOnce {
                    isAnimating = false
                } else {
                    typewriterIndex = 0
                    typewriterText = ""
                    cursorBlinkCount = 0
                    animateNextCharacter()
                }
            }
            return
        }
        
        let index = text.index(text.startIndex, offsetBy: typewriterIndex)
        typewriterText = String(text[..<index])
        typewriterIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
            animateNextCharacter()
        }
    }
    
    private func getTextWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
        let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let attributes = [NSAttributedString.Key.font: font]
        
        let lines = text.split(separator: "\n") // Note: .split might behave differently from .components for trailing newlines
        let lastLine = lines.last.map(String.init) ?? ""
        
        let size = (lastLine as NSString).size(withAttributes: attributes)
        return size.width
    }
}

struct TerminalView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.edgesIgnoringSafeArea(.all)
            VStack {
                TerminalView(text: "English: 95%")
                TerminalView(text: "No blinking cursor here.", showBlinkingCursor: false)
                TerminalView(text: "Explicit background.", backgroundColor: .blue)
            }
        }
    }
}
