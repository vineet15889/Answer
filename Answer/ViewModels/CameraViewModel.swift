//
//  CameraViewModel.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import SwiftUI
import AVFoundation
import PhotosUI
import CoreData // Keep CoreData import for NSManagedObjectContext

class CameraViewModel: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var selectedItem: PhotosPickerItem?
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isCapturing = false
    @Published var isLoading = false
    @Published var translationResult: TranslationResponse? {
        didSet {
            if let result = translationResult, let image = capturedImage {
                saveTranslationToCoreData(image: image, result: result, context: PersistenceController.shared.container.viewContext)
            }
        }
    }

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    private let translationService: TranslationServiceProtocol
    private let coreDataService: CoreDataServiceProtocol
    var isSessionSetup = false

    init(translationService: TranslationServiceProtocol = TranslationService(),
         coreDataService: CoreDataServiceProtocol = CoreDataService()) {
        self.translationService = translationService
        self.coreDataService = coreDataService
        super.init()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupSession()
                    }
                }
            }
        default:
            showPermissionAlert()
        }
    }
    
    func setupSession() {
        guard !isSessionSetup else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                DispatchQueue.main.async {
                    self.showCameraSetupErrorAlert()
                }
                return
            }
            
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
            }
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
            self.isSessionSetup = true
        }
    }
    
    func capturePhoto(completion: ((UIImage?) -> Void)? = nil) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isCapturing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                self.isCapturing = false
            }
        }
        
        self.captureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func loadSelectedImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        self.capturedImage = image
                    }
                case .failure:
                    self.showImageLoadErrorAlert()
                }
            }
        }
    }
    
    private func showPermissionAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alertTitle = "Camera Access"
            self.alertMessage = "Please allow camera access in Settings to use this feature."
            self.showAlert = true
        }
    }
    
    private func showCameraSetupErrorAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alertTitle = "Camera Error"
            self.alertMessage = "Unable to setup camera. Please try again."
            self.showAlert = true
        }
    }
    
    private func showImageLoadErrorAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alertTitle = "Image Error"
            self.alertMessage = "Unable to load the selected image."
            self.showAlert = true
        }
    }
    
    private func saveTranslationToCoreData(image: UIImage, result: TranslationResponse, context: NSManagedObjectContext) {
        coreDataService.saveTranslation(
            image: image,
            detectedLanguage: result.detectedLanguage,
            translatedText: result.translatedText,
            originalText: result.originalText,
            context: context
        )
        print("Translation saved via CoreDataService from CameraViewModel.")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.captureCompletion?(nil)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.captureCompletion?(nil)
            }
            return
        }
        
        DispatchQueue.main.async {
            self.captureCompletion?(image)
            self.capturedImage = image
        }
    }
    

    func processGalleryImage(_ image: UIImage) {
        self.capturedImage = image
        self.isLoading = true
        Task {
            do {
                let result = try await translationService.translateImage(
                    image,
                    targetLanguage: "English"
                )
                await MainActor.run {
                    self.translationResult = result
                }
            } catch {
                print("Error translating image: \(error)")
                await MainActor.run {
                    self.isLoading = false
                     self.alertTitle = "Translation Error"
                     self.alertMessage = "Failed to translate the image."
                     self.showAlert = true
                }
            }
        }
    }
}
