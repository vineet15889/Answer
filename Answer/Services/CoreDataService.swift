import Foundation
import CoreData
import UIKit

class CoreDataService: CoreDataServiceProtocol {
    
    func saveTranslation(image: UIImage?, detectedLanguage: String, translatedText: String, originalText: String, context: NSManagedObjectContext) {
        let newTranslation = TranslationEntry(context: context)
        newTranslation.id = UUID()
        newTranslation.timestamp = Date()
        newTranslation.detectedLanguage = detectedLanguage
        newTranslation.translatedText = translatedText
        newTranslation.originalText = originalText
        
        if let img = image, let imageData = img.jpegData(compressionQuality: 0.8) {
            newTranslation.imageData = imageData
        }
        
        do {
            try context.save()
            print("Translation saved successfully via CoreDataService.")
        } catch {
            let nsError = error as NSError
            print("CoreDataService: Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func fetchAllTranslations(context: NSManagedObjectContext) -> [TranslationEntry] {
        let fetchRequest: NSFetchRequest<TranslationEntry> = TranslationEntry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TranslationEntry.timestamp, ascending: false)]
        
        do {
            let fetchedEntries = try context.fetch(fetchRequest)
            return fetchedEntries
        } catch {
            print("CoreDataService: Failed to fetch translations: \(error)")
            return []
        }
    }
    
    func deleteTranslation(id: UUID, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<TranslationEntry> = TranslationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let entries = try context.fetch(fetchRequest)
            if let entryToDelete = entries.first {
                context.delete(entryToDelete)
                try context.save()
                print("CoreDataService: Deleted translation with id \(id)")
            } else {
                print("CoreDataService: No translation found with id \(id) to delete.")
            }
        } catch {
            let nsError = error as NSError
            print("CoreDataService: Error deleting translation \(nsError), \(nsError.userInfo)")
        }
    }
}
