import Foundation
import CoreData
import UIKit

protocol CoreDataServiceProtocol {
    func saveTranslation(image: UIImage?, detectedLanguage: String, translatedText: String, originalText: String, context: NSManagedObjectContext)
    func fetchAllTranslations(context: NSManagedObjectContext) -> [TranslationEntry]
    func deleteTranslation(id: UUID, context: NSManagedObjectContext)
}