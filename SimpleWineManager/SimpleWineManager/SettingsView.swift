import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var settings: SettingsStore
    @State private var showingAddSortOrder = false
    @State private var editingSortOrder: SortOrder?
    @State private var showingWineSelection = false
    @State private var showingImportPicker = false
    @State private var showingImportView = false
    @State private var selectedImportFileURL: URL?
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    @State private var isOptimizingImages = false
    @State private var optimizationProgress = ""
    @State private var currentOptimizationIndex = 0
    @State private var totalImagesToOptimize = 0
    
    @StateObject private var exportImportManager: WineExportImportManager
    
    init(settings: SettingsStore, context: NSManagedObjectContext) {
        self.settings = settings
        _exportImportManager = StateObject(wrappedValue: WineExportImportManager(context: context, settings: settings))
    }
    
    private func formatSortOrder(_ order: SortOrder) -> Text {
        var text = Text("")
        for (index, field) in order.fields.enumerated() {
            if index > 0 {
                text = text + Text(" → ")
            }
            let fieldText = order.subtitleFields.contains(field) ?
                Text(field.rawValue).bold().foregroundColor(.blue) :
                Text(field.rawValue)
            text = text + fieldText
        }
        return text
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Manual Section
                Section {
                    NavigationLink(destination: ManualView()) {
                        HStack {
                            Image(systemName: "book.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("User Manual")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Learn how to use Wine Manager")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("Sort Orders"),
                        footer: Text("Choose your preferred wine list sort order. Fields in blue are used as section headers.")) {
                    ForEach(settings.sortOrders) { order in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: settings.selectedSortOrderId == order.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.blue)
                                Text(order.name)
                                    .font(.headline)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                settings.selectedSortOrderId = order.id
                            }
                            
                            formatSortOrder(order)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Edit") {
                                editingSortOrder = order
                            }
                            .tint(.blue)
                            
                            Button("Delete", role: .destructive) {
                                if let index = settings.sortOrders.firstIndex(where: { $0.id == order.id }) {
                                    settings.sortOrders.remove(at: index)
                                    if settings.selectedSortOrderId == order.id {
                                        settings.selectedSortOrderId = settings.sortOrders.first?.id
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: { showingAddSortOrder = true }) {
                        Label("Add Sort Order", systemImage: "plus")
                    }
                }
                
                Section(header: Text("Data Management"),
                        footer: Text("Export your wine collection to share with others, or import wines from CSV files or shared collections.")) {
                    Button(action: { showingWineSelection = true }) {
                        Label("Export Wines", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingImportPicker = true }) {
                        Label("Import Wines", systemImage: "square.and.arrow.down")
                    }
                }
                
                Section(header: Text("Currency")) {
                    Picker("Select Currency", selection: $settings.selectedCurrency) {
                        ForEach(SettingsStore.currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    Toggle("Hide wines with Qty 0", isOn: $settings.hideZeroQuantityWines)
                }
                
                Section(header: Text("Bottle Size Unit"),
                        footer: Text("This will be used as the default unit for bottle sizes.")) {
                    Picker("Select Unit", selection: $settings.bottleSizeUnit) {
                        ForEach(SettingsStore.bottleSizeUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Image Quality"),
                        footer: Text("Choose the desired image size for wine label photos. Images are automatically compressed when saved.")) {
                    Picker("Select Quality", selection: $settings.imageQuality) {
                        ForEach(ImageQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    VStack(spacing: 8) {
                        Button(action: { optimizeAllImages() }) {
                            HStack {
                                if isOptimizingImages {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Optimizing...")
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                    Text("Optimize All Images")
                                }
                            }
                        }
                        .foregroundColor(.blue)
                        .disabled(isOptimizingImages)
                        
                        if isOptimizingImages && !optimizationProgress.isEmpty {
                            Text(optimizationProgress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(
                    header: Text("AI Integration"),
                    footer: Text("Your API key is stored locally on this device. The AI will fill in empty wine fields based on the information you've already entered.")
                ) {
                    Picker("Provider", selection: $settings.aiProvider) {
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }

                    if settings.aiProvider == .openAICompatible {
                        HStack {
                            Text("Base URL")
                                .foregroundColor(.secondary)
                            TextField("https://your-server/v1", text: $settings.aiCustomBaseURL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }

                    HStack {
                        Text("API Key")
                            .foregroundColor(.secondary)
                        SecureField("sk-...", text: $settings.aiApiKey)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    HStack {
                        Text("Model")
                            .foregroundColor(.secondary)
                        TextField(settings.aiProvider.defaultModel, text: $settings.aiModel)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddSortOrder) {
                SortOrderEditView(settings: settings, sortOrder: nil)
            }
            .sheet(item: $editingSortOrder) { order in
                SortOrderEditView(settings: settings, sortOrder: order)
            }
            .sheet(isPresented: $showingWineSelection) {
                WineSelectionView(context: viewContext, settings: settings)
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.simpleWineManager, .text, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleImportFilePicker(result)
            }
            .sheet(isPresented: $showingImportView) {
                if let fileURL = selectedImportFileURL {
                    WineImportView(fileURL: fileURL, settings: settings, context: viewContext)
                }
            }
            .alert("Import Result", isPresented: $showingImportAlert) {
                Button("OK") { }
            } message: {
                Text(importAlertMessage)
            }
        }
    }
    
    private func handleImportFilePicker(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedImportFileURL = url
            showingImportView = true
            
        case .failure(let error):
            importAlertMessage = "Failed to access file: \(error.localizedDescription)"
            showingImportAlert = true
        }
    }
    
    private func optimizeAllImages() {
        Task {
            isOptimizingImages = true
            currentOptimizationIndex = 0
            optimizationProgress = ""
            await performBulkImageOptimization()
        }
    }
    
    @MainActor
    private func performBulkImageOptimization() async {
        defer {
            isOptimizingImages = false
            optimizationProgress = ""
        }
        
        // Fetch all wines with images
        let request: NSFetchRequest<Wine> = Wine.fetchRequest()
        request.predicate = NSPredicate(format: "frontImageData != nil OR backImageData != nil")
        
        do {
            let wines = try viewContext.fetch(request)
            totalImagesToOptimize = wines.count
            
            // Early exit if no wines with images
            if wines.isEmpty {
                importAlertMessage = "No wines with images found to optimize."
                showingImportAlert = true
                return
            }
            
            let targetRange = settings.imageQuality.targetSizeRange
            var optimizedCount = 0
            currentOptimizationIndex = 0
            
            // Update initial progress
            optimizationProgress = "Analyzing \(totalImagesToOptimize) wine\(totalImagesToOptimize == 1 ? "" : "s")..."
            
            // Process wines individually to show accurate progress
            for (index, wine) in wines.enumerated() {
                autoreleasepool {
                    currentOptimizationIndex = index + 1
                    optimizationProgress = "Processing \(currentOptimizationIndex)/\(totalImagesToOptimize)"
                    
                    var needsSave = false
                    
                    // Optimize front image only if it's larger than target max
                    // Never re-compress images that are already smaller than target range
                    if let frontImageData = wine.frontImageData,
                       frontImageData.count > targetRange.max,
                       let frontImage = UIImage(data: frontImageData),
                       let optimizedData = settings.compressImage(frontImage) {
                        wine.frontImageData = optimizedData
                        needsSave = true
                    }
                    
                    // Optimize back image only if it's larger than target max
                    // Never re-compress images that are already smaller than target range
                    if let backImageData = wine.backImageData,
                       backImageData.count > targetRange.max,
                       let backImage = UIImage(data: backImageData),
                       let optimizedData = settings.compressImage(backImage) {
                        wine.backImageData = optimizedData
                        needsSave = true
                    }
                    
                    if needsSave {
                        optimizedCount += 1
                    }
                }
                
                // Save every 10 wines to prevent memory buildup and show progress
                if (index + 1) % 10 == 0 || index == wines.count - 1 {
                    if viewContext.hasChanges {
                        try viewContext.save()
                    }
                }
                
                // Small delay to allow UI updates and prevent overwhelming the system
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
            // Show completion alert
            if optimizedCount > 0 {
                importAlertMessage = "Optimized \(optimizedCount) wine\(optimizedCount == 1 ? "" : "s") images to \(settings.imageQuality.displayName.lowercased()) quality."
            } else {
                importAlertMessage = "All images are already optimized for the selected quality setting."
            }
            showingImportAlert = true
            
        } catch {
            importAlertMessage = "Failed to optimize images: \(error.localizedDescription)"
            showingImportAlert = true
        }
    }
}

struct SortOrderEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings: SettingsStore
    let sortOrder: SortOrder?
    
    @State private var name: String = ""
    @State private var selectedFields: [SortField] = []
    @State private var availableFields: [SortField] = SortField.allCases
    @State private var subtitleFields: Set<SortField> = []
    
    init(settings: SettingsStore, sortOrder: SortOrder?) {
        self.settings = settings
        self.sortOrder = sortOrder
        _name = State(initialValue: sortOrder?.name ?? "")
        _selectedFields = State(initialValue: sortOrder?.fields ?? [])
        _subtitleFields = State(initialValue: sortOrder?.subtitleFields ?? [])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Sort Order Name", text: $name)
                }
                
                Section(
                    header: Text("Selected Fields"),
                    footer: Text("Toggle the checkbox to make a field appear as a subtitle in your wine list. Fields with checkboxes on will create hierarchical sections in your list.")
                ) {
                    ForEach(selectedFields, id: \.self) { field in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { subtitleFields.contains(field) },
                                set: { isOn in
                                    if isOn {
                                        subtitleFields.insert(field)
                                    } else {
                                        subtitleFields.remove(field)
                                    }
                                }
                            )) {
                                Text(field.rawValue)
                            }
                            Spacer()
                            Button {
                                withAnimation {
                                    removeField(field)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section(header: Text("Available Fields")) {
                    ForEach(availableFields.filter { !selectedFields.contains($0) }, id: \.self) { field in
                        Button(action: { addField(field) }) {
                            HStack {
                                Text(field.rawValue)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle(sortOrder == nil ? "Add Sort Order" : "Edit Sort Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSortOrder()
                        dismiss()
                    }
                    .disabled(name.isEmpty || selectedFields.isEmpty)
                }
            }
        }
    }
    
    private func addField(_ field: SortField) {
        selectedFields.append(field)
    }
    
    private func removeField(_ field: SortField) {
        selectedFields.removeAll { $0 == field }
        subtitleFields.remove(field)
    }
    
    private func saveSortOrder() {
        let newOrder = SortOrder(
            id: sortOrder?.id ?? UUID(),
            name: name,
            fields: selectedFields,
            subtitleFields: subtitleFields
        )
        
        if let existingIndex = settings.sortOrders.firstIndex(where: { $0.id == newOrder.id }) {
            settings.sortOrders[existingIndex] = newOrder
        } else {
            settings.sortOrders.append(newOrder)
            if settings.selectedSortOrderId == nil {
                settings.selectedSortOrderId = newOrder.id
            }
        }
    }
}
