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
                viewModel.translationResult = nil
                viewModel.capturedImage = nil
                briefImage = nil
                viewModel.isLoading = false
                if viewModel.isSessionSetup && !viewModel.session.isRunning {
                    viewModel.session.startRunning()
                    viewModel.isCapturing = true
                } else if !viewModel.isSessionSetup {
                    viewModel.setupSession()
                }
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
                    viewModel.translationResult = nil
                    viewModel.capturedImage = nil
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
        // Ensure previous results are cleared before starting a new translation
        // This is an additional safeguard, though resetting in .onAppear and selection handlers is primary.
        viewModel.translationResult = nil
        
        viewModel.processGalleryImage(image) // This will set viewModel.capturedImage and trigger translation
        Task {
            // Wait for translationResult to be populated by the ViewModel
            // This loop relies on processGalleryImage eventually setting translationResult
            var attempts = 0
            let maxAttempts = 20 // e.g., 10 seconds if sleep is 0.5s
            while viewModel.translationResult == nil && viewModel.isLoading && attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: 500_000_000) // Check every 0.5 seconds
                attempts += 1
            }
            
            // Ensure UI updates are on the main thread
            await MainActor.run {
                withAnimation {
                    viewModel.isLoading = false // Stop loading indicator
                    if viewModel.translationResult != nil {
                        navigationPath.append("results")
                    } else {
                        // Handle timeout or error if translationResult is still nil
                        viewModel.alertTitle = "Translation Failed"
                        viewModel.alertMessage = "Could not get translation results. Please try again."
                        viewModel.showAlert = true
                    }
                    // Clear the full-screen preview image from CameraView *after* navigating or showing an alert
                    viewModel.capturedImage = nil
                }
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
