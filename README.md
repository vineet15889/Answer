# Photo Translator iOS

A native SwiftUI app for iOS 17+ that allows users to capture or select a photo containing text, translate it using an AI-powered endpoint, and view the results in an elegant and animated UI.

## Features

-  Live camera feed using `AVCaptureSession`
-  Capture animation
-  Upload image to a translation endpoint
-  Displays detected language, original text, and translated text
-  History screen to view past translations
-  Unit tests

## Pattern: MVVM (Model-View-ViewModel)

The app follows a clean MVVM structure for better separation of concerns, testability, and scalability.

📁 AnswerApp
├── 📁 Views            // SwiftUI screens: CameraView, ResultView, HistoryView
├── 📁 ViewModels       // View logic and business rules
├── 📁 Models           // Codable models for request/response
├── 📁 Services         // API clients and utility services
├── 📁 ServerConfig     // Server end-point
├── 📁 AnswerTests     // XCTest case / Unit test


##  Setup & Run

### Requirements

- Xcode 16+
- iOS 17+ SDK
- Swift 5.5+

### Setup Instructions

1. Clone the repo:
   ```bash
   git clone https://github.com/vineet15889/Answer.git
2. Run using real device (due to camera) using xcode 16+

### Screenshots / Media

##  Camera flow
https://github.com/user-attachments/assets/37f55fe9-47d5-4229-acfe-5a9d6108b35f

##  Gallery flow
https://github.com/user-attachments/assets/a39b87d7-e122-4383-aa90-de4a78168bf5

##  History Screen 
https://github.com/user-attachments/assets/a233104c-2599-4acb-b072-c12d98a818f7





