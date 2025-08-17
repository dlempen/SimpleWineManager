import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct WineImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let fileURL: URL
    let settings: SettingsStore
    
    @State private var importData: ImportData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Import options
    @State private var importMode: ImportMode = .newOnly
    @State private var setQuantityToZero = false
    @State private var updateMode: UpdateMode = .fillEmpty
    
    // Wine selection
    @State private var selectedWines: Set<UUID> = []
    @State private var searchText = ""
    
    // CSV field mapping (only for CSV files)
    @State private var fieldMappings: [String: WineField] = [:]
    @State private var csvImportStep: CSVImportStep = .fieldMapping // New state for CSV import steps
    @State private var processedWines: [ImportWine] = [] // Wines after field mapping is applied
    @State private var charactersToRemove: String = "\"" // Characters to strip during import
    
    @StateObject private var exportImportManager: WineExportImportManager
    
    init(fileURL: URL, settings: SettingsStore, context: NSManagedObjectContext) {
        self.fileURL = fileURL
        self.settings = settings
        _exportImportManager = StateObject(wrappedValue: WineExportImportManager(context: context, settings: settings))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading file...")
                            .padding(.top)
                    }
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Import Error")
                            .font(.headline)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                } else if let data = importData {
                    importContentView(data: data)
                }
            }
            .navigationTitle("Import Wines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                if importData != nil && !isLoading && errorMessage == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        if case .csv = importData?.fileType, csvImportStep == .fieldMapping {
                            Button("Next") {
                                processCSVMapping()
                            }
                            .disabled(!isValidFieldMapping())
                        } else {
                            Button("Import") {
                                performImport()
                            }
                            .disabled(selectedWines.isEmpty)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadImportData()
        }
        .alert("Import Result", isPresented: $showingAlert) {
            Button("OK") {
                if !alertMessage.contains("failed") && !alertMessage.contains("Error") {
                    dismiss() // Close on successful import
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    @ViewBuilder
    private func importContentView(data: ImportData) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if case .csv = data.fileType {
                    // CSV Two-Step Process
                    if csvImportStep == .fieldMapping {
                        // Step 1: Field Mapping and Preview
                        csvFieldMappingSection
                        csvPreviewSection
                    } else {
                        // Step 2: Import Options and Wine Selection
                        importOptionsSection
                        wineSelectionSection(wines: processedWines)
                    }
                } else {
                    // Single-Step Process for Proprietary Files
                    importOptionsSection
                    wineSelectionSection(wines: data.wines)
                }
            }
            .padding()
        }
    }
    
    private var importOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Options")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Import Mode")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Import Mode", selection: $importMode) {
                    Text("New wines only").tag(ImportMode.newOnly)
                    Text("All wines").tag(ImportMode.all)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text(importMode.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if importMode == .newOnly {
                Toggle("Set quantity to 0 for new wines", isOn: $setQuantityToZero)
                    .font(.callout)
            }
            
            if importMode == .all {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Update Mode")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Update Mode", selection: $updateMode) {
                        Text("Fill empty fields only").tag(UpdateMode.fillEmpty)
                        Text("Overwrite all fields").tag(UpdateMode.overwrite)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(updateMode.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var csvFieldMappingSection: some View {
        if case .csv(let headers) = importData?.fileType {
            VStack(alignment: .leading, spacing: 12) {
                Text("Field Mapping")
                    .font(.headline)
                
                Text("Map CSV columns to wine fields. Fields can only be used once.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVStack(spacing: 8) {
                    ForEach(headers, id: \.self) { header in
                        csvFieldMappingRow(csvField: header)
                    }
                }
                
                Divider()
                
                // Character removal section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Character Removal (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Enter characters to remove from all imported data (e.g. quotes, brackets):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Remove:")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        TextField("Characters to remove", text: $charactersToRemove)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    if !charactersToRemove.isEmpty {
                        Text("These characters will be removed: \(charactersToRemove)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private func csvFieldMappingRow(csvField: String) -> some View {
        HStack {
            Text(csvField)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
            
            Picker("Map to", selection: Binding(
                get: { fieldMappings[csvField] ?? .noImport },
                set: { newValue in
                    // Remove previous mapping if exists
                    if let oldValue = fieldMappings[csvField], oldValue != .noImport {
                        // Find and remove the old mapping
                        fieldMappings = fieldMappings.mapValues { value in
                            value == oldValue && fieldMappings.first(where: { $0.value == oldValue })?.key == csvField ? .noImport : value
                        }
                    }
                    
                    // Set new mapping
                    if newValue != .noImport {
                        // Remove this field from any other mappings
                        fieldMappings = fieldMappings.mapValues { value in
                            value == newValue ? .noImport : value
                        }
                        fieldMappings[csvField] = newValue
                    } else {
                        fieldMappings[csvField] = .noImport
                    }
                }
            )) {
                Text("No Import").tag(WineField.noImport)
                ForEach(WineField.allImportableFields, id: \.self) { field in
                    Text(field.displayName)
                        .tag(field)
                        .disabled(isFieldMapped(field) && fieldMappings[csvField] != field)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 150)
        }
        .padding(.vertical, 4)
    }
    
    private func isFieldMapped(_ field: WineField) -> Bool {
        fieldMappings.values.contains(field)
    }
    
    @ViewBuilder
    private var csvPreviewSection: some View {
        if case .csv = importData?.fileType, !fieldMappings.isEmpty {
            let mappedFields = fieldMappings.filter { $0.value != .noImport }
            
            if !mappedFields.isEmpty {
                csvPreviewContent(mappedFields: mappedFields)
            }
        }
    }
    
    @ViewBuilder
    private func csvPreviewContent(mappedFields: [String: WineField]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            Text("First few rows showing how your data will be imported:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            let sampleWines = Array(importData?.wines.prefix(3) ?? [])
            
            ForEach(sampleWines, id: \.id) { wine in
                csvPreviewRow(wine: wine, mappedFields: mappedFields, isLast: wine.id == sampleWines.last?.id)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func csvPreviewRow(wine: ImportWine, mappedFields: [String: WineField], isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let sortedFields = mappedFields.sorted(by: { $0.value.displayName < $1.value.displayName })
            
            ForEach(sortedFields, id: \.key) { csvField, wineField in
                csvPreviewFieldRow(csvField: csvField, wineField: wineField, wine: wine)
            }
            
            if !isLast {
                Divider()
                    .padding(.top, 4)
            }
        }
    }
    
    @ViewBuilder
    private func csvPreviewFieldRow(csvField: String, wineField: WineField, wine: ImportWine) -> some View {
        HStack {
            Text(wineField.displayName + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            let value = wine.csvData?[csvField] ?? ""
            let processedValue = processPreviewValue(value: value, field: wineField)
            
            Text(processedValue.isEmpty ? "—" : processedValue)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func processPreviewValue(value: String, field: WineField) -> String {
        let cleanedValue = removeUnwantedCharacters(from: value)
        switch field {
        case .alcohol:
            return cleanAlcoholValue(cleanedValue)
        case .bottleSize:
            return cleanBottleSizeValue(cleanedValue)
        default:
            return cleanedValue
        }
    }
    
    private func wineSelectionSection(wines: [ImportWine]) -> some View {
        let filteredWines = searchText.isEmpty ? wines : wines.filter { wine in
            let searchTerm = searchText.lowercased()
            return wine.name?.lowercased().contains(searchTerm) == true ||
                   wine.producer?.lowercased().contains(searchTerm) == true ||
                   wine.vintage?.lowercased().contains(searchTerm) == true
        }
        
        let availableWines = importMode == .newOnly ? wines.filter { !$0.existsInDatabase } : wines
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Wines to Import")
                    .font(.headline)
                Spacer()
                if !availableWines.isEmpty {
                    Button(selectedWines.count == availableWines.count ? "Deselect All" : "Select All") {
                        if selectedWines.count == availableWines.count {
                            selectedWines.removeAll()
                        } else {
                            selectedWines = Set(availableWines.map { $0.id })
                        }
                    }
                    .font(.callout)
                }
            }
            
            SearchBar(text: $searchText)
            
            Text("\(selectedWines.count) of \(availableWines.count) wines selected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if availableWines.isEmpty {
                if importMode == .newOnly {
                    Text("No new wines found in the import file. All wines already exist in your collection.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text("No wines found in the import file.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(filteredWines.filter { wine in availableWines.contains { $0.id == wine.id } }, id: \.id) { wine in
                        ImportWineRow(
                            wine: wine,
                            isSelected: selectedWines.contains(wine.id)
                        ) {
                            if selectedWines.contains(wine.id) {
                                selectedWines.remove(wine.id)
                            } else {
                                selectedWines.insert(wine.id)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func loadImportData() {
        Task {
            do {
                let data = try await loadImportDataAsync()
                await MainActor.run {
                    self.importData = data
                    self.isLoading = false
                    
                    // Auto-select all available wines
                    let wines = data.wines
                    let availableWines = importMode == .newOnly ? wines.filter { !$0.existsInDatabase } : wines
                    selectedWines = Set(availableWines.map { $0.id })
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadImportDataAsync() async throws -> ImportData {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Request access to security-scoped resource
                    let accessGranted = fileURL.startAccessingSecurityScopedResource()
                    defer {
                        if accessGranted {
                            fileURL.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    let data = try Data(contentsOf: fileURL)
                    
                    // Determine file type
                    let fileType: ImportFileType
                    let wines: [ImportWine]
                    
                    if fileURL.pathExtension.lowercased() == "csv" {
                        // Parse CSV
                        let csvResult = try self.parseCSV(data: data)
                        fileType = .csv(headers: csvResult.headers)
                        wines = csvResult.wines
                        
                        // Auto-map fields based on common names
                        DispatchQueue.main.async {
                            self.autoMapCSVFields(headers: csvResult.headers)
                        }
                    } else {
                        // Parse proprietary format
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let collection = try decoder.decode(WineCollection.self, from: data)
                        fileType = .proprietary
                        wines = collection.wines.map { ImportWine(from: $0, context: self.viewContext) }
                    }
                    
                    let importData = ImportData(fileType: fileType, wines: wines)
                    continuation.resume(returning: importData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func parseCSV(data: Data) throws -> (headers: [String], wines: [ImportWine]) {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat
        }
        
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            throw ImportError.invalidFormat
        }
        
        // Parse header row
        let headers = parseCSVLine(lines[0])
        guard !headers.isEmpty else {
            throw ImportError.invalidFormat
        }
        
        // Parse wine rows
        var wines: [ImportWine] = []
        for i in 1..<lines.count {
            let fields = parseCSVLine(lines[i])
            if fields.count == headers.count {
                let wine = ImportWine(from: headers, fields: fields, context: viewContext)
                wines.append(wine)
            }
        }
        
        return (headers, wines)
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                if inQuotes && i < line.index(before: line.endIndex) && line[line.index(after: i)] == "\"" {
                    // Escaped quote
                    currentField += "\""
                    i = line.index(after: i)
                } else {
                    // Toggle quote state
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                // Field separator
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // Don't forget the last field
        fields.append(currentField)
        
        return fields
    }
    
    private func autoMapCSVFields(headers: [String]) {
        for header in headers {
            let normalizedHeader = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Try to find matching field
            for field in WineField.allImportableFields {
                if field.matchesCSVHeader(normalizedHeader) && !isFieldMapped(field) {
                    fieldMappings[header] = field
                    break
                }
            }
        }
    }
    
    // MARK: - CSV Import Methods
    
    private func processCSVMapping() {
        guard case .csv = importData?.fileType,
              let rawWines = importData?.wines else {
            return
        }
        
        // Create processed wines with field mappings applied
        processedWines = rawWines.compactMap { wine in
            guard let csvData = wine.csvData else { return wine }
            
            var name: String?
            var producer: String?
            var vintage: String?
            var alcohol: String?
            var quantity: Int16 = 1
            var category: String?
            var country: String?
            var region: String?
            var subregion: String?
            var type: String?
            var bottleSize: String?
            var readyToTrinkYear: String?
            var bestBeforeYear: String?
            var storageLocation: String?
            var remarks: String?
            var wineRating: String?
            var price: Double?
            
            // Apply field mappings
            for (csvField, wineField) in fieldMappings {
                guard wineField != .noImport,
                      let rawValue = csvData[csvField],
                      !rawValue.isEmpty else { continue }
                
                // Clean unwanted characters first
                let cleanedValue = removeUnwantedCharacters(from: rawValue)
                guard !cleanedValue.isEmpty else { continue }
                
                switch wineField {
                case .name:
                    name = cleanedValue
                case .producer:
                    producer = cleanedValue
                case .vintage:
                    vintage = cleanedValue
                case .alcohol:
                    alcohol = cleanAlcoholValue(cleanedValue)
                case .quantity:
                    quantity = Int16(cleanedValue) ?? 1
                case .category:
                    category = cleanedValue
                case .country:
                    country = cleanedValue
                case .region:
                    region = cleanedValue
                case .subregion:
                    subregion = cleanedValue
                case .type:
                    type = cleanedValue
                case .bottleSize:
                    bottleSize = cleanBottleSizeValue(cleanedValue)
                case .readyToTrinkYear:
                    readyToTrinkYear = cleanedValue
                case .bestBeforeYear:
                    bestBeforeYear = cleanedValue
                case .storageLocation:
                    storageLocation = cleanedValue
                case .remarks:
                    remarks = cleanedValue
                case .wineRating:
                    wineRating = cleanedValue
                case .price:
                    price = Double(cleanedValue)
                case .noImport:
                    break
                }
            }
            
            // Create new ImportWine with proper field values
            return ImportWine(
                name: name,
                producer: producer,
                vintage: vintage,
                alcohol: alcohol,
                quantity: quantity,
                category: category,
                country: country,
                region: region,
                subregion: subregion,
                type: type,
                bottleSize: bottleSize,
                readyToTrinkYear: readyToTrinkYear,
                bestBeforeYear: bestBeforeYear,
                storageLocation: storageLocation,
                remarks: remarks,
                wineRating: wineRating,
                price: price,
                csvData: csvData,
                existsInDatabase: checkWineExistsInDatabase(name: name, producer: producer, vintage: vintage)
            )
        }
        
        // Move to wine selection step
        csvImportStep = .wineSelection
        
        // Select all wines by default
        selectedWines = Set(processedWines.map { $0.id })
    }
    
    // MARK: - Helper Methods
    
    /// Removes user-specified unwanted characters from a string
    private func removeUnwantedCharacters(from value: String) -> String {
        guard !charactersToRemove.isEmpty else { return value }
        
        var cleanedValue = value
        for character in charactersToRemove {
            cleanedValue = cleanedValue.replacingOccurrences(of: String(character), with: "")
        }
        
        return cleanedValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isValidFieldMapping() -> Bool {
        // At least name should be mapped for a valid import
        return fieldMappings.values.contains(.name)
    }
    
    private func checkWineExistsInDatabase(name: String?, producer: String?, vintage: String?) -> Bool {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return false
        }
        
        let request: NSFetchRequest<Wine> = Wine.fetchRequest()
        
        if let producer = producer?.trimmingCharacters(in: .whitespacesAndNewlines), !producer.isEmpty,
           let vintage = vintage?.trimmingCharacters(in: .whitespacesAndNewlines), !vintage.isEmpty {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND producer ==[c] %@ AND vintage ==[c] %@", name, producer, vintage)
        } else {
            request.predicate = NSPredicate(format: "name ==[c] %@", name)
        }
        
        return (try? viewContext.fetch(request).first) != nil
    }
    
    private func performImport() {
        guard let importData = importData else { return }
        
        // For CSV imports, use processed wines; for proprietary imports, use original wines
        let availableWines: [ImportWine]
        if case .csv = importData.fileType {
            availableWines = processedWines
        } else {
            availableWines = importData.wines
        }
        let winesToImport = availableWines.filter { selectedWines.contains($0.id) }
        
        Task {
            let result = await performImportAsync(wines: winesToImport)
            await MainActor.run {
                switch result {
                case .success(let importResult):
                    if importResult.skipped > 0 {
                        alertMessage = "Import complete!\n• \(importResult.imported) wine\(importResult.imported == 1 ? "" : "s") imported\n• \(importResult.skipped) duplicate\(importResult.skipped == 1 ? "" : "s") skipped"
                    } else {
                        alertMessage = "Successfully imported \(importResult.imported) wine\(importResult.imported == 1 ? "" : "s")."
                    }
                    
                    // Notify the app that data changed
                    NotificationCenter.default.post(name: NSNotification.Name("WineDataDidChange"), object: nil)
                    
                case .failure(let error):
                    alertMessage = "Import failed: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    private func performImportAsync(wines: [ImportWine]) async -> Result<ImportResult, Error> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    var importedCount = 0
                    var skippedCount = 0
                    
                    for importWine in wines {
                        let existingWine = self.findExistingWine(importWine)
                        
                        if let existing = existingWine {
                            if self.importMode == .all {
                                // Update existing wine
                                self.updateWine(existing, with: importWine)
                                importedCount += 1
                            } else {
                                // Skip existing wine
                                skippedCount += 1
                            }
                        } else {
                            // Create new wine
                            let newWine = self.createWine(from: importWine)
                            if self.setQuantityToZero && self.importMode == .newOnly {
                                newWine.quantity = 0
                            }
                            importedCount += 1
                        }
                    }
                    
                    try self.viewContext.save()
                    let result = ImportResult(imported: importedCount, skipped: skippedCount)
                    continuation.resume(returning: .success(result))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    private func findExistingWine(_ importWine: ImportWine) -> Wine? {
        let request: NSFetchRequest<Wine> = Wine.fetchRequest()
        
        // First try by name, producer, and vintage if all are available
        if let name = importWine.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
           let producer = importWine.producer?.trimmingCharacters(in: .whitespacesAndNewlines), !producer.isEmpty,
           let vintage = importWine.vintage?.trimmingCharacters(in: .whitespacesAndNewlines), !vintage.isEmpty {
            
            request.predicate = NSPredicate(format: "name ==[c] %@ AND producer ==[c] %@ AND vintage ==[c] %@", name, producer, vintage)
            return try? viewContext.fetch(request).first
        }
        
        return nil
    }
    
    private func updateWine(_ wine: Wine, with importWine: ImportWine) {
        if case .csv = importData?.fileType {
            // Update based on field mappings
            updateWineFromCSV(wine, with: importWine)
        } else {
            // Update from proprietary format
            updateWineFromProprietary(wine, with: importWine)
        }
    }
    
    private func updateWineFromCSV(_ wine: Wine, with importWine: ImportWine) {
        // Use the already processed values from the ImportWine object
        // These were created during processCSVMapping() with proper field mappings applied
        if updateMode == .overwrite || shouldFillField(wine, field: .name) {
            wine.name = importWine.name
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .producer) {
            wine.producer = importWine.producer
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .vintage) {
            wine.vintage = importWine.vintage
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .alcohol) {
            wine.alcohol = importWine.alcohol
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .category) {
            wine.category = importWine.category
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .country) {
            wine.country = importWine.country
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .region) {
            wine.region = importWine.region
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .subregion) {
            wine.subregion = importWine.subregion
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .type) {
            wine.type = importWine.type
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .bottleSize) {
            wine.bottleSize = importWine.bottleSize
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .readyToTrinkYear) {
            wine.readyToTrinkYear = importWine.readyToTrinkYear
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .bestBeforeYear) {
            wine.bestBeforeYear = importWine.bestBeforeYear
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .storageLocation) {
            wine.storageLocation = importWine.storageLocation
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .remarks) {
            wine.remarks = importWine.remarks
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .wineRating) {
            wine.wineRating = importWine.wineRating
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .price) {
            wine.price = importWine.price != nil ? NSDecimalNumber(value: importWine.price!) : nil
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .quantity) {
            wine.quantity = importWine.quantity
        }
    }
    
    private func updateWineFromProprietary(_ wine: Wine, with importWine: ImportWine) {
        if updateMode == .overwrite || shouldFillField(wine, field: .name) {
            wine.name = importWine.name
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .producer) {
            wine.producer = importWine.producer
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .vintage) {
            wine.vintage = importWine.vintage
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .alcohol) {
            wine.alcohol = importWine.alcohol?.isEmpty == false ? cleanAlcoholValue(importWine.alcohol!) : nil
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .category) {
            wine.category = importWine.category
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .country) {
            wine.country = importWine.country
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .region) {
            wine.region = importWine.region
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .subregion) {
            wine.subregion = importWine.subregion
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .type) {
            wine.type = importWine.type
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .bottleSize) {
            wine.bottleSize = importWine.bottleSize?.isEmpty == false ? cleanBottleSizeValue(importWine.bottleSize!) : nil
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .readyToTrinkYear) {
            wine.readyToTrinkYear = importWine.readyToTrinkYear
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .bestBeforeYear) {
            wine.bestBeforeYear = importWine.bestBeforeYear
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .storageLocation) {
            wine.storageLocation = importWine.storageLocation
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .remarks) {
            wine.remarks = importWine.remarks
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .wineRating) {
            wine.wineRating = importWine.wineRating
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .price) {
            wine.price = importWine.price != nil ? NSDecimalNumber(value: importWine.price!) : nil
        }
        if updateMode == .overwrite || shouldFillField(wine, field: .quantity) {
            wine.quantity = importWine.quantity
        }
    }
    
    private func shouldFillField(_ wine: Wine, field: WineField) -> Bool {
        switch field {
        case .name: return wine.name?.isEmpty != false
        case .producer: return wine.producer?.isEmpty != false
        case .vintage: return wine.vintage?.isEmpty != false
        case .alcohol: return wine.alcohol?.isEmpty != false
        case .category: return wine.category?.isEmpty != false
        case .country: return wine.country?.isEmpty != false
        case .region: return wine.region?.isEmpty != false
        case .subregion: return wine.subregion?.isEmpty != false
        case .type: return wine.type?.isEmpty != false
        case .bottleSize: return wine.bottleSize?.isEmpty != false
        case .readyToTrinkYear: return wine.readyToTrinkYear?.isEmpty != false
        case .bestBeforeYear: return wine.bestBeforeYear?.isEmpty != false
        case .storageLocation: return wine.storageLocation?.isEmpty != false
        case .remarks: return wine.remarks?.isEmpty != false
        case .wineRating: return wine.wineRating?.isEmpty != false
        case .price: return wine.price == nil || wine.price?.doubleValue == 0
        case .quantity: return wine.quantity == 0
        case .noImport: return false
        }
    }
    
    private func setWineField(_ wine: Wine, field: WineField, value: String) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch field {
        case .name: wine.name = trimmedValue.isEmpty ? nil : trimmedValue
        case .producer: wine.producer = trimmedValue.isEmpty ? nil : trimmedValue
        case .vintage: wine.vintage = trimmedValue.isEmpty ? nil : trimmedValue
        case .alcohol: wine.alcohol = trimmedValue.isEmpty ? nil : cleanAlcoholValue(trimmedValue)
        case .category: wine.category = trimmedValue.isEmpty ? nil : trimmedValue
        case .country: wine.country = trimmedValue.isEmpty ? nil : trimmedValue
        case .region: wine.region = trimmedValue.isEmpty ? nil : trimmedValue
        case .subregion: wine.subregion = trimmedValue.isEmpty ? nil : trimmedValue
        case .type: wine.type = trimmedValue.isEmpty ? nil : trimmedValue
        case .bottleSize: wine.bottleSize = trimmedValue.isEmpty ? nil : cleanBottleSizeValue(trimmedValue)
        case .readyToTrinkYear: wine.readyToTrinkYear = trimmedValue.isEmpty ? nil : trimmedValue
        case .bestBeforeYear: wine.bestBeforeYear = trimmedValue.isEmpty ? nil : trimmedValue
        case .storageLocation: wine.storageLocation = trimmedValue.isEmpty ? nil : trimmedValue
        case .remarks: wine.remarks = trimmedValue.isEmpty ? nil : trimmedValue
        case .wineRating: wine.wineRating = trimmedValue.isEmpty ? nil : trimmedValue
        case .price:
            if let doubleValue = Double(trimmedValue) {
                wine.price = NSDecimalNumber(value: doubleValue)
            }
        case .quantity:
            if let intValue = Int16(trimmedValue) {
                wine.quantity = intValue
            }
        case .noImport:
            break
        }
    }
    
    private func createWine(from importWine: ImportWine) -> Wine {
        let wine = Wine(context: viewContext)
        wine.id = UUID()
        
        if case .csv = importData?.fileType {
            // Create from CSV data
            createWineFromCSV(wine, with: importWine)
        } else {
            // Create from proprietary format
            createWineFromProprietary(wine, with: importWine)
        }
        
        return wine
    }
    
    private func createWineFromCSV(_ wine: Wine, with importWine: ImportWine) {
        // Use the already processed values from the ImportWine object
        // These were created during processCSVMapping() with proper field mappings applied
        wine.name = importWine.name
        wine.producer = importWine.producer
        wine.vintage = importWine.vintage
        wine.alcohol = importWine.alcohol
        wine.quantity = importWine.quantity
        wine.category = importWine.category
        wine.country = importWine.country
        wine.region = importWine.region
        wine.subregion = importWine.subregion
        wine.type = importWine.type
        wine.bottleSize = importWine.bottleSize
        wine.readyToTrinkYear = importWine.readyToTrinkYear
        wine.bestBeforeYear = importWine.bestBeforeYear
        wine.storageLocation = importWine.storageLocation
        wine.remarks = importWine.remarks
        wine.wineRating = importWine.wineRating
        wine.price = importWine.price != nil ? NSDecimalNumber(value: importWine.price!) : nil
    }
    
    private func createWineFromProprietary(_ wine: Wine, with importWine: ImportWine) {
        wine.name = importWine.name
        wine.producer = importWine.producer
        wine.vintage = importWine.vintage
        wine.alcohol = importWine.alcohol?.isEmpty == false ? cleanAlcoholValue(importWine.alcohol!) : nil
        wine.quantity = importWine.quantity
        wine.category = importWine.category
        wine.country = importWine.country
        wine.region = importWine.region
        wine.subregion = importWine.subregion
        wine.type = importWine.type
        wine.bottleSize = importWine.bottleSize?.isEmpty == false ? cleanBottleSizeValue(importWine.bottleSize!) : nil
        wine.readyToTrinkYear = importWine.readyToTrinkYear
        wine.bestBeforeYear = importWine.bestBeforeYear
        wine.storageLocation = importWine.storageLocation
        wine.remarks = importWine.remarks
        wine.wineRating = importWine.wineRating
        if let price = importWine.price {
            wine.price = NSDecimalNumber(value: price)
        }
        // Note: Images are not imported from CSV
        wine.frontImageData = importWine.frontImageData
        wine.backImageData = importWine.backImageData
    }
}

// MARK: - Data Models

struct ImportData {
    let fileType: ImportFileType
    let wines: [ImportWine]
}

enum ImportFileType {
    case proprietary
    case csv(headers: [String])
}

struct ImportWine {
    let id = UUID()
    let name: String?
    let producer: String?
    let vintage: String?
    let alcohol: String?
    let quantity: Int16
    let category: String?
    let country: String?
    let region: String?
    let subregion: String?
    let type: String?
    let bottleSize: String?
    let readyToTrinkYear: String?
    let bestBeforeYear: String?
    let storageLocation: String?
    let remarks: String?
    let wineRating: String?
    let price: Double?
    let frontImageData: Data?
    let backImageData: Data?
    let csvData: [String: String]?
    let existsInDatabase: Bool
    
    init(from sharedWine: SharedWine, context: NSManagedObjectContext) {
        self.name = sharedWine.name
        self.producer = sharedWine.producer
        self.vintage = sharedWine.vintage
        self.alcohol = sharedWine.alcohol
        self.quantity = sharedWine.quantity
        self.category = sharedWine.category
        self.country = sharedWine.country
        self.region = sharedWine.region
        self.subregion = sharedWine.subregion
        self.type = sharedWine.type
        self.bottleSize = sharedWine.bottleSize
        self.readyToTrinkYear = sharedWine.readyToTrinkYear
        self.bestBeforeYear = sharedWine.bestBeforeYear
        self.storageLocation = sharedWine.storageLocation
        self.remarks = nil // Not available in SharedWine
        self.wineRating = nil // Not available in SharedWine
        self.price = sharedWine.price
        self.frontImageData = sharedWine.frontImageData
        self.backImageData = sharedWine.backImageData
        self.csvData = nil
        
        // Check if wine exists in database
        self.existsInDatabase = ImportWine.checkWineExists(sharedWine, context: context)
    }
    
    init(from headers: [String], fields: [String], context: NSManagedObjectContext) {
        var csvData: [String: String] = [:]
        for (index, header) in headers.enumerated() {
            if index < fields.count {
                csvData[header] = fields[index]
            }
        }
        self.csvData = csvData
        
        // Extract basic fields for display
        self.name = csvData.values.first { !$0.isEmpty }
        self.producer = nil
        self.vintage = nil
        self.alcohol = nil
        self.quantity = 1
        self.category = nil
        self.country = nil
        self.region = nil
        self.subregion = nil
        self.type = nil
        self.bottleSize = nil
        self.readyToTrinkYear = nil
        self.bestBeforeYear = nil
        self.storageLocation = nil
        self.remarks = nil
        self.wineRating = nil
        self.price = nil
        self.frontImageData = nil
        self.backImageData = nil
        
        // Check if wine exists (simplified for CSV)
        self.existsInDatabase = false // Will be updated later
    }
    
    // New initializer for properly mapped CSV wines
    init(name: String?, producer: String?, vintage: String?, alcohol: String?, quantity: Int16, category: String?, country: String?, region: String?, subregion: String?, type: String?, bottleSize: String?, readyToTrinkYear: String?, bestBeforeYear: String?, storageLocation: String?, remarks: String?, wineRating: String?, price: Double?, csvData: [String: String]?, existsInDatabase: Bool) {
        self.name = name
        self.producer = producer
        self.vintage = vintage
        self.alcohol = alcohol
        self.quantity = quantity
        self.category = category
        self.country = country
        self.region = region
        self.subregion = subregion
        self.type = type
        self.bottleSize = bottleSize
        self.readyToTrinkYear = readyToTrinkYear
        self.bestBeforeYear = bestBeforeYear
        self.storageLocation = storageLocation
        self.remarks = remarks
        self.wineRating = wineRating
        self.price = price
        self.frontImageData = nil
        self.backImageData = nil
        self.csvData = csvData
        self.existsInDatabase = existsInDatabase
    }
    
    static func checkWineExists(_ sharedWine: SharedWine, context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<Wine> = Wine.fetchRequest()
        
        // Check by name, producer, and vintage if all are available
        if let name = sharedWine.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
           let producer = sharedWine.producer?.trimmingCharacters(in: .whitespacesAndNewlines), !producer.isEmpty,
           let vintage = sharedWine.vintage?.trimmingCharacters(in: .whitespacesAndNewlines), !vintage.isEmpty {
            
            request.predicate = NSPredicate(format: "name ==[c] %@ AND producer ==[c] %@ AND vintage ==[c] %@", name, producer, vintage)
            return (try? context.fetch(request).first) != nil
        }
        
        return false
    }
}

// MARK: - Enums

enum ImportMode: CaseIterable {
    case newOnly
    case all
    
    var description: String {
        switch self {
        case .newOnly:
            return "Only import wines that don't already exist in your collection"
        case .all:
            return "Import all wines, including duplicates"
        }
    }
}

enum UpdateMode: CaseIterable {
    case fillEmpty
    case overwrite
    
    var description: String {
        switch self {
        case .fillEmpty:
            return "Only fill in empty fields of existing wines"
        case .overwrite:
            return "Replace all fields of existing wines with imported data"
        }
    }
}

enum CSVImportStep {
    case fieldMapping
    case wineSelection
}

enum WineField: CaseIterable {
    case name, producer, vintage, alcohol, quantity, category, country, region, subregion, type, bottleSize, readyToTrinkYear, bestBeforeYear, storageLocation, remarks, wineRating, price, noImport
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .producer: return "Producer"
        case .vintage: return "Vintage"
        case .alcohol: return "Alcohol %"
        case .quantity: return "Quantity"
        case .category: return "Category"
        case .country: return "Country"
        case .region: return "Region"
        case .subregion: return "Subregion"
        case .type: return "Type"
        case .bottleSize: return "Bottle Size"
        case .readyToTrinkYear: return "Ready to Drink Year"
        case .bestBeforeYear: return "Best Before Year"
        case .storageLocation: return "Storage Location"
        case .remarks: return "Remarks"
        case .wineRating: return "Rating"
        case .price: return "Price"
        case .noImport: return "No Import"
        }
    }
    
    static var allImportableFields: [WineField] {
        return WineField.allCases.filter { $0 != .noImport }
    }
    
    func matchesCSVHeader(_ header: String) -> Bool {
        let commonMappings: [WineField: [String]] = [
            .name: ["name", "wine", "wine name", "title"],
            .producer: ["producer", "winery", "maker", "brand"],
            .vintage: ["vintage", "year"],
            .alcohol: ["alcohol", "alcohol %", "abv", "alcohol content"],
            .quantity: ["quantity", "qty", "count", "amount"],
            .category: ["category", "type", "style", "wine type"],
            .country: ["country"],
            .region: ["region"],
            .subregion: ["subregion", "sub region", "sub-region"],
            .type: ["type", "grape", "variety"],
            .bottleSize: ["bottle size", "size", "volume"],
            .readyToTrinkYear: ["ready to drink", "ready", "drink from"],
            .bestBeforeYear: ["best before", "drink by", "best by"],
            .storageLocation: ["storage", "location", "cellar"],
            .remarks: ["remarks", "notes", "comments", "description"],
            .wineRating: ["rating", "score", "stars"],
            .price: ["price", "cost", "value"]
        ]
        
        return commonMappings[self]?.contains(header) == true
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search wines...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct ImportWineRow: View {
    let wine: ImportWine
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(wine.name ?? "Unknown Wine")
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if wine.existsInDatabase {
                        Text("EXISTS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
                
                if let producer = wine.producer {
                    Text(producer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let vintage = wine.vintage {
                        Text(vintage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let category = wine.category {
                        Text("• \(category)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Methods
    
/// Cleans alcohol value by removing % symbol and extracting numeric value
private func cleanAlcoholValue(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Remove % symbol and common alcohol-related text
    let cleanedValue = trimmed
        .replacingOccurrences(of: "%", with: "")
        .replacingOccurrences(of: "ABV", with: "", options: .caseInsensitive)
        .replacingOccurrences(of: "ALC", with: "", options: .caseInsensitive)
        .replacingOccurrences(of: "VOL", with: "", options: .caseInsensitive)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Extract numeric value with optional decimal point
    if let range = cleanedValue.range(of: "\\d+(?:\\.\\d+)?", options: .regularExpression) {
        return String(cleanedValue[range])
    }
    
    return cleanedValue
}

/// Cleans bottle size value by removing unit text and converting to milliliters
private func cleanBottleSizeValue(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Extract numeric value and unit using regex
    let pattern = "(\\d+(?:\\.\\d+)?)\\s*([a-zA-Z]+)?"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
        // If regex fails, try to extract just the number
        let numberPattern = "\\d+(?:\\.\\d+)?"
        if let numberRegex = try? NSRegularExpression(pattern: numberPattern),
           let match = numberRegex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
            return String(trimmed[Range(match.range, in: trimmed)!])
        }
        return trimmed
    }
    
    guard let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
        return trimmed
    }
    
    // Extract number
    let numberRange = match.range(at: 1)
    guard let numberSwiftRange = Range(numberRange, in: trimmed) else {
        return trimmed
    }
    let numberString = String(trimmed[numberSwiftRange])
    guard let number = Double(numberString) else {
        return trimmed
    }
    
    // Extract unit (if present)
    var unit = ""
    if match.numberOfRanges > 2 {
        let unitRange = match.range(at: 2)
        if unitRange.location != NSNotFound,
           let unitSwiftRange = Range(unitRange, in: trimmed) {
            unit = String(trimmed[unitSwiftRange]).lowercased()
        }
    }
    
    // Convert to milliliters based on unit
    let milliliters: Double
    switch unit {
    case "l", "liter", "litre", "liters", "litres":
        milliliters = number * 1000 // 1L = 1000ml
    case "cl", "centilitre", "centiliter":
        milliliters = number * 10 // 1cl = 10ml
    case "dl", "decilitre", "deciliter":
        milliliters = number * 100 // 1dl = 100ml
    case "ml", "millilitre", "milliliter", "":
        milliliters = number // Already in ml or no unit (assume ml)
    default:
        milliliters = number // Unknown unit, assume ml
    }
    
    // Return as integer string if it's a whole number, otherwise with decimals
    if milliliters == floor(milliliters) {
        return String(Int(milliliters))
    } else {
        return String(milliliters)
    }
}
