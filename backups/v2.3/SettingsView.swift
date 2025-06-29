import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings: SettingsStore
    @State private var showingAddSortOrder = false
    @State private var editingSortOrder: SortOrder?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sort Orders"),
                        footer: Text("Choose your preferred wine list sort order.")) {
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
                            
                            Text(order.fields.map(\.rawValue).joined(separator: " → "))
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
                
                Section(header: Text("Currency")) {
                    Picker("Select Currency", selection: $settings.selectedCurrency) {
                        ForEach(SettingsStore.currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
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
    
    init(settings: SettingsStore, sortOrder: SortOrder?) {
        self.settings = settings
        self.sortOrder = sortOrder
        _name = State(initialValue: sortOrder?.name ?? "")
        _selectedFields = State(initialValue: sortOrder?.fields ?? [])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Sort Order Name", text: $name)
                }
                
                Section(header: Text("Selected Fields")) {
                    ForEach(selectedFields, id: \.self) { field in
                        HStack {
                            Text(field.rawValue)
                            Spacer()
                            if selectedFields.firstIndex(of: field) != 0 {
                                Button(action: { moveUp(field) }) {
                                    Image(systemName: "arrow.up")
                                }
                            }
                            Button(action: { removeField(field) }) {
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
    }
    
    private func moveUp(_ field: SortField) {
        guard let index = selectedFields.firstIndex(of: field),
              index > 0 else { return }
        selectedFields.swapAt(index, index - 1)
    }
    
    private func saveSortOrder() {
        let newOrder = SortOrder(
            id: sortOrder?.id ?? UUID(),
            name: name,
            fields: selectedFields
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
