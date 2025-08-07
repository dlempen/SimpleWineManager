import SwiftUI

// MARK: - Advanced Search Criteria Model
class AdvancedSearchCriteria: ObservableObject {
    @Published var name = ""
    @Published var producer = ""
    @Published var category = ""
    @Published var country = ""
    @Published var region = ""
    @Published var subregion = ""
    @Published var type = ""
    @Published var storageLocation = ""
    
    // Range filters
    @Published var vintageFrom = ""
    @Published var vintageTo = ""
    @Published var alcoholFrom = ""
    @Published var alcoholTo = ""
    @Published var priceFrom = ""
    @Published var priceTo = ""
    @Published var quantityFrom = ""
    @Published var quantityTo = ""
    @Published var readyToTrinkFrom = ""
    @Published var readyToTrinkTo = ""
    @Published var bestBeforeFrom = ""
    @Published var bestBeforeTo = ""
    
    // Bottle size filter
    @Published var bottleSizeFilter = ""
    
    func reset() {
        name = ""
        producer = ""
        category = ""
        country = ""
        region = ""
        subregion = ""
        type = ""
        storageLocation = ""
        vintageFrom = ""
        vintageTo = ""
        alcoholFrom = ""
        alcoholTo = ""
        priceFrom = ""
        priceTo = ""
        quantityFrom = ""
        quantityTo = ""
        readyToTrinkFrom = ""
        readyToTrinkTo = ""
        bestBeforeFrom = ""
        bestBeforeTo = ""
        bottleSizeFilter = ""
    }
    
    func hasActiveCriteria() -> Bool {
        return !name.isEmpty || !producer.isEmpty || !category.isEmpty ||
               !country.isEmpty || !region.isEmpty || !subregion.isEmpty ||
               !type.isEmpty || !storageLocation.isEmpty ||
               !vintageFrom.isEmpty || !vintageTo.isEmpty ||
               !alcoholFrom.isEmpty || !alcoholTo.isEmpty ||
               !priceFrom.isEmpty || !priceTo.isEmpty ||
               !quantityFrom.isEmpty || !quantityTo.isEmpty ||
               !readyToTrinkFrom.isEmpty || !readyToTrinkTo.isEmpty ||
               !bestBeforeFrom.isEmpty || !bestBeforeTo.isEmpty ||
               !bottleSizeFilter.isEmpty
    }
}

// MARK: - Advanced Search View
struct AdvancedSearchView: View {
    @ObservedObject var criteria: AdvancedSearchCriteria
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var wineRegions = WineRegions()
    @Environment(\.dismiss) private var dismiss
    
    let wineCategories = ["Red", "White", "Rosé", "Sparkling", "Dessert", "Port"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Wine Details")) {
                    HStack {
                        Text("Name")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("Contains...", text: $criteria.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Producer")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("Contains...", text: $criteria.producer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Category")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Picker("Category", selection: $criteria.category) {
                            Text("Any").tag("")
                            ForEach(wineCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Storage")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("Location...", text: $criteria.storageLocation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section(header: Text("Geographic Classification")) {
                    HStack {
                        Text("Country")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Picker("Country", selection: $criteria.country) {
                            Text("Any").tag("")
                            ForEach(wineRegions.countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: criteria.country) { _, newValue in
                            if !newValue.isEmpty {
                                wineRegions.updateRegions(for: newValue)
                            } else {
                                criteria.region = ""
                                criteria.subregion = ""
                                criteria.type = ""
                                wineRegions.resetAllOptions()
                            }
                        }
                    }
                    
                    HStack {
                        Text("Region")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Picker("Region", selection: $criteria.region) {
                            Text("Any").tag("")
                            ForEach(wineRegions.regions, id: \.self) { region in
                                Text(region).tag(region)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: criteria.region) { _, newValue in
                            if !newValue.isEmpty && !criteria.country.isEmpty {
                                wineRegions.updateSubregions(for: criteria.country, region: newValue)
                            } else {
                                criteria.subregion = ""
                                criteria.type = ""
                            }
                        }
                    }
                    
                    HStack {
                        Text("Subregion")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Picker("Subregion", selection: $criteria.subregion) {
                            Text("Any").tag("")
                            ForEach(wineRegions.subregions, id: \.self) { subregion in
                                Text(subregion).tag(subregion)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: criteria.subregion) { _, newValue in
                            if !newValue.isEmpty && !criteria.country.isEmpty && !criteria.region.isEmpty {
                                wineRegions.updateTypes(for: criteria.country, region: criteria.region, subregion: newValue)
                            } else {
                                criteria.type = ""
                            }
                        }
                    }
                    
                    HStack {
                        Text("Type")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Picker("Type", selection: $criteria.type) {
                            Text("Any").tag("")
                            ForEach(wineRegions.types, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("Vintage Range")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        TextField("Year", text: $criteria.vintageFrom)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        TextField("Year", text: $criteria.vintageTo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("Alcohol Content Range (%)")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        TextField("Min %", text: $criteria.alcoholFrom)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        TextField("Max %", text: $criteria.alcoholTo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Price Range (\(settings.currencySymbol))")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        TextField("Min", text: $criteria.priceFrom)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        TextField("Max", text: $criteria.priceTo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Quantity Range")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        TextField("Min", text: $criteria.quantityFrom)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        TextField("Max", text: $criteria.quantityTo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("Ready to Drink Range")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        TextField("Year", text: $criteria.readyToTrinkFrom)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        TextField("Year", text: $criteria.readyToTrinkTo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("Best Before Range")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        TextField("Year", text: $criteria.bestBeforeFrom)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        TextField("Year", text: $criteria.bestBeforeTo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("Bottle Size")) {
                    HStack {
                        Text("Size")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("e.g. 750", text: $criteria.bottleSizeFilter)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        Text(settings.bottleSizeUnit)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        criteria.reset()
                    }
                    .disabled(!criteria.hasActiveCriteria())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Update regions based on existing selection
            if !criteria.country.isEmpty {
                wineRegions.updateRegions(for: criteria.country)
                if !criteria.region.isEmpty {
                    wineRegions.updateSubregions(for: criteria.country, region: criteria.region)
                    if !criteria.subregion.isEmpty {
                        wineRegions.updateTypes(for: criteria.country, region: criteria.region, subregion: criteria.subregion)
                    }
                }
            }
        }
    }
}

#Preview {
    AdvancedSearchView(criteria: AdvancedSearchCriteria())
        .environmentObject(SettingsStore())
}
