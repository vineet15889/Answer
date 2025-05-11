//
//  AnswerTests.swift
//  AnswerTests
//
//  Created by Vineet Rai on 10-May-25.
//

import XCTest
@testable import Answer
import CoreData
import Combine

// MARK: - Mock Translation Service
class MockTranslationService: TranslationServiceProtocol {
    var translateImageShouldThrowError: Error?
    var translateImageReturnValue: TranslationResponse?
    private(set) var translateImageCallCount = 0
    private(set) var lastImagePassedToTranslate: UIImage?
    private(set) var lastTargetLanguagePassed: String?

    func translateImage(_ image: UIImage, targetLanguage: String) async throws -> TranslationResponse {
        translateImageCallCount += 1
        lastImagePassedToTranslate = image
        lastTargetLanguagePassed = targetLanguage

        if let error = translateImageShouldThrowError {
            throw error
        }
        guard let returnValue = translateImageReturnValue else {
            // In a real test, you might want to throw a specific error or use XCTFail
            fatalError("MockTranslationService.translateImageReturnValue was not set.")
        }
        return returnValue
    }
}

// MARK: - Mock CoreData Service
class MockCoreDataService: CoreDataServiceProtocol {
   
    private(set) var saveTranslationCalled = false
    private(set) var fetchAllTranslationsCalled = false
    private(set) var deleteTranslationCalled = false

    private(set) var lastSavedImage: UIImage?
    private(set) var lastSavedDetectedLanguage: String?
    private(set) var lastSavedTranslatedText: String?
    private(set) var lastSavedOriginalText: String?
    private(set) var lastSavedContext: NSManagedObjectContext?

    private(set) var lastFetchAllContext: NSManagedObjectContext?
    var translationsToReturnOnFetch: [Answer.TranslationEntry] = []

    private(set) var lastDeletedId: UUID?
    private(set) var lastDeleteContext: NSManagedObjectContext?
    var deleteShouldSucceed = true


    func saveTranslation(image: UIImage?, detectedLanguage: String, translatedText: String, originalText: String, context: NSManagedObjectContext) {
        saveTranslationCalled = true
        lastSavedImage = image
        lastSavedDetectedLanguage = detectedLanguage
        lastSavedTranslatedText = translatedText
        lastSavedOriginalText = originalText
        lastSavedContext = context
    }


    func fetchAllTranslations(context: NSManagedObjectContext) -> [Answer.TranslationEntry] {
        fetchAllTranslationsCalled = true
        lastFetchAllContext = context
        return translationsToReturnOnFetch
    }

    func deleteTranslation(id: UUID, context: NSManagedObjectContext) {
        deleteTranslationCalled = true
        lastDeletedId = id
        lastDeleteContext = context
        if !deleteShouldSucceed {
            // Simulate a failure if needed, though the protocol doesn't specify throwing
            print("MockCoreDataService: Simulated delete failure for ID \(id)")
        }
    }
}


final class AnswerTests: XCTestCase {

    var mockTranslationService: MockTranslationService!
    var mockCoreDataService: MockCoreDataService!
    var inMemoryPersistenceController: PersistenceController!
    var testViewContext: NSManagedObjectContext!
    private var cancellables: Set<AnyCancellable>!


    override func setUpWithError() throws {
        try super.setUpWithError()
        mockTranslationService = MockTranslationService()
        mockCoreDataService = MockCoreDataService()
        
        inMemoryPersistenceController = PersistenceController(inMemory: true)
        testViewContext = inMemoryPersistenceController.container.viewContext
        
        cancellables = []
    }

    override func tearDownWithError() throws {
        mockTranslationService = nil
        mockCoreDataService = nil
        inMemoryPersistenceController = nil
        testViewContext = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    func createDummyImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    // MARK: - PersistenceController Tests
    func testPersistenceController_saveTranslation() {
        let image = createDummyImage()
        let detectedLang = "English"
        let translatedText = "Hola"
        let originalText = "Hello"

        inMemoryPersistenceController.saveTranslation(
            image: image,
            detectedLanguage: detectedLang,
            translatedText: translatedText,
            originalText: originalText
        )

        let fetchRequest: NSFetchRequest<TranslationEntry> = TranslationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "originalText == %@", originalText)
        
        do {
            let results = try testViewContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "Should find one saved translation.")
            let savedEntry = results.first!
            XCTAssertEqual(savedEntry.detectedLanguage, detectedLang)
            XCTAssertEqual(savedEntry.translatedText, translatedText)
            XCTAssertNotNil(savedEntry.imageData)
        } catch {
            XCTFail("Failed to fetch saved translation: \(error)")
        }
    }

    // MARK: - CoreDataService Tests
    func testCoreDataService_saveTranslation() {
        let service = CoreDataService()
        let image = createDummyImage()
        let lang = "TestLang"
        let translated = "TestTranslated"
        let original = "TestOriginal"

        service.saveTranslation(image: image, detectedLanguage: lang, translatedText: translated, originalText: original, context: testViewContext)

        let fetchRequest: NSFetchRequest<TranslationEntry> = TranslationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "originalText == %@", original)
        do {
            let results = try testViewContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.translatedText, translated)
        } catch {
            XCTFail("Fetching after save failed: \(error)")
        }
    }

    func testCoreDataService_fetchAllTranslations() {
        let service = CoreDataService()
        // Pre-populate data
        let entry1 = TranslationEntry(context: testViewContext)
        entry1.id = UUID()
        entry1.timestamp = Date()
        entry1.originalText = "Original1"
        try! testViewContext.save()

        let results = service.fetchAllTranslations(context: testViewContext)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.originalText, "Original1")
    }

    func testCoreDataService_deleteTranslation() {
        let service = CoreDataService()
        let entryId = UUID()
        let entry = TranslationEntry(context: testViewContext)
        entry.id = entryId
        entry.originalText = "ToDelete"
        try! testViewContext.save()

        service.deleteTranslation(id: entryId, context: testViewContext)

        let fetchRequest: NSFetchRequest<TranslationEntry> = TranslationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", entryId as CVarArg)
        do {
            let results = try testViewContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 0, "Entry should have been deleted.")
        } catch {
            XCTFail("Fetching after delete failed: \(error)")
        }
    }
    
    // MARK: - CameraViewModel Tests
    func testCameraViewModel_init() {
        let viewModel = CameraViewModel(translationService: mockTranslationService, coreDataService: mockCoreDataService)
        XCTAssertNotNil(viewModel)
    }

    func testCameraViewModel_processGalleryImage_success() async {
        let image = createDummyImage()
        let expectedResponse = TranslationResponse(detectedLanguage: "Spanish", translatedText: "Hola", originalText: "Hello")
        mockTranslationService.translateImageReturnValue = expectedResponse
        
        let viewModel = CameraViewModel(translationService: mockTranslationService, coreDataService: mockCoreDataService)
        viewModel.capturedImage = image // Set image first
        
        let expectationLoadingTrue = XCTestExpectation(description: "isLoading becomes true")
        let expectationLoadingFalse = XCTestExpectation(description: "isLoading becomes false")
        let expectationTranslationResult = XCTestExpectation(description: "translationResult is set")

        viewModel.$isLoading.sink { isLoading in
            if isLoading { expectationLoadingTrue.fulfill() }
            else if viewModel.translationResult != nil { expectationLoadingFalse.fulfill() } // after result
        }.store(in: &cancellables)
        
        viewModel.$translationResult.sink { result in
            if result != nil { expectationTranslationResult.fulfill() }
        }.store(in: &cancellables)

        // Process the image
        viewModel.processGalleryImage(image)
        
        await fulfillment(of: [expectationLoadingTrue, expectationTranslationResult, expectationLoadingFalse], timeout: 5.0)

        XCTAssertEqual(mockTranslationService.translateImageCallCount, 1)
        XCTAssertEqual(mockTranslationService.lastImagePassedToTranslate, image)
        XCTAssertEqual(mockTranslationService.lastTargetLanguagePassed, "Spanish") // Default or configured
        XCTAssertEqual(viewModel.translationResult?.translatedText, expectedResponse.translatedText)
        XCTAssertTrue(mockCoreDataService.saveTranslationCalled, "CoreDataService's saveTranslation should be called.")
        XCTAssertEqual(mockCoreDataService.lastSavedDetectedLanguage, expectedResponse.detectedLanguage)
    }

    func testCameraViewModel_processGalleryImage_translationError() async {
        let image = createDummyImage()
        enum MyError: Error { case test }
        mockTranslationService.translateImageShouldThrowError = MyError.test
        
        let viewModel = CameraViewModel(translationService: mockTranslationService, coreDataService: mockCoreDataService)
        
        let expectationShowAlert = XCTestExpectation(description: "showAlert becomes true")
        viewModel.$showAlert.sink { showAlert in
            if showAlert { expectationShowAlert.fulfill() }
        }.store(in: &cancellables)

        viewModel.processGalleryImage(image)
        
        await fulfillment(of: [expectationShowAlert], timeout: 2.0)
        
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.alertTitle, "Translation Error")
        XCTAssertFalse(mockCoreDataService.saveTranslationCalled) // Should not save on error
    }
    
    func testCameraViewModel_capturedImagePublishedAndSaved() {
        let viewModel = CameraViewModel(translationService: mockTranslationService, coreDataService: mockCoreDataService)
        let image = createDummyImage()
        let expectation = XCTestExpectation(description: "capturedImage is published")

        viewModel.$capturedImage
            .dropFirst() // Ignore initial value
            .sink { newImage in
                XCTAssertEqual(newImage, image, "The new image should be the one set.")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.capturedImage = image
        let response = TranslationResponse(detectedLanguage: "Test", translatedText: "Test", originalText: "Test")
        viewModel.translationResult = response

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockCoreDataService.saveTranslationCalled)
        XCTAssertEqual(mockCoreDataService.lastSavedImage, image)
        XCTAssertEqual(mockCoreDataService.lastSavedDetectedLanguage, response.detectedLanguage)
    }


    // MARK: - HistoryViewModel Tests
    func testHistoryViewModel_loadTranslations_empty() {
        let viewModel = HistoryViewModel(context: testViewContext) // Uses the in-memory context
        XCTAssertTrue(viewModel.translations.isEmpty, "Translations should be empty initially if Core Data is empty.")
    }

    func testHistoryViewModel_loadTranslations_withData() {
        let entry = TranslationEntry(context: testViewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.detectedLanguage = "English"
        entry.translatedText = "Hola"
        entry.originalText = "Hello"
        let dummyImageData = createDummyImage().pngData()
        entry.imageData = dummyImageData
        
        try! testViewContext.save()

        let viewModel = HistoryViewModel(context: testViewContext)
        XCTAssertEqual(viewModel.translations.count, 1)
        let item = viewModel.translations.first!
        XCTAssertEqual(item.result.originalText, "Hello")
        XCTAssertEqual(item.result.translatedText, "Hola")
        XCTAssertNotNil(item.image)
    }

    // MARK: - ResultsViewModel Tests
    func testResultsViewModel_init_withData() {
        let image = createDummyImage()
        let translation = TranslationResponse(detectedLanguage: "French", translatedText: "Bonjour", originalText: "Hi")
        let viewModel = ResultsViewModel(image: image, translationResult: translation)

        XCTAssertEqual(viewModel.capturedImage, image)
        XCTAssertEqual(viewModel.detectedLanguage, "French")
        XCTAssertEqual(viewModel.translationResult?.translatedText, "Bonjour")
    }

    func testResultsViewModel_computedProperties() {
        let viewModel = ResultsViewModel(image: nil, translationResult: nil)
        viewModel.detectedLanguage = "German"
        viewModel.confidenceLevel = 85

        XCTAssertEqual(viewModel.languageString, "Language: German")
        XCTAssertEqual(viewModel.confidenceString, "85%")
        XCTAssertEqual(viewModel.confidenceDisplayString, "Confidence: 85%")
    }
    
    func testResultsViewModel_refreshImage() {
        let image = createDummyImage()
        let viewModel = ResultsViewModel(image: image, translationResult: nil)
        
        let expectation = XCTestExpectation(description: "Image is refreshed")
        var nilOccurred = false
        
        viewModel.$capturedImage.sink { img in
            if img == nil {
                nilOccurred = true
            } else if nilOccurred && img != nil {
                XCTAssertEqual(img, image)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        viewModel.refreshImage()
        wait(for: [expectation], timeout: 1.0)
    }

}
