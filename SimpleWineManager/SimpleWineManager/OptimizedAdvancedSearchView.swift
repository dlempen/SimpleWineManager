import SwiftUI

// MARK: - Optimized Advanced Search Criteria Model
class OptimizedAdvancedSearchCriteria: ObservableObject, Equatable {
    // Implementation of Equatable
    static func == (lhs: OptimizedAdvancedSearchCriteria, rhs: OptimizedAdvancedSearchCriteria) -> Bool {
        // Compare basic fields
        return lhs.name == rhs.name &&
               lhs.producer == rhs.producer &&
               lhs.grapes == rhs.grapes &&
               lhs.category == rhs.category &&
               lhs.country == rhs.country &&
               lhs.region == rhs.region &&
               lhs.subregion == rhs.subregion &&
               lhs.type == rhs.type &&
               lhs.storageLocation == rhs.storageLocation &&
               lhs.purchasedFrom == rhs.purchasedFrom &&
               // Compare range filters
               lhs.vintageFrom == rhs.vintageFrom &&
               lhs.vintageTo == rhs.vintageTo &&
               lhs.alcoholFrom == rhs.alcoholFrom &&
               lhs.alcoholTo == rhs.alcoholTo &&
               lhs.priceFrom == rhs.priceFrom &&
               lhs.priceTo == rhs.priceTo &&
               lhs.quantityFrom == rhs.quantityFrom &&
               lhs.quantityTo == rhs.quantityTo &&
               lhs.readyToTrinkFrom == rhs.readyToTrinkFrom &&
               lhs.readyToTrinkTo == rhs.readyToTrinkTo &&
               lhs.bestBeforeFrom == rhs.bestBeforeFrom &&
               lhs.bestBeforeTo == rhs.bestBeforeTo &&
               lhs.bottleSizeFrom == rhs.bottleSizeFrom &&
               lhs.bottleSizeTo == rhs.bottleSizeTo
    }
    // Published properties with debouncing
    @Published var name = ""
    @Published var producer = ""
    @Published var grapes = ""
    @Published var category = ""
    @Published var country = ""
    @Published var region = ""
    @Published var subregion = ""
    @Published var type = ""
    @Published var storageLocation = ""
    @Published var purchasedFrom = ""
    
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
    @Published var bottleSizeFrom = ""
    @Published var bottleSizeTo = ""
    
    // Private backing stores for debouncing
    private var debounceWorkItems: [String: DispatchWorkItem] = [:]
    private let debounceDelay: TimeInterval = 0.3
    
    func updateTextField(_ field: String, value: String) {
        // Cancel existing work item for this field
        debounceWorkItems[field]?.cancel()
        
        // Create new debounced update
        let workItem = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                self?.setFieldValue(field, value: value)
            }
        }
        
        debounceWorkItems[field] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
    }
    
    private func setFieldValue(_ field: String, value: String) {
        switch field {
        case "name": name = value
        case "producer": producer = value
        case "grapes": grapes = value
        case "storageLocation": storageLocation = value
        case "purchasedFrom": purchasedFrom = value
        case "vintageFrom": vintageFrom = value
        case "vintageTo": vintageTo = value
        case "alcoholFrom": alcoholFrom = value
        case "alcoholTo": alcoholTo = value
        case "priceFrom": priceFrom = value
        case "priceTo": priceTo = value
        case "quantityFrom": quantityFrom = value
        case "quantityTo": quantityTo = value
        case "readyToTrinkFrom": readyToTrinkFrom = value
        case "readyToTrinkTo": readyToTrinkTo = value
        case "bestBeforeFrom": bestBeforeFrom = value
        case "bestBeforeTo": bestBeforeTo = value
        case "bottleSizeFrom": bottleSizeFrom = value
        case "bottleSizeTo": bottleSizeTo = value
        default: break
        }
    }
    
    func reset() {
        // Cancel all pending debounced updates
        debounceWorkItems.values.forEach { $0.cancel() }
        debounceWorkItems.removeAll()
        
        name = ""
        producer = ""
        grapes = ""
        category = ""
        country = ""
        region = ""
        subregion = ""
        type = ""
        storageLocation = ""
        purchasedFrom = ""
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
        bottleSizeFrom = ""
        bottleSizeTo = ""
    }
    
    func hasActiveCriteria() -> Bool {
        return !name.isEmpty || !producer.isEmpty || !grapes.isEmpty || !category.isEmpty ||
               !country.isEmpty || !region.isEmpty || !subregion.isEmpty ||
               !type.isEmpty || !storageLocation.isEmpty || !purchasedFrom.isEmpty ||
               !vintageFrom.isEmpty || !vintageTo.isEmpty ||
               !alcoholFrom.isEmpty || !alcoholTo.isEmpty ||
               !priceFrom.isEmpty || !priceTo.isEmpty ||
               !quantityFrom.isEmpty || !quantityTo.isEmpty ||
               !readyToTrinkFrom.isEmpty || !readyToTrinkTo.isEmpty ||
               !bestBeforeFrom.isEmpty || !bestBeforeTo.isEmpty ||
               !bottleSizeFrom.isEmpty || !bottleSizeTo.isEmpty
    }
}

// MARK: - Optimized Wine Regions with Caching & Async Processing
class OptimizedWineRegions: ObservableObject {
    struct RegionHierarchy: Codable {
        var wineRegions: [String: [String: [String: [String: [String]]]]]
    }
    
    @Published var countries: [String] = []
    @Published var regions: [String] = []
    @Published var subregions: [String] = []
    @Published var types: [String] = []
    @Published var isLoading: Bool = false
    
    private var hierarchy: RegionHierarchy?
    private let updateQueue = DispatchQueue(label: "wine.regions.update", qos: .userInitiated)
    
    // Caching for performance
    private var regionCache: [String: [String]] = [:]
    private var subregionCache: [String: [String]] = [:]
    private var typeCache: [String: [String]] = [:]
    
    init() {
        loadRegionData()
    }
    
    private func loadRegionData() {
        updateQueue.async { [weak self] in
            do {
                guard let url = Bundle.main.url(forResource: "WineRegions", withExtension: "json") else {
                    print("WineRegions.json file not found in bundle")
                    return
                }
                
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let hierarchy = try decoder.decode(RegionHierarchy.self, from: data)
                
                DispatchQueue.main.async {
                    self?.hierarchy = hierarchy
                    let wineRegions = hierarchy.wineRegions
                    self?.countries = Array(wineRegions.keys).sorted()
                    self?.updateAllOptions()
                }
            } catch let error {
                print("Error loading wine regions: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.hierarchy = nil
                    self?.countries = []
                }
            }
        }
    }
    
    private func updateAllOptions() {
        guard let wineRegions = hierarchy?.wineRegions else { return }
        
        var allRegions = Set<String>()
        var allSubregions = Set<String>()
        var allTypes = Set<String>()
        
        for (_, regions) in wineRegions {
            for (region, subregions) in regions {
                allRegions.insert(region)
                for (subregion, typeDict) in subregions {
                    allSubregions.insert(subregion)
                    if let types = typeDict["types"] {
                        types.forEach { allTypes.insert($0) }
                    }
                }
            }
        }
        
        regions = Array(allRegions).sorted()
        subregions = Array(allSubregions).sorted()
        types = Array(allTypes).sorted()
    }
    
    func updateRegionsAsync(for country: String) {
        guard !country.isEmpty else {
            DispatchQueue.main.async {
                self.regions = []
                self.subregions = []
                self.types = []
            }
            return
        }
        
        // Check cache first
        if let cachedRegions = regionCache[country] {
            DispatchQueue.main.async {
                self.regions = cachedRegions
            }
            return
        }
        
        isLoading = true
        updateQueue.async { [weak self] in
            guard let self = self,
                  let countryRegions = self.hierarchy?.wineRegions[country] else {
                DispatchQueue.main.async {
                    self?.regions = []
                    self?.isLoading = false
                }
                return
            }
            
            let newRegions = Array(countryRegions.keys).sorted()
            
            // Cache the result
            self.regionCache[country] = newRegions
            
            DispatchQueue.main.async {
                self.regions = newRegions
                self.isLoading = false
            }
        }
    }
    
    func updateSubregionsAsync(for country: String, region: String) {
        guard !country.isEmpty && !region.isEmpty else {
            DispatchQueue.main.async {
                self.subregions = []
                self.types = []
            }
            return
        }
        
        let cacheKey = "\(country)_\(region)"
        if let cachedSubregions = subregionCache[cacheKey] {
            DispatchQueue.main.async {
                self.subregions = cachedSubregions
            }
            return
        }
        
        isLoading = true
        updateQueue.async { [weak self] in
            guard let self = self,
                  let regionSubregions = self.hierarchy?.wineRegions[country]?[region] else {
                DispatchQueue.main.async {
                    self?.subregions = []
                    self?.isLoading = false
                }
                return
            }
            
            let newSubregions = Array(regionSubregions.keys).sorted()
            self.subregionCache[cacheKey] = newSubregions
            
            DispatchQueue.main.async {
                self.subregions = newSubregions
                self.isLoading = false
            }
        }
    }
    
    func updateTypesAsync(for country: String, region: String, subregion: String) {
        guard !country.isEmpty && !region.isEmpty && !subregion.isEmpty else {
            DispatchQueue.main.async {
                self.types = []
            }
            return
        }
        
        let cacheKey = "\(country)_\(region)_\(subregion)"
        if let cachedTypes = typeCache[cacheKey] {
            DispatchQueue.main.async {
                self.types = cachedTypes
            }
            return
        }
        
        isLoading = true
        updateQueue.async { [weak self] in
            guard let self = self else { return }
            
            let newTypes = self.hierarchy?.wineRegions[country]?[region]?[subregion]?["types"] ?? []
            self.typeCache[cacheKey] = newTypes
            
            DispatchQueue.main.async {
                self.types = newTypes
                self.isLoading = false
            }
        }
    }
    
    func resetAllOptions() {
        updateAllOptions()
    }
}

// MARK: - Debounced Text Field Component
struct DebouncedTextField: View {
    let title: String
    let placeholder: String
    let fieldKey: String
    @ObservedObject var criteria: OptimizedAdvancedSearchCriteria
    let keyboardType: UIKeyboardType
    
    @State private var localText: String = ""
    @State private var isFirstAppear = true
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            TextField(placeholder, text: $localText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .onChange(of: localText) { _, newValue in
                    criteria.updateTextField(fieldKey, value: newValue)
                }
                .onAppear {
                    if isFirstAppear {
                        // Set initial value without triggering debounced update
                        switch fieldKey {
                        case "name": localText = criteria.name
                        case "producer": localText = criteria.producer
                        case "grapes": localText = criteria.grapes
                        case "storageLocation": localText = criteria.storageLocation
                        case "purchasedFrom": localText = criteria.purchasedFrom
                        case "vintageFrom": localText = criteria.vintageFrom
                        case "vintageTo": localText = criteria.vintageTo
                        case "alcoholFrom": localText = criteria.alcoholFrom
                        case "alcoholTo": localText = criteria.alcoholTo
                        case "priceFrom": localText = criteria.priceFrom
                        case "priceTo": localText = criteria.priceTo
                        case "quantityFrom": localText = criteria.quantityFrom
                        case "quantityTo": localText = criteria.quantityTo
                        case "readyToTrinkFrom": localText = criteria.readyToTrinkFrom
                        case "readyToTrinkTo": localText = criteria.readyToTrinkTo
                        case "bestBeforeFrom": localText = criteria.bestBeforeFrom
                        case "bestBeforeTo": localText = criteria.bestBeforeTo
                        case "bottleSizeFrom": localText = criteria.bottleSizeFrom
                        case "bottleSizeTo": localText = criteria.bottleSizeTo
                        default: break
                        }
                        isFirstAppear = false
                    }
                }
        }
    }
}

// MARK: - Optimized Advanced Search View
struct OptimizedAdvancedSearchView: View {
    @ObservedObject var criteria: OptimizedAdvancedSearchCriteria
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var wineRegions = OptimizedWineRegions()
    @Environment(\.dismiss) private var dismiss
    
    let wineCategories = ["Red", "White", "Rosé", "Sparkling", "Dessert", "Port"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Wine Details")) {
                    DebouncedTextField(
                        title: "Name",
                        placeholder: "Contains...",
                        fieldKey: "name",
                        criteria: criteria,
                        keyboardType: .default
                    )
                    
                    DebouncedTextField(
                        title: "Producer",
                        placeholder: "Contains...",
                        fieldKey: "producer",
                        criteria: criteria,
                        keyboardType: .default
                    )
                    
                    DebouncedTextField(
                        title: "Grapes",
                        placeholder: "Contains...",
                        fieldKey: "grapes",
                        criteria: criteria,
                        keyboardType: .default
                    )
                    
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
                    
                    DebouncedTextField(
                        title: "Storage",
                        placeholder: "Location...",
                        fieldKey: "storageLocation",
                        criteria: criteria,
                        keyboardType: .default
                    )
                    
                    DebouncedTextField(
                        title: "Purchased from",
                        placeholder: "Store, shop...",
                        fieldKey: "purchasedFrom",
                        criteria: criteria,
                        keyboardType: .default
                    )
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
                                wineRegions.updateRegionsAsync(for: newValue)
                            } else {
                                criteria.region = ""
                                criteria.subregion = ""
                                criteria.type = ""
                                wineRegions.resetAllOptions()
                            }
                        }
                        
                        if wineRegions.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.leading, 8)
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
                                wineRegions.updateSubregionsAsync(for: criteria.country, region: newValue)
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
                                wineRegions.updateTypesAsync(for: criteria.country, region: criteria.region, subregion: newValue)
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
                        DebouncedTextField(
                            title: "",
                            placeholder: "Year",
                            fieldKey: "vintageFrom",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Year",
                            fieldKey: "vintageTo",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("Alcohol Content Range (%)")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Min %",
                            fieldKey: "alcoholFrom",
                            criteria: criteria,
                            keyboardType: .decimalPad
                        )
                        .labelsHidden()
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Max %",
                            fieldKey: "alcoholTo",
                            criteria: criteria,
                            keyboardType: .decimalPad
                        )
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("Price Range (\(settings.currencySymbol))")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Min",
                            fieldKey: "priceFrom",
                            criteria: criteria,
                            keyboardType: .decimalPad
                        )
                        .labelsHidden()
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Max",
                            fieldKey: "priceTo",
                            criteria: criteria,
                            keyboardType: .decimalPad
                        )
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("Quantity Range")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Min",
                            fieldKey: "quantityFrom",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Max",
                            fieldKey: "quantityTo",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("Ready to Drink Range")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Year",
                            fieldKey: "readyToTrinkFrom",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Year",
                            fieldKey: "readyToTrinkTo",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("Best Before Range")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Year",
                            fieldKey: "bestBeforeFrom",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Year",
                            fieldKey: "bestBeforeTo",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("Bottle Size Range (\(settings.bottleSizeUnit))")) {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Min",
                            fieldKey: "bottleSizeFrom",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                        
                        Text("To")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        DebouncedTextField(
                            title: "",
                            placeholder: "Max",
                            fieldKey: "bottleSizeTo",
                            criteria: criteria,
                            keyboardType: .numberPad
                        )
                        .labelsHidden()
                    }
                }
            }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        criteria.reset()
                        wineRegions.resetAllOptions()
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
            // Initialize regions based on existing selection
            if !criteria.country.isEmpty {
                wineRegions.updateRegionsAsync(for: criteria.country)
                if !criteria.region.isEmpty {
                    wineRegions.updateSubregionsAsync(for: criteria.country, region: criteria.region)
                    if !criteria.subregion.isEmpty {
                        wineRegions.updateTypesAsync(for: criteria.country, region: criteria.region, subregion: criteria.subregion)
                    }
                }
            }
        }
    }
}

#Preview {
    OptimizedAdvancedSearchView(criteria: OptimizedAdvancedSearchCriteria())
        .environmentObject(SettingsStore())
}
