//
//  CaptureButtonView.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import SwiftUI

struct CaptureButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                )
        }
    }
}

struct CaptureButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            CaptureButtonView(action: {})
        }
    }
}