import SwiftUI
import PhotosUI
import Vision

struct AddWineView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var wineRegions = WineRegions()
    @StateObject private var suggestionProvider = SuggestionProvider(context: PersistenceController.shared.container.viewContext)
    @ObservedObject var historyService: WineHistoryService
    
    let wineCategories = ["Red", "White", "Rosé", "Sparkling", "Dessert", "Port"]

    @State private var name = ""
    @State private var producer = ""
    @State private var vintage = ""
    @State private var alcohol = ""
    @State private var quantity: Int = 1
    @State private var selectedCategory = "Red"
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var isShowingFrontCamera = false
    @State private var isShowingBackCamera = false
    @State private var price = ""
    @State private var bottleSize = ""
    @State private var readyToTrinkYear = ""
    @State private var bestBeforeYear = ""
    @State private var storageLocation = ""
    @State private var remarks = ""
    @State private var wineRating = ""
    
    @State private var selectedCountry = ""
    @State private var selectedRegion = ""
    @State private var selectedSubregion = ""
    @State private var selectedType = ""
    
    @State private var updatingFromSelection = false
    
    init(historyService: WineHistoryService, copyFrom wine: Wine? = nil) {
        self.historyService = historyService
        
        // When copying a wine's data, initialize all @State properties
        _name = State(initialValue: wine?.name ?? "")
        _producer = State(initialValue: wine?.producer ?? "")
        _vintage = State(initialValue: wine?.vintage ?? "")
        _alcohol = State(initialValue: wine?.alcohol ?? "")
        _quantity = State(initialValue: Int(wine?.quantity ?? 1))
        _selectedCategory = State(initialValue: wine?.category ?? "Red")
        _selectedCountry = State(initialValue: wine?.country ?? "")
        _selectedRegion = State(initialValue: wine?.region ?? "")
        _selectedSubregion = State(initialValue: wine?.subregion ?? "")
        _selectedType = State(initialValue: wine?.type ?? "")
        _price = State(initialValue: wine?.price?.stringValue ?? "")
        
        // Initialize with raw milliliter value, conversion will happen in onAppear
        if let wineBottleSize = wine?.bottleSize {
            _bottleSize = State(initialValue: wineBottleSize)
        } else {
            _bottleSize = State(initialValue: "750ml")
        }
        
        _readyToTrinkYear = State(initialValue: wine?.readyToTrinkYear ?? "")
        _bestBeforeYear = State(initialValue: wine?.bestBeforeYear ?? "")
        _storageLocation = State(initialValue: wine?.storageLocation ?? "")
        _remarks = State(initialValue: wine?.remarks ?? "")
        _wineRating = State(initialValue: wine?.wineRating ?? "")
        
        // When copying a wine, we don't copy the images
        _frontImage = State(initialValue: nil)
        _backImage = State(initialValue: nil)
    }
    
    private func convertBottleSizeOnAppear() {
        // Convert the bottle size to user's preferred unit when the view appears
        if bottleSize.hasSuffix("ml") {
            let mlValue = bottleSize.replacingOccurrences(of: "ml", with: "")
            bottleSize = settings.convertFromMilliliters(mlValue, to: settings.bottleSizeUnit)
        }
    }
    
    private func convertBottleSizeForSaving() -> String {
        // Convert the bottle size back to milliliters for saving
        return settings.convertToMilliliters(bottleSize, from: settings.bottleSizeUnit) + "ml"
    }
    
    var body: some View {
        Form {
            Section(header: Text("Wine Details")) {
                Stepper(value: $quantity, in: 1...99) {
                    Text("Quantity: \(quantity)")
                }
                
                // Wine Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(wineCategories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                AutocompleteTextField(
                    title: "Name",
                    placeholder: "Name",
                    text: $name,
                    suggestionProvider: suggestionProvider,
                    fieldType: .name,
                    keyboardType: .default
                )
                
                AutocompleteTextField(
                    title: "Producer",
                    placeholder: "Producer",
                    text: $producer,
                    suggestionProvider: suggestionProvider,
                    fieldType: .producer,
                    keyboardType: .default
                )
                
                HStack {
                    Text("Vintage")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Vintage (Year)", text: $vintage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Text("Alcohol")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Alcohol", text: $alcohol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    Text("%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Price")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Price", text: $price)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    Text(settings.currencySymbol)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Bottle Size")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Size", text: $bottleSize)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    Text(settings.bottleSizeUnit)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Drink from")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Ready to drink (Year)", text: $readyToTrinkYear)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Text("Best before")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Best before (Year)", text: $bestBeforeYear)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                AutocompleteTextField(
                    title: "Storage",
                    placeholder: "Storage Location",
                    text: $storageLocation,
                    suggestionProvider: suggestionProvider,
                    fieldType: .storageLocation,
                    keyboardType: .default
                )
                
                HStack {
                    Text("Rating")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Wine Rating", text: $wineRating)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Remarks")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                    }
                    TextField("Comments, tasting notes, etc.", text: $remarks, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }

            Section(header: Text("Classification")) {
                Picker("Country", selection: $selectedCountry) {
                    Text("Select Country").tag("")
                    ForEach(wineRegions.countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                .onChange(of: selectedCountry) { _, newValue in
                    if !updatingFromSelection {
                        updatingFromSelection = true
                        if !newValue.isEmpty {
                            wineRegions.updateRegions(for: newValue)
                        } else {
                            // Reset all fields below when "Select Country" is chosen
                            selectedRegion = ""
                            selectedSubregion = ""
                            selectedType = ""
                            wineRegions.resetAllOptions()
                        }
                        updatingFromSelection = false
                    }
                }
                
                Picker("Region", selection: $selectedRegion) {
                    Text("Select Region").tag("")
                    ForEach(wineRegions.regions, id: \.self) { region in
                        Text(region).tag(region)
                    }
                }
                .onChange(of: selectedRegion) { _, newValue in
                    if !updatingFromSelection {
                        updatingFromSelection = true
                        if !newValue.isEmpty {
                            // Only autocomplete country if it's empty
                            if selectedCountry.isEmpty {
                                if let match = wineRegions.findMatchByRegion(newValue) {
                                    selectedCountry = match.country
                                    wineRegions.updateRegions(for: match.country)
                                }
                            }
                            wineRegions.updateSubregions(for: selectedCountry, region: newValue)
                        } else {
                            // Reset all fields below when "Select Region" is chosen
                            selectedSubregion = ""
                            selectedType = ""
                            if !selectedCountry.isEmpty {
                                wineRegions.updateSubregionsForCountry(selectedCountry)
                                wineRegions.updateTypesForCountry(selectedCountry)
                            } else {
                                wineRegions.resetAllOptions()
                            }
                        }
                        updatingFromSelection = false
                    }
                }
                
                Picker("Subregion", selection: $selectedSubregion) {
                    Text("Select Subregion").tag("")
                    ForEach(wineRegions.subregions, id: \.self) { subregion in
                        Text(subregion).tag(subregion)
                    }
                }
                .onChange(of: selectedSubregion) { _, newValue in
                    if !updatingFromSelection {
                        updatingFromSelection = true
                        if !newValue.isEmpty {
                            // Only autocomplete country and region if they are BOTH empty
                            if selectedCountry.isEmpty && selectedRegion.isEmpty {
                                if let match = wineRegions.findMatchBySubregion(newValue) {
                                    selectedCountry = match.country
                                    wineRegions.updateRegions(for: match.country)
                                    selectedRegion = match.region
                                    wineRegions.updateSubregions(for: match.country, region: match.region)
                                }
                            }
                            wineRegions.updateTypes(for: selectedCountry, region: selectedRegion, subregion: newValue)
                        } else {
                            // Reset all fields below when "Select Subregion" is chosen
                            selectedType = ""
                            if !selectedCountry.isEmpty && !selectedRegion.isEmpty {
                                wineRegions.updateTypesForCountryAndRegion(selectedCountry, selectedRegion)
                            } else if !selectedCountry.isEmpty {
                                wineRegions.updateTypesForCountry(selectedCountry)
                            } else {
                                wineRegions.resetAllOptions()
                            }
                        }
                        updatingFromSelection = false
                    }
                }
                
                Picker("Type", selection: $selectedType) {
                    Text("Select Type").tag("")
                    ForEach(wineRegions.types, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .onChange(of: selectedType) { _, newValue in
                    if !updatingFromSelection {
                        updatingFromSelection = true
                        if !newValue.isEmpty {
                            // Only autocomplete country, region, and subregion if they are ALL empty
                            if selectedCountry.isEmpty && selectedRegion.isEmpty && selectedSubregion.isEmpty {
                                if let match = wineRegions.findMatchByType(newValue) {
                                    selectedCountry = match.country
                                    wineRegions.updateRegions(for: match.country)
                                    selectedRegion = match.region
                                    wineRegions.updateSubregions(for: match.country, region: match.region)
                                    selectedSubregion = match.subregion
                                    wineRegions.updateTypes(for: match.country, region: match.region, subregion: match.subregion)
                                }
                            }
                        }
                        updatingFromSelection = false
                    }
                }
            }

            Section(header: Text("Photos")) {
                HStack(spacing: 15) {
                    Image(systemName: "camera")
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        if let image = frontImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                            Button(action: { frontImage = nil }) {
                                Text("Delete")
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button(action: { isShowingFrontCamera = true }) {
                                Text("Front Label")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 8) {
                        if let image = backImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                            Button(action: { backImage = nil }) {
                                Text("Delete")
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button(action: { isShowingBackCamera = true }) {
                                Text("Back Label")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Add Wine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    do {
                        addWine()
                        try viewContext.save()
                        dismiss()
                    } catch {
                        print("Error saving new wine: \(error)")
                    }
                }
                .disabled(name.isEmpty)
            }
        }
        .sheet(isPresented: $isShowingFrontCamera) {
            ImagePicker(image: $frontImage, sourceType: .camera, onImageSelected: { image in
                if let image = image, areAllFieldsEmpty() {
                    extractWineInfo(from: image)
                }
            })
        }
        .sheet(isPresented: $isShowingBackCamera) {
            ImagePicker(image: $backImage, sourceType: .camera, onImageSelected: { image in
                if let image = image, areAllFieldsEmpty() {
                    extractWineInfo(from: image)
                }
            })
        }
        .onAppear {
            // Convert bottle size to the user's preferred unit when the view appears
            convertBottleSizeOnAppear()
        }
    }

    private func addWine() {
        let newWine = Wine(context: viewContext)
        newWine.id = UUID()
        newWine.name = name
        newWine.producer = producer
        newWine.vintage = vintage
        newWine.alcohol = alcohol
        newWine.quantity = Int16(quantity)
        newWine.country = selectedCountry
        newWine.region = selectedRegion
        newWine.subregion = selectedSubregion
        newWine.type = selectedType
        newWine.category = selectedCategory
        newWine.price = NSDecimalNumber(string: price.isEmpty ? "0" : price)
        // Ensure the bottle size is saved in milliliters
        newWine.bottleSize = convertBottleSizeForSaving()
        newWine.readyToTrinkYear = readyToTrinkYear
        newWine.bestBeforeYear = bestBeforeYear
        newWine.storageLocation = storageLocation
        newWine.remarks = remarks
        newWine.wineRating = wineRating
        
        if let frontImage = frontImage, let data = frontImage.jpegData(compressionQuality: 0.8) {
            newWine.frontImageData = data
        }
        
        if let backImage = backImage, let data = backImage.jpegData(compressionQuality: 0.8) {
            newWine.backImageData = data
        }
        
        // Log the wine addition to history
        historyService.logWineAdded(wine: newWine)
    }
    
    private func areAllFieldsEmpty() -> Bool {
        // Check if bottle size is at default value (750 in any unit)
        let bottleSizeIsDefault = bottleSize.isEmpty || 
                                 bottleSize == "750" || 
                                 bottleSize == "75" || 
                                 bottleSize == "7.5" || 
                                 bottleSize == "0.75"
        
        return name.isEmpty &&
               producer.isEmpty &&
               vintage.isEmpty &&
               alcohol.isEmpty &&
               selectedCategory == "Red" && // Default value
               selectedCountry.isEmpty &&
               selectedRegion.isEmpty &&
               selectedSubregion.isEmpty &&
               selectedType.isEmpty &&
               price.isEmpty &&
               bottleSizeIsDefault &&
               readyToTrinkYear.isEmpty &&
               bestBeforeYear.isEmpty &&
               storageLocation.isEmpty &&
               remarks.isEmpty &&
               wineRating.isEmpty
    }

    private func extractWineInfo(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: " ")
            
            // Extract relevant information using pattern matching
            DispatchQueue.main.async { [self] in
                // Try to find wine name (usually first line with letters)
                if let wineName = recognizedStrings.first(where: { $0.range(of: "[A-Za-z\\s]{3,}", options: .regularExpression) != nil }) {
                    name = wineName.trimmingCharacters(in: .whitespaces)
                }
                
                // Try to find producer
                if let producerName = recognizedStrings.dropFirst().first(where: { $0.range(of: "[A-Za-z\\s]{3,}", options: .regularExpression) != nil }) {
                    producer = producerName.trimmingCharacters(in: .whitespaces)
                }
                
                // Try to find vintage (4 digit year)
                if let yearMatch = recognizedStrings.first(where: { $0.range(of: "\\b(19|20)\\d{2}\\b", options: .regularExpression) != nil }) {
                    vintage = yearMatch.trimmingCharacters(in: .whitespaces)
                }
                
                // Try to find alcohol percentage
                if let alcoholMatch = recognizedStrings.first(where: { $0.range(of: "\\d{1,2}(\\.\\d)?\\s?%|ALC", options: [.regularExpression, .caseInsensitive]) != nil }) {
                    alcohol = alcoholMatch.trimmingCharacters(in: .whitespaces)
                }
                
                // Try to infer wine category from the text
                let lowercaseText = fullText.lowercased()
                if lowercaseText.contains("sparkling") || lowercaseText.contains("champagne") || lowercaseText.contains("prosecco") || lowercaseText.contains("cava") {
                    selectedCategory = "Sparkling"
                } else if lowercaseText.contains("rosé") || lowercaseText.contains("rose") || lowercaseText.contains("blush") {
                    selectedCategory = "Rosé"
                } else if lowercaseText.contains("white") || lowercaseText.contains("blanc") || lowercaseText.contains("chardonnay") || lowercaseText.contains("riesling") || lowercaseText.contains("sauvignon") {
                    selectedCategory = "White"
                } else if lowercaseText.contains("red") || lowercaseText.contains("rouge") || lowercaseText.contains("noir") || lowercaseText.contains("cabernet") || lowercaseText.contains("merlot") || lowercaseText.contains("syrah") || lowercaseText.contains("shiraz") {
                    selectedCategory = "Red"
                } else if lowercaseText.contains("dessert") || lowercaseText.contains("sweet") || lowercaseText.contains("ice wine") || lowercaseText.contains("sauternes") {
                    selectedCategory = "Dessert"
                } else if lowercaseText.contains("port") || lowercaseText.contains("porto") || lowercaseText.contains("fortified") {
                    selectedCategory = "Port"
                }
                
                // Try to match wine regions
                let matches = wineRegions.findMatches(in: fullText)
                if let country = matches.country {
                    selectedCountry = country
                    wineRegions.updateRegions(for: country)
                    
                    if let region = matches.region {
                        selectedRegion = region
                        wineRegions.updateSubregions(for: country, region: region)
                        
                        if let subregion = matches.subregion {
                            selectedSubregion = subregion
                            wineRegions.updateTypes(for: country, region: region, subregion: subregion)
                            
                            if let type = matches.type {
                                selectedType = type
                            }
                        }
                    }
                }
            }
        }
        
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}
