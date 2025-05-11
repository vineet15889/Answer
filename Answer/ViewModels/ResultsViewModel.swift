//
//  ResultsViewModel.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import Foundation
import UIKit
import SwiftUI
import CoreData

class ResultsViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var detectedLanguage: String = "Analyzing..."
    @Published var confidenceLevel: Int = 0
    @Published var showConfidence: Bool = false
    @Published var translationResult: TranslationResponse?
    
    init(image: UIImage?, translationResult: TranslationResponse? = nil) {
        self.capturedImage = image
        self.translationResult = translationResult

        if let result = translationResult {
            self.detectedLanguage = result.detectedLanguage
        }
    }
    
    var confidenceString: String {
        return "\(confidenceLevel)%"
    }
    
    var languageString: String {
        return "Language: \(detectedLanguage)"
    }
    
    var confidenceDisplayString: String {
        return "Confidence: \(confidenceString)"
    }
 
    func refreshImage() {
        let tempImage = capturedImage
        capturedImage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.capturedImage = tempImage
        }
    }
}
