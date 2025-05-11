//
//  Persistence.swift
//  Answer
//
//  Created by Trae AI on [Current Date]
//

import CoreData
import UIKit // For UIImage

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Answer") // Should match your .xcdatamodeld file name
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it may be useful during development.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Preview controller for SwiftUI Previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<3 {
            let newItem = TranslationEntry(context: viewContext)
            newItem.timestamp = Date().addingTimeInterval(Double(i) * -3600) // Offset by hours
            newItem.id = UUID()
            newItem.detectedLanguage = "Sample Language \(i)"
            newItem.translatedText = "Sample translated text for item \(i)."
            newItem.originalText = "Sample original text for item \(i)."
            // Create a small sample image data
            if let sampleImage = UIImage(systemName: "photo"), let imageData = sampleImage.pngData() {
                newItem.imageData = imageData
            }
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    // Function to save a new translation
    func saveTranslation(image: UIImage?, detectedLanguage: String, translatedText: String, originalText: String) {
        let context = container.viewContext
        let newTranslation = TranslationEntry(context: context)
        newTranslation.id = UUID()
        newTranslation.timestamp = Date()
        newTranslation.detectedLanguage = detectedLanguage
newTranslation.translatedText = translatedText
        newTranslation.originalText = originalText
        
        if let img = image, let imageData = img.jpegData(compressionQuality: 0.8) { // Compress image
            newTranslation.imageData = imageData
        }
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
            // Handle the error appropriately in a production app
        }
    }
}