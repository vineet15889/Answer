//
//  TranslationServiceProtocol.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import Foundation
import UIKit

protocol TranslationServiceProtocol {
    func translateImage(_ image: UIImage, targetLanguage: String) async throws -> TranslationResponse
}