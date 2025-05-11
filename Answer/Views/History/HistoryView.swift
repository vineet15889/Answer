//
//  HistoryView.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.managedObjectContext) private var viewContext

    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: HistoryViewModel(context: context))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                    .padding(.leading, 16)
                    .padding(.vertical, 16)
                    
                    Spacer()
                    
                    Text("Translation History")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                if viewModel.translations.isEmpty {
                    Spacer()
                    Text("No translation history yet")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.translations) { translation in
                            TranslationHistoryCell(translation: translation)
                                .listRowBackground(Color.black)
                                .onTapGesture {
                                    viewModel.selectedTranslation = translation
                                }
                        }
                        .onDelete(perform: deleteItems) // Optional: Add delete functionality
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.black)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .sheet(item: $viewModel.selectedTranslation) { translation in
            ResultsView(
                capturedImage: translation.image,
                translationResult: translation.result,
                navigationPath: .constant(NavigationPath())
            )
            .environment(\.managedObjectContext, self.viewContext) // Pass the environment context
        }
        .onAppear {
            viewModel.loadTranslations()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.translations[$0] }.forEach { itemToDelete in
                let fetchRequest: NSFetchRequest<TranslationEntry> = TranslationEntry.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", itemToDelete.id as CVarArg)
                
                do {
                    let entries = try viewContext.fetch(fetchRequest)
                    if let entryToDelete = entries.first {
                        viewContext.delete(entryToDelete)
                    }
                } catch {
                    print("Error fetching item to delete: \(error)")
                }
            }
            
            do {
                try viewContext.save()
                viewModel.loadTranslations()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct TranslationHistoryCell: View {
    let translation: TranslationHistoryItem
    
    var body: some View {
        HStack(spacing: 16) {
            if let image = translation.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(translation.result.detectedLanguage)
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text(translation.dateFormatted)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
