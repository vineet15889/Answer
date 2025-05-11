//
//  AnswerApp.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import SwiftUI

@main
struct AnswerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CameraView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
