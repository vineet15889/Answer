//
//  TranslationResponse.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import Foundation

struct TranslationResponse: Codable, Identifiable {
    var id: UUID = UUID()
    let detectedLanguage: String
    let translatedText: String
    let originalText: String

    enum CodingKeys: String, CodingKey {
        case detectedLanguage = "detected_language"
        case translatedText = "translated_text"
        case originalText = "original_text"
    }
}
