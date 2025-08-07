import SwiftUI
import Vision
import UIKit

struct WineDetailView: View {
    @ObservedObject var wine: Wine
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var historyService = WineHistoryService(context: PersistenceController.shared.container.viewContext)
    
    let wineCategories = ["Red", "White", "Rosé", "Sparkling", "Dessert", "Port"]
    
    @State private var consumeAmount = 1
    @State private var isEditing = false
    @State private var isShowingCopySheet = false
    @StateObject private var wineRegions = WineRegions()
    @StateObject private var suggestionProvider = SuggestionProvider(context: PersistenceController.shared.container.viewContext)
    @State private var selectedImage: UIImage?
    @State private var isShowingFullScreen = false
    
    // MARK: - Editing state
    @State private var editName: String = ""
    @State private var editProducer: String = ""
    @State private var editVintage: String = ""
    @State private var editAlcohol: String = ""
    @State private var editQuantity: Int = 1
    @State private var editCategory: String = ""
    @State private var editCountry: String = ""
    @State private var editRegion: String = ""
    @State private var editSubregion: String = ""
    @State private var editType: String = ""
    @State private var editPrice: String = ""
    @State private var editBottleSize: String = ""
    @State private var editReadyToTrinkYear: String = ""
    @State private var editBestBeforeYear: String = ""
    @State private var editStorageLocation: String = ""
    @State private var editRemarks: String = ""
    @State private var editWineRating: String = ""
    @State private var editFrontImage: UIImage?
    @State private var editBackImage: UIImage?
    @State private var isShowingFrontCamera = false
    @State private var isShowingBackCamera = false
    @State private var updatingFromSelection = false
    
    private func setupEditingState() {
        editName = wine.name ?? ""
        editProducer = wine.producer ?? ""
        editVintage = wine.vintage ?? ""
        editAlcohol = wine.alcohol ?? ""
        editQuantity = Int(wine.quantity)
        editCategory = wine.category ?? ""
        editCountry = wine.country ?? ""
        editRegion = wine.region ?? ""
        editSubregion = wine.subregion ?? ""
        editType = wine.type ?? ""
        editPrice = wine.price?.stringValue ?? ""
        
        // Convert stored ml value to user's preferred unit for editing
        if let bottleSize = wine.bottleSize {
            let mlValue = bottleSize.replacingOccurrences(of: "ml", with: "")
            editBottleSize = settings.convertFromMilliliters(mlValue, to: settings.bottleSizeUnit)
        } else {
            editBottleSize = ""
        }
        
        editReadyToTrinkYear = wine.readyToTrinkYear ?? ""
        editBestBeforeYear = wine.bestBeforeYear ?? ""
        editStorageLocation = wine.storageLocation ?? ""
        
        if let frontImageData = wine.frontImageData {
            editFrontImage = UIImage(data: frontImageData)
        }
        if let backImageData = wine.backImageData {
            editBackImage = UIImage(data: backImageData)
        }
        
        // Initialize wine regions
        if !editCountry.isEmpty {
            wineRegions.updateRegions(for: editCountry)
            if !editRegion.isEmpty {
                wineRegions.updateSubregions(for: editCountry, region: editRegion)
                if !editSubregion.isEmpty {
                    wineRegions.updateTypes(for: editCountry, region: editRegion, subregion: editSubregion)
                }
            }
        }
    }
    
    // MARK: - Body View
    var body: some View {
        Group {
            if isEditing {
                editingContent
                    .navigationTitle("Edit Wine")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        viewingContent
                    }
                    .padding()
                }
                .navigationTitle(wine.name ?? "Wine Details")
            }
        }
        .toolbar {
            if isEditing {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            } else {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Copy") {
                        isShowingCopySheet = true
                    }
                    Button("Edit") {
                        startEditing()
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCopySheet) {
            NavigationView {
                AddWineView(historyService: historyService, copyFrom: wine)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(settings)
            }
        }
        .sheet(isPresented: $isShowingFrontCamera) {
            ImagePicker(image: $editFrontImage, sourceType: .camera, onImageSelected: { _ in })
        }
        .sheet(isPresented: $isShowingBackCamera) {
            ImagePicker(image: $editBackImage, sourceType: .camera, onImageSelected: { _ in })
        }
        .overlay {
            if isShowingFullScreen, let image = selectedImage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation {
                                isShowingFullScreen = false
                            }
                        }
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    isShowingFullScreen = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Editing Content
    private var editingContent: some View {
        Form {
            Section(header: Text("Wine Details")) {
                Stepper(value: $editQuantity, in: 0...999) {
                    Text("Quantity: \(editQuantity)")
                }
                
                // Wine Category Picker
                Picker("Category", selection: $editCategory) {
                    ForEach(wineCategories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                AutocompleteTextField(
                    title: "Name",
                    placeholder: "Name",
                    text: $editName,
                    suggestionProvider: suggestionProvider,
                    fieldType: .name,
                    keyboardType: .default
                )
                
                AutocompleteTextField(
                    title: "Producer",
                    placeholder: "Producer",
                    text: $editProducer,
                    suggestionProvider: suggestionProvider,
                    fieldType: .producer,
                    keyboardType: .default
                )
                
                HStack {
                    Text("Vintage")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Vintage (Year)", text: $editVintage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Text("Alcohol")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Alcohol", text: $editAlcohol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    Text("%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Price")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Price", text: $editPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    Text(settings.currencySymbol)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Bottle Size")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Size", text: $editBottleSize)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    Text(settings.bottleSizeUnit)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Drink from")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Ready to drink (Year)", text: $editReadyToTrinkYear)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Text("Best before")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Best before (Year)", text: $editBestBeforeYear)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                AutocompleteTextField(
                    title: "Storage",
                    placeholder: "Storage Location",
                    text: $editStorageLocation,
                    suggestionProvider: suggestionProvider,
                    fieldType: .storageLocation,
                    keyboardType: .default
                )
                
                HStack {
                    Text("Rating")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Wine Rating", text: $editWineRating)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Remarks")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                    }
                    TextEditor(text: $editRemarks)
                        .frame(minHeight: 60, maxHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }

            Section(header: Text("Classification")) {
                Picker("Country", selection: $editCountry) {
                    Text("Select Country").tag("")
                    ForEach(wineRegions.countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                
                Picker("Region", selection: $editRegion) {
                    Text("Select Region").tag("")
                    ForEach(wineRegions.regions, id: \.self) { region in
                        Text(region).tag(region)
                    }
                }
                
                Picker("Subregion", selection: $editSubregion) {
                    Text("Select Subregion").tag("")
                    ForEach(wineRegions.subregions, id: \.self) { subregion in
                        Text(subregion).tag(subregion)
                    }
                }
                
                Picker("Type", selection: $editType) {
                    Text("Select Type").tag("")
                    ForEach(wineRegions.types, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            }

            Section(header: Text("Photos")) {
                HStack(spacing: 15) {
                    Image(systemName: "camera")
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        if let image = editFrontImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedImage = image
                                    withAnimation {
                                        isShowingFullScreen = true
                                    }
                                }
                            Button(action: { editFrontImage = nil }) {
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
                        if let image = editBackImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedImage = image
                                    withAnimation {
                                        isShowingFullScreen = true
                                    }
                                }
                            Button(action: { editBackImage = nil }) {
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
        .onAppear {
            setupEditingState()
        }
        .onChange(of: editCountry) { oldValue, newValue in
            if !updatingFromSelection {
                updatingFromSelection = true
                if !newValue.isEmpty {
                    wineRegions.updateRegions(for: newValue)
                } else {
                    // Reset all fields below when "Select Country" is chosen
                    editRegion = ""
                    editSubregion = ""
                    editType = ""
                    wineRegions.resetAllOptions()
                }
                updatingFromSelection = false
            }
        }
        .onChange(of: editRegion) { oldValue, newValue in
            if !updatingFromSelection {
                updatingFromSelection = true
                if !newValue.isEmpty {
                    // Only autocomplete country if it's empty
                    if editCountry.isEmpty {
                        if let match = wineRegions.findMatchByRegion(newValue) {
                            editCountry = match.country
                            wineRegions.updateRegions(for: match.country)
                        }
                    }
                    wineRegions.updateSubregions(for: editCountry, region: newValue)
                } else {
                    // Reset all fields below when "Select Region" is chosen
                    editSubregion = ""
                    editType = ""
                    if !editCountry.isEmpty {
                        wineRegions.updateSubregionsForCountry(editCountry)
                        wineRegions.updateTypesForCountry(editCountry)
                    } else {
                        wineRegions.resetAllOptions()
                    }
                }
                updatingFromSelection = false
            }
        }
        .onChange(of: editSubregion) { oldValue, newValue in
            if !updatingFromSelection {
                updatingFromSelection = true
                if !newValue.isEmpty {
                    // Only autocomplete country and region if they are BOTH empty
                    if editCountry.isEmpty && editRegion.isEmpty {
                        if let match = wineRegions.findMatchBySubregion(newValue) {
                            editCountry = match.country
                            wineRegions.updateRegions(for: match.country)
                            editRegion = match.region
                            wineRegions.updateSubregions(for: match.country, region: match.region)
                        }
                    }
                    wineRegions.updateTypes(for: editCountry, region: editRegion, subregion: newValue)
                } else {
                    // Reset all fields below when "Select Subregion" is chosen
                    editType = ""
                    if !editCountry.isEmpty && !editRegion.isEmpty {
                        wineRegions.updateTypesForCountryAndRegion(editCountry, editRegion)
                    } else if !editCountry.isEmpty {
                        wineRegions.updateTypesForCountry(editCountry)
                    } else {
                        wineRegions.resetAllOptions()
                    }
                }
                updatingFromSelection = false
            }
        }
        .onChange(of: editType) { oldValue, newValue in
            if !updatingFromSelection {
                updatingFromSelection = true
                if !newValue.isEmpty {
                    // Only autocomplete country, region, and subregion if they are ALL empty
                    if editCountry.isEmpty && editRegion.isEmpty && editSubregion.isEmpty {
                        if let match = wineRegions.findMatchByType(newValue) {
                            editCountry = match.country
                            wineRegions.updateRegions(for: match.country)
                            editRegion = match.region
                            wineRegions.updateSubregions(for: match.country, region: match.region)
                            editSubregion = match.subregion
                            wineRegions.updateTypes(for: match.country, region: match.region, subregion: match.subregion)
                        }
                    }
                }
                updatingFromSelection = false
            }
        }
    }
    
    // MARK: - Viewing Content
    private var viewingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Consume Wine Section at the top
            if wine.quantity > 0 {
                HStack {
                    Stepper("Quantity: \(consumeAmount)", value: $consumeAmount, in: 1...max(1, Int(wine.quantity)))
                    Button("Consume") {
                        consumeWine()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("No bottles available")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Wine Details
            Group {
                DetailRow(label: "Name", value: wine.name ?? "")
                DetailRow(label: "Producer", value: wine.producer ?? "")
                DetailRow(label: "Vintage", value: wine.vintage ?? "")
                if let alcohol = wine.alcohol, !alcohol.isEmpty {
                    DetailRow(label: "Alcohol", value: "\(alcohol)%")
                }
                DetailRow(label: "Quantity", value: "\(wine.quantity)")
                DetailRow(label: "Category", value: wine.category ?? "")
                DetailRow(label: "Country", value: wine.country ?? "")
                DetailRow(label: "Region", value: wine.region ?? "")
                DetailRow(label: "Subregion", value: wine.subregion ?? "")
                DetailRow(label: "Type", value: wine.type ?? "")
                if let price = wine.price, price != 0 {
                    DetailRow(label: "Price", value: "\(price)\(settings.currencySymbol)")
                }
                if let bottleSize = wine.bottleSize {
                    DetailRow(label: "Bottle Size", value: settings.getDisplayBottleSize(bottleSize))
                }
                DetailRow(label: "Ready to drink", value: wine.readyToTrinkYear ?? "")
                DetailRow(label: "Best before", value: wine.bestBeforeYear ?? "")
                DetailRow(label: "Storage", value: wine.storageLocation ?? "")
                DetailRow(label: "Rating", value: wine.wineRating ?? "")
                if let remarks = wine.remarks, !remarks.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Remarks")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        Text(remarks)
                            .bold()
                    }
                }
            }
            
            Divider()
            
            // Wine Images at the bottom
            HStack(spacing: 15) {
                if let frontImageData = wine.frontImageData,
                   let frontImage = UIImage(data: frontImageData) {
                    Image(uiImage: frontImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(8)
                        .onTapGesture {
                            withAnimation {
                                selectedImage = frontImage
                                isShowingFullScreen = true
                            }
                        }
                }
                
                if let backImageData = wine.backImageData,
                   let backImage = UIImage(data: backImageData) {
                    Image(uiImage: backImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(8)
                        .onTapGesture {
                            withAnimation {
                                selectedImage = backImage
                                isShowingFullScreen = true
                            }
                        }
                }
            }
        }
    }

    private func startEditing() {
        editName = wine.name ?? ""
        editProducer = wine.producer ?? ""
        editVintage = wine.vintage ?? ""
        editAlcohol = wine.alcohol ?? ""
        editQuantity = Int(wine.quantity)
        editCategory = wine.category ?? ""
        editCountry = wine.country ?? ""
        editRegion = wine.region ?? ""
        editSubregion = wine.subregion ?? ""
        editType = wine.type ?? ""
        editPrice = wine.price?.stringValue ?? ""
        // Remove unit from bottleSize when editing
        editBottleSize = (wine.bottleSize ?? "")
            .replacingOccurrences(of: "ml", with: "")
            .replacingOccurrences(of: "dl", with: "")
            .replacingOccurrences(of: "cl", with: "")
            .replacingOccurrences(of: "l", with: "")
        editReadyToTrinkYear = wine.readyToTrinkYear ?? ""
        editBestBeforeYear = wine.bestBeforeYear ?? ""
        editStorageLocation = wine.storageLocation ?? ""
        editRemarks = wine.remarks ?? ""
        editWineRating = wine.wineRating ?? ""
        
        if let frontData = wine.frontImageData {
            editFrontImage = UIImage(data: frontData)
        }
        if let backData = wine.backImageData {
            editBackImage = UIImage(data: backData)
        }
        
        // Setup wine regions
        if !editCountry.isEmpty {
            wineRegions.updateRegions(for: editCountry)
            if !editRegion.isEmpty {
                wineRegions.updateSubregions(for: editCountry, region: editRegion)
                if !editSubregion.isEmpty {
                    wineRegions.updateTypes(for: editCountry, region: editRegion, subregion: editSubregion)
                }
            }
        }
        
        isEditing = true
    }
    
    private func saveChanges() {
        // Update the managed object
        wine.name = editName
        wine.producer = editProducer
        wine.vintage = editVintage
        wine.alcohol = editAlcohol
        wine.quantity = Int16(editQuantity)
        wine.category = editCategory
        wine.country = editCountry
        wine.region = editRegion
        wine.subregion = editSubregion
        wine.type = editType
        wine.price = NSDecimalNumber(string: editPrice.isEmpty ? "0" : editPrice)
        // Ensure the bottle size is saved in milliliters
        let mlValue = settings.convertToMilliliters(editBottleSize, from: settings.bottleSizeUnit)
        wine.bottleSize = "\(mlValue)ml"
        wine.readyToTrinkYear = editReadyToTrinkYear
        wine.bestBeforeYear = editBestBeforeYear
        wine.storageLocation = editStorageLocation
        wine.remarks = editRemarks
        wine.wineRating = editWineRating
        
        // Handle front image updates and deletions
        if let frontImage = editFrontImage {
            wine.frontImageData = frontImage.jpegData(compressionQuality: 0.8)
        } else {
            wine.frontImageData = nil
        }
        
        // Handle back image updates and deletions
        if let backImage = editBackImage {
            wine.backImageData = backImage.jpegData(compressionQuality: 0.8)
        } else {
            wine.backImageData = nil
        }
        
        do {
            // Save the changes
            try viewContext.save()
            
            // Log the wine edit to history
            historyService.logWineEdited(wine: wine)
            
            // Ensure the wine object is fully updated
            viewContext.refresh(wine, mergeChanges: true)
            
            // Force UI update for this object
            wine.objectWillChange.send()
            
            // Notify parent views that they should refresh
            NotificationCenter.default.post(name: NSNotification.Name("WineDataDidChange"), object: nil)
            
            isEditing = false
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func cancelEditing() {
        isEditing = false
        viewContext.refresh(wine, mergeChanges: false)
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
                    editName = wineName.trimmingCharacters(in: .whitespaces)
                }
                
                // Try to find producer
                if let producerName = recognizedStrings.dropFirst().first(where: { $0.range(of: "[A-Za-z\\s]{3,}", options: .regularExpression) != nil }) {
                    editProducer = producerName.trimmingCharacters(in: .whitespaces)
                }
                
                // Try to find vintage (4 digit year)
                if let yearMatch = recognizedStrings.first(where: { $0.range(of: "\\b(19|20)\\d{2}\\b", options: .regularExpression) != nil }) {
                    editVintage = yearMatch.trimmingCharacters(in: .whitespaces)
                }
                
                // Try to find alcohol percentage
                if let alcoholMatch = recognizedStrings.first(where: { $0.range(of: "\\d{1,2}(\\.\\d)?\\s?%|ALC", options: [.regularExpression, .caseInsensitive]) != nil }) {
                    editAlcohol = alcoholMatch.trimmingCharacters(in: .whitespaces)
                }
                
                // Try to infer wine category from the text
                let lowercaseText = fullText.lowercased()
                if lowercaseText.contains("sparkling") || lowercaseText.contains("champagne") || lowercaseText.contains("prosecco") || lowercaseText.contains("cava") {
                    editCategory = "Sparkling"
                } else if lowercaseText.contains("rosé") || lowercaseText.contains("rose") || lowercaseText.contains("blush") {
                    editCategory = "Rosé"
                } else if lowercaseText.contains("white") || lowercaseText.contains("blanc") || lowercaseText.contains("chardonnay") || lowercaseText.contains("riesling") || lowercaseText.contains("sauvignon") {
                    editCategory = "White"
                } else if lowercaseText.contains("red") || lowercaseText.contains("rouge") || lowercaseText.contains("noir") || lowercaseText.contains("cabernet") || lowercaseText.contains("merlot") || lowercaseText.contains("syrah") || lowercaseText.contains("shiraz") {
                    editCategory = "Red"
                } else if lowercaseText.contains("dessert") || lowercaseText.contains("sweet") || lowercaseText.contains("ice wine") || lowercaseText.contains("sauternes") {
                    editCategory = "Dessert"
                } else if lowercaseText.contains("port") || lowercaseText.contains("porto") || lowercaseText.contains("fortified") {
                    editCategory = "Port"
                }
                
                // Try to match wine regions
                let matches = wineRegions.findMatches(in: fullText)
                if let country = matches.country {
                    editCountry = country
                    wineRegions.updateRegions(for: country)
                    
                    if let region = matches.region {
                        editRegion = region
                        wineRegions.updateSubregions(for: country, region: region)
                        
                        if let subregion = matches.subregion {
                            editSubregion = subregion
                            wineRegions.updateTypes(for: country, region: region, subregion: subregion)
                            
                            if let type = matches.type {
                                editType = type
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

    private func consumeWine() {
        // Don't allow consuming more than available
        if Int(wine.quantity) < consumeAmount {
            consumeAmount = Int(wine.quantity)
        }
        
        // Don't consume if there's nothing to consume
        guard wine.quantity > 0 && consumeAmount > 0 else { return }
        
        let oldQuantity = wine.quantity
        wine.quantity -= Int16(consumeAmount)
        
        do {
            try viewContext.save()
            
            // Log the wine consumption to history
            historyService.logWineConsumed(wine: wine, quantityConsumed: consumeAmount)
            
            // Force an update to the object
            viewContext.refresh(wine, mergeChanges: true)
            // Make sure the changes are processed immediately
            wine.objectWillChange.send()
            // Navigate back after successful consumption
            dismiss()
        } catch {
            print("Error saving context: \(error)")
            wine.quantity = oldQuantity
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}
