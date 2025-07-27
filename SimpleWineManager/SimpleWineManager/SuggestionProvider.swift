import Foundation
import CoreData
import SwiftUI
import Combine

class SuggestionProvider: ObservableObject {
    @Published var nameSuggestions: [String] = []
    @Published var producerSuggestions: [String] = []
    @Published var locationSuggestions: [String] = []
    
    private var context: NSManagedObjectContext
    private var nameCancellable: AnyCancellable?
    private var producerCancellable: AnyCancellable?
    private var locationCancellable: AnyCancellable?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getSuggestions(for field: FieldType, text: String) {
        // Only fetch suggestions if we have at least 1 character
        guard text.count >= 1 else {
            clearSuggestions(for: field)
            return
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Wine")
        let attribute = field.rawValue
        
        // Case insensitive search with prefix matching
        let predicate = NSPredicate(format: "%K BEGINSWITH[cd] %@", attribute, text)
        fetchRequest.predicate = predicate
        
        // We need distinct values
        fetchRequest.propertiesToFetch = [attribute]
        fetchRequest.returnsDistinctResults = true
        fetchRequest.resultType = .dictionaryResultType
        
        do {
            let results = try context.fetch(fetchRequest) as? [[String: Any]] ?? []
            let uniqueValues = Set(results.compactMap { $0[attribute] as? String })
                .filter { !$0.isEmpty }
                .sorted()
                .prefix(5) // Limit to 5 suggestions
            
            switch field {
            case .name:
                nameSuggestions = Array(uniqueValues)
            case .producer:
                producerSuggestions = Array(uniqueValues)
            case .storageLocation:
                locationSuggestions = Array(uniqueValues)
            }
        } catch {
            print("Error fetching suggestions: \(error)")
        }
    }
    
    func clearSuggestions(for field: FieldType) {
        switch field {
        case .name:
            nameSuggestions = []
        case .producer:
            producerSuggestions = []
        case .storageLocation:
            locationSuggestions = []
        }
    }
    
    func clearAllSuggestions() {
        nameSuggestions = []
        producerSuggestions = []
        locationSuggestions = []
    }
    
    enum FieldType: String {
        case name
        case producer
        case storageLocation
    }
}

struct AutocompleteSuggestionView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: {
                    onSelect(suggestion)
                }) {
                    HStack {
                        Text(suggestion)
                            .foregroundColor(.primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(UIColor.systemBackground))
                
                if suggestion != suggestions.last {
                    Divider()
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct AutocompleteTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @ObservedObject var suggestionProvider: SuggestionProvider
    let fieldType: SuggestionProvider.FieldType
    let keyboardType: UIKeyboardType
    
    @State private var isFocused: Bool = false
    @State private var isSelectingSuggestion: Bool = false
    @FocusState private var textFieldFocused: Bool
    
    private var suggestions: [String] {
        switch fieldType {
        case .name:
            return suggestionProvider.nameSuggestions
        case .producer:
            return suggestionProvider.producerSuggestions
        case .storageLocation:
            return suggestionProvider.locationSuggestions
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
                
                TextField(placeholder, text: $text, onEditingChanged: { focused in
                    isFocused = focused
                    if !focused {
                        // Clear suggestions when we leave the field
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if !isSelectingSuggestion {
                                suggestionProvider.clearSuggestions(for: fieldType)
                            }
                        }
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .focused($textFieldFocused)
                .onChange(of: text) { _, newValue in
                    // Only get suggestions if we're not currently selecting a suggestion
                    if !isSelectingSuggestion {
                        suggestionProvider.getSuggestions(for: fieldType, text: newValue)
                    }
                }
                .onChange(of: textFieldFocused) { _, focused in
                    isFocused = focused
                    if !focused && !isSelectingSuggestion {
                        suggestionProvider.clearSuggestions(for: fieldType)
                    }
                }
            }
            
            if !suggestions.isEmpty && isFocused {
                AutocompleteSuggestionView(suggestions: suggestions) { selectedValue in
                    isSelectingSuggestion = true
                    text = selectedValue
                    textFieldFocused = false
                    suggestionProvider.clearSuggestions(for: fieldType)
                    
                    // Reset the flag after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSelectingSuggestion = false
                    }
                }
                .padding(.top, 4)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: suggestions)
            }
        }
    }
}
