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
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    
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
                Section(header: Text("Bottle Size Unit"),
                        footer: Text("This will be used as the default unit for bottle sizes.")) {
                    Picker("Select Unit", selection: $settings.bottleSizeUnit) {
                        ForEach(SettingsStore.bottleSizeUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Currency")) {
                    Picker("Select Currency", selection: $settings.selectedCurrency) {
                        ForEach(SettingsStore.currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
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
                        footer: Text("Export your wine collection to share with others, or import wines from a shared collection.")) {
                    Button(action: { showingWineSelection = true }) {
                        Label("Export Wines", systemImage: "square.and.arrow.up")
                    }
                    
                    Toggle("Import with quantity", isOn: $settings.importWithQuantity)
                        .help("When enabled, imported wines will keep their original quantities. When disabled, all imported wines will have quantity set to 0.")
                    
                    Button(action: { showingImportPicker = true }) {
                        Label("Import Wines", systemImage: "square.and.arrow.down")
                    }
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
                allowedContentTypes: [.simpleWineManager],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Import Result", isPresented: $showingImportAlert) {
                Button("OK") { }
            } message: {
                Text(importAlertMessage)
            }
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let importResult = exportImportManager.importWines(from: url)
            switch importResult {
            case .success(let result):
                if result.skipped > 0 {
                    importAlertMessage = "Import complete!\n• \(result.imported) wine\(result.imported == 1 ? "" : "s") imported\n• \(result.skipped) duplicate\(result.skipped == 1 ? "" : "s") skipped"
                } else {
                    importAlertMessage = "Successfully imported \(result.imported) wine\(result.imported == 1 ? "" : "s")."
                }
                
                // Notify the app that data changed
                NotificationCenter.default.post(name: NSNotification.Name("WineDataDidChange"), object: nil)
                
            case .failure(let error):
                importAlertMessage = "Import failed: \(error.localizedDescription)"
            }
            showingImportAlert = true
            
        case .failure(let error):
            importAlertMessage = "Failed to access file: \(error.localizedDescription)"
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
