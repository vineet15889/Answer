//
//  TranslationService.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import Foundation
import UIKit

enum TranslationError: Error {
    case invalidImage
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
}

class TranslationService: TranslationServiceProtocol {

    
    init() {}
    
    func translateImage(_ image: UIImage, targetLanguage: String = "Spanish") async throws -> TranslationResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw TranslationError.invalidImage
        }
        
        let base64Image = imageData.base64EncodedString()
        let base64WithPrefix = "data:image/png;base64,\(base64Image)"
        
        guard let url = URL(string: ServerConfig.getTranslateURL()) else { // Use ServerConfig
            throw TranslationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "base64_image": base64WithPrefix,
            "target_language": targetLanguage
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw TranslationError.invalidResponse
            }
            
            do {
                let translationResponse = try JSONDecoder().decode(TranslationResponse.self, from: data)
                return translationResponse
            } catch {
                throw TranslationError.decodingError(error)
            }
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.networkError(error)
        }
    }
}
