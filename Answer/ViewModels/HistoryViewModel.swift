//
//  HistoryViewModel.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import Foundation
import UIKit
import SwiftUI
import CoreData

class HistoryViewModel: ObservableObject {
    @Published var translations: [TranslationHistoryItem] = []
    @Published var selectedTranslation: TranslationHistoryItem?
    
    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadTranslations()
    }
    
    func loadTranslations() {
        let fetchRequest: NSFetchRequest<TranslationEntry> = TranslationEntry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TranslationEntry.timestamp, ascending: false)]
        
        do {
            let fetchedEntries = try viewContext.fetch(fetchRequest)
            self.translations = fetchedEntries.map { entry in
                var uiImage: UIImage? = nil
                if let imageData = entry.imageData {
                    uiImage = UIImage(data: imageData)
                }
                
                let response = TranslationResponse(
                    detectedLanguage: entry.detectedLanguage ?? "N/A",
                    translatedText: entry.translatedText ?? "N/A",
                    originalText: entry.originalText ?? "N/A"
                )
                
                return TranslationHistoryItem(
                    id: entry.id ?? UUID(),
                    date: entry.timestamp ?? Date(),
                    image: uiImage,
                    result: response
                )
            }
        } catch {
            print("Failed to fetch translations: \(error)")
            self.translations = [] // Fallback to empty
        }
    }
}

struct TranslationHistoryItem: Identifiable {
    let id: UUID
    let date: Date
    let image: UIImage?
    let result: TranslationResponse
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
