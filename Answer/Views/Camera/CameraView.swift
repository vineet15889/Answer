//
//  CameraView.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var showBriefImage = false
    @State private var briefImage: UIImage?
    @State private var showImagePicker = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                CameraPreviewView(session: viewModel.session)
                    .edgesIgnoringSafeArea(.all)
                    .scaleEffect(viewModel.isCapturing ? 0.95 : 1.0)
                    .brightness(viewModel.isCapturing ? 0.3 : 0)
                
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(.leading, 30)
                        Spacer()
                        Button(action: {
                            viewModel.capturePhoto { image in
                                // Store the captured image and show loading screen
                                if let capturedImage = image {
                                    briefImage = capturedImage
                                    withAnimation {
                                        viewModel.isLoading = true
                                    }
                                    processImageAndNavigate(capturedImage)
                                }
                            }
                        }) {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            navigationPath.append("history")
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(.trailing, 30)
                    }
                    .padding(.bottom, 30)
                }
                if viewModel.isLoading {
                    MeshGradientLoadingView()
                        .transition(.opacity)
                }
                
                if let image = viewModel.capturedImage, !viewModel.isLoading && !showBriefImage {
                    Color.black.edgesIgnoringSafeArea(.all)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .onAppear {
                viewModel.checkPermissions()
                viewModel.setupSession()
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .animation(.easeInOut, value: viewModel.isLoading)
            .animation(.easeInOut, value: viewModel.capturedImage)
            .animation(.easeInOut, value: showBriefImage)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: { image in
                    // Handle the selected image
                    briefImage = image
                    showImagePicker = false
                    
                    withAnimation {
                        viewModel.isLoading = true
                    }
                    
                    processImageAndNavigate(image)
                })
            }
            .navigationDestination(for: String.self) { route in
                if route == "results" {
                    ResultsView(capturedImage: briefImage, translationResult: viewModel.translationResult, navigationPath: $navigationPath)
                } else if route == "history" {
                    HistoryView()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func processImageAndNavigate(_ image: UIImage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                viewModel.translationResult = TranslationResponse(
                    detectedLanguage: "English",
                    translatedText: "I can't directly execute or verify external API calls like curl in real time, but I can review your curl command and confirm if it looks correct based on standard structure.I can't directly execute or verify external API calls like curl in real time, but I can review your curl command and confirm if it looks correct based on standard structure.", originalText: "Sample text for testing"
                )
                
                viewModel.isLoading = false
                navigationPath.append("results")
                viewModel.capturedImage = nil
            }
        }
        
        /* ORIGINAL CODE - Uncomment when ready to use the real API
        // Process the image using the view model
        viewModel.processGalleryImage(image)
        
        // Use a Task to monitor the translation result
        Task {
            // Wait for the translation result to be available
            while viewModel.translationResult == nil && viewModel.isLoading {
                try? await Task.sleep(nanoseconds: 500_000_000) // Check every 0.5 seconds
            }
            
            // If we have a result, navigate to the results screen
            if viewModel.translationResult != nil {
                await MainActor.run {
                    withAnimation {
                        viewModel.isLoading = false
                        navigationPath.append("results")
                        viewModel.capturedImage = nil
                    }
                }
            }
        }
        */
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
