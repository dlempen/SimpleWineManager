import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings: SettingsStore
    @State private var showingAddSortOrder = false
    @State private var editingSortOrder: SortOrder?
    
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
                
                Section(header: Text("Print Settings"),
                        footer: Text("Customize the title and subtitle for printed wine lists.")) {
                    HStack {
                        Text("Print Title")
                        Spacer()
                        TextField("Title", text: $settings.printTitle)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Print Subtitle")
                        Spacer()
                        TextField("Subtitle", text: $settings.printSubtitle)
                            .multilineTextAlignment(.trailing)
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
