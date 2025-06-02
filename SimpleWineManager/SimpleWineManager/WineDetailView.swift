import SwiftUI
import Vision
import UIKit

struct WineDetailView: View {
    @ObservedObject var wine: Wine
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let wineCategories = ["Red Wine", "White Wine", "Sparkling Wine", "Rosé Wine"]
    
    @State private var consumeAmount = 1
    @State private var isEditing = false
    @State private var isShowingCopySheet = false
    @StateObject private var wineRegions = WineRegions()
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isEditing {
                    editingContent
                } else {
                    viewingContent
                }
            }
            .padding()
        }
        .navigationTitle(wine.name ?? "Wine Details")
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
        .sheet(isPresented: $isShowingFrontCamera) {
            ImagePicker(image: $editFrontImage, sourceType: .camera, onImageSelected: { _ in })
        }
        .sheet(isPresented: $isShowingBackCamera) {
            ImagePicker(image: $editBackImage, sourceType: .camera, onImageSelected: { _ in })
        }
        .sheet(isPresented: $isShowingCopySheet) {
            NavigationView {
                AddWineView(copyFrom: wine)
            }
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
        VStack(alignment: .leading, spacing: 20) {
            // Wine Details Form
            Group {
                // Wine Category Selection
                Section {
                    Picker("Category", selection: $editCategory) {
                        ForEach(wineCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 8)
                }
                
                Group {
                    HStack {
                        Text("Name")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        TextField("Name", text: $editName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Producer")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        TextField("Producer", text: $editProducer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Vintage")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        TextField("Vintage", text: $editVintage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text("Alcohol")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        TextField("Alcohol %", text: $editAlcohol)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Quantity")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Stepper("\(editQuantity)", value: $editQuantity, in: 0...999)
                    }
                }
                .padding(.vertical, 4)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Wine Region Selection
                Group {
                    HStack {
                        Text("Country")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $editCountry) {
                            Text("Select Country").tag("")
                            ForEach(wineRegions.countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Region")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $editRegion) {
                            Text("Select Region").tag("")
                            ForEach(wineRegions.regions, id: \.self) { region in
                                Text(region).tag(region)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Subregion")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $editSubregion) {
                            Text("Select Subregion").tag("")
                            ForEach(wineRegions.subregions, id: \.self) { subregion in
                                Text(subregion).tag(subregion)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Type")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $editType) {
                            Text("Select Type").tag("")
                            ForEach(wineRegions.types, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                }
            }

            Divider()
                .padding(.vertical, 8)

            // Photos Section at the bottom
            HStack(spacing: 15) {
                Image(systemName: "camera")
                    .foregroundColor(.blue)

                VStack(spacing: 8) {
                    if let image = editFrontImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(8)
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
                            .frame(height: 150)
                            .cornerRadius(8)
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
            .onAppear {
                setupEditingState()
            }
            .onChange(of: editCountry) { oldValue, newValue in
                if !updatingFromSelection {
                    updatingFromSelection = true
                    wineRegions.updateRegions(for: newValue)
                    editRegion = ""
                    editSubregion = ""
                    editType = ""
                    updatingFromSelection = false
                }
            }
            .onChange(of: editRegion) { oldValue, newValue in
                if !updatingFromSelection {
                    updatingFromSelection = true
                    if !newValue.isEmpty {
                        wineRegions.updateSubregions(for: editCountry, region: newValue)
                        editSubregion = ""
                        editType = ""
                    }
                    updatingFromSelection = false
                }
            }
            .onChange(of: editSubregion) { oldValue, newValue in
                if !updatingFromSelection {
                    updatingFromSelection = true
                    if !newValue.isEmpty {
                        wineRegions.updateTypes(for: editCountry, region: editRegion, subregion: newValue)
                        editType = ""
                    }
                    updatingFromSelection = false
                }
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
                DetailRow(label: "Alcohol", value: wine.alcohol ?? "")
                DetailRow(label: "Quantity", value: "\(wine.quantity)")
                DetailRow(label: "Category", value: wine.category ?? "")
                DetailRow(label: "Country", value: wine.country ?? "")
                DetailRow(label: "Region", value: wine.region ?? "")
                DetailRow(label: "Subregion", value: wine.subregion ?? "")
                DetailRow(label: "Type", value: wine.type ?? "")
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
                    editCategory = "Sparkling Wine"
                } else if lowercaseText.contains("rosé") || lowercaseText.contains("rose") || lowercaseText.contains("blush") {
                    editCategory = "Rosé Wine"
                } else if lowercaseText.contains("white") || lowercaseText.contains("blanc") || lowercaseText.contains("chardonnay") || lowercaseText.contains("riesling") || lowercaseText.contains("sauvignon") {
                    editCategory = "White Wine"
                } else if lowercaseText.contains("red") || lowercaseText.contains("rouge") || lowercaseText.contains("noir") || lowercaseText.contains("cabernet") || lowercaseText.contains("merlot") || lowercaseText.contains("syrah") || lowercaseText.contains("shiraz") {
                    editCategory = "Red Wine"
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
        
        wine.quantity -= Int16(consumeAmount)
        
        do {
            try viewContext.save()
            // Force an update to the object
            viewContext.refresh(wine, mergeChanges: true)
            // Make sure the changes are processed immediately
            wine.objectWillChange.send()
            // Navigate back after successful consumption
            dismiss()
        } catch {
            print("Error saving context: \(error)")
            wine.quantity += Int16(consumeAmount)
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
