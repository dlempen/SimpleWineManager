//
//  ContentView.swift
//  SimpleWineManager
//
//  Created by Lempen Dieter on 31.05.2025.
//

import SwiftUI
import CoreData
import Combine

class WineListViewModel: ObservableObject {
    private var viewContext: NSManagedObjectContext
    @Published private(set) var lastRefresh = Date()
    @Published var searchText = ""
    @Published var advancedSearchCriteria = AdvancedSearchCriteria()
    private var cancellables = Set<AnyCancellable>()
    
    var wines: [Wine] {
        let request: NSFetchRequest<Wine> = Wine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Wine.name, ascending: true)]
        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        
        // Listen for CoreData and manual refresh notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshData),
            name: .NSManagedObjectContextObjectsDidChange,
            object: viewContext)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshData),
            name: NSNotification.Name("WineDataDidChange"),
            object: nil)
        
        // Listen for changes in advanced search criteria to trigger UI refresh
        advancedSearchCriteria.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    @objc func refreshData() {
        DispatchQueue.main.async {
            self.lastRefresh = Date()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: WineListViewModel
    @StateObject private var settings = SettingsStore()
    @State private var showingAddWine = false
    @State private var showingSettings = false
    @State private var showingPrintView = false
    @State private var showingAdvancedSearch = false
    
    // Use standard @FetchRequest instead of a State variable
    @FetchRequest private var wines: FetchedResults<Wine>
    
    init(context: NSManagedObjectContext? = nil) {
        let context = context ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: WineListViewModel(context: context))
        
        // Initialize the FetchRequest with default sorting
        _wines = FetchRequest(
            entity: Wine.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Wine.name, ascending: true)],
            animation: .default
        )
    }
    
    private func updateSortDescriptors() {
        guard let sortOrder = settings.selectedSortOrder else { return }
        
        let sortDescriptors = sortOrder.fields.map { field -> NSSortDescriptor in
            NSSortDescriptor(key: field.keyPath, ascending: true)
        }
        
        // Update the fetch request's sort descriptors
        wines.nsSortDescriptors = sortDescriptors
    }
    
    private func groupedWines() -> [(level: Int, title: String, wine: Wine?)] {
        guard let sortOrder = settings.selectedSortOrder,
              !sortOrder.subtitleFields.isEmpty else {
            return filteredWines.map { (0, "", $0) }
        }
        
        // First, sort all wines according to the sort order
        let sortedWines = filteredWines.sorted { wine1, wine2 in
            for field in sortOrder.fields {
                let value1 = getFieldValue(field, for: wine1)
                let value2 = getFieldValue(field, for: wine2)
                if value1 != value2 {
                    return value1 < value2
                }
            }
            return false
        }
        
        // Get subtitle fields in the order they appear in fields array
        let orderedSubtitleFields = sortOrder.fields.filter { sortOrder.subtitleFields.contains($0) }
        
        var result: [(level: Int, title: String, wine: Wine?)] = []
        var previousValues: [String] = Array(repeating: "", count: orderedSubtitleFields.count)
        
        for wine in sortedWines {
            // Check if we need to add any new titles/subtitles
            for (index, field) in orderedSubtitleFields.enumerated() {
                let currentValue = getFieldValue(field, for: wine)
                
                // If this value is different from the previous, we need new titles from this level down
                if currentValue != previousValues[index] {
                    // Add titles for this level and all subsequent levels that change
                    for levelIndex in index..<orderedSubtitleFields.count {
                        let levelField = orderedSubtitleFields[levelIndex]
                        let levelValue = getFieldValue(levelField, for: wine)
                        result.append((levelIndex, levelValue, nil))
                        previousValues[levelIndex] = levelValue
                    }
                    break
                }
            }
            
            // Add the wine itself
            result.append((orderedSubtitleFields.count, "", wine))
        }
        
        return result
    }
    
    func getFieldValue(_ field: SortField, for wine: Wine) -> String {
        switch field {
        case .name: return wine.name ?? ""
        case .producer: return wine.producer ?? ""
        case .vintage: return wine.vintage ?? ""
        case .country: return wine.country ?? ""
        case .region: return wine.region ?? ""
        case .type: return wine.type ?? ""
        case .category: return wine.category ?? ""
        case .price: return wine.price?.stringValue ?? ""
        case .quantity: return String(format: "%03d", wine.quantity) // Pad with zeros for proper sorting
        case .bottleSize: 
            // Extract numeric value from bottle size for proper numerical sorting
            guard let bottleSize = wine.bottleSize else { return "00000" }
            let numericString = bottleSize.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            if let numericValue = Double(numericString) {
                return String(format: "%05.0f", numericValue) // Pad with zeros for proper sorting
            }
            return "00000" // Default for invalid values
        case .readyToTrinkYear: return wine.readyToTrinkYear ?? ""
        case .bestBeforeYear: return wine.bestBeforeYear ?? ""
        }
    }
    
    var filteredWines: [Wine] {
        let wineArray = Array(wines)
        
        // Apply basic search text filter first
        let basicFiltered: [Wine]
        if viewModel.searchText.isEmpty {
            basicFiltered = wineArray
        } else {
            let lowercasedSearch = viewModel.searchText.lowercased()
            basicFiltered = wineArray.filter { wine in
                let name = wine.name?.lowercased() ?? ""
                let producer = wine.producer?.lowercased() ?? ""
                let vintage = wine.vintage?.lowercased() ?? ""
                let alcohol = wine.alcohol?.lowercased() ?? ""
                let category = wine.category?.lowercased() ?? ""
                let country = wine.country?.lowercased() ?? ""
                let region = wine.region?.lowercased() ?? ""
                let subregion = wine.subregion?.lowercased() ?? ""
                let type = wine.type?.lowercased() ?? ""
                let bottleSize = wine.bottleSize?.lowercased() ?? ""
                let readyToTrinkYear = wine.readyToTrinkYear?.lowercased() ?? ""
                let bestBeforeYear = wine.bestBeforeYear?.lowercased() ?? ""
                let storageLocation = wine.storageLocation?.lowercased() ?? ""
                let price = wine.price?.stringValue ?? ""
                
                return name.contains(lowercasedSearch) ||
                       producer.contains(lowercasedSearch) ||
                       vintage.contains(lowercasedSearch) ||
                       alcohol.contains(lowercasedSearch) ||
                       category.contains(lowercasedSearch) ||
                       country.contains(lowercasedSearch) ||
                       region.contains(lowercasedSearch) ||
                       subregion.contains(lowercasedSearch) ||
                       type.contains(lowercasedSearch) ||
                       bottleSize.contains(lowercasedSearch) ||
                       readyToTrinkYear.contains(lowercasedSearch) ||
                       bestBeforeYear.contains(lowercasedSearch) ||
                       storageLocation.contains(lowercasedSearch) ||
                       price.contains(lowercasedSearch)
            }
        }
        
        // Apply advanced search criteria
        let criteria = viewModel.advancedSearchCriteria
        if !criteria.hasActiveCriteria() {
            return basicFiltered
        }
        
        return basicFiltered.filter { wine in
            // String field filters (case-insensitive contains)
            if !criteria.name.isEmpty {
                let wineName = wine.name?.lowercased() ?? ""
                if !wineName.contains(criteria.name.lowercased()) {
                    return false
                }
            }
            
            if !criteria.producer.isEmpty {
                let wineProducer = wine.producer?.lowercased() ?? ""
                if !wineProducer.contains(criteria.producer.lowercased()) {
                    return false
                }
            }
            
            if !criteria.category.isEmpty {
                if wine.category != criteria.category {
                    return false
                }
            }
            
            if !criteria.country.isEmpty {
                if wine.country != criteria.country {
                    return false
                }
            }
            
            if !criteria.region.isEmpty {
                if wine.region != criteria.region {
                    return false
                }
            }
            
            if !criteria.subregion.isEmpty {
                if wine.subregion != criteria.subregion {
                    return false
                }
            }
            
            if !criteria.type.isEmpty {
                if wine.type != criteria.type {
                    return false
                }
            }
            
            if !criteria.storageLocation.isEmpty {
                let wineStorage = wine.storageLocation?.lowercased() ?? ""
                if !wineStorage.contains(criteria.storageLocation.lowercased()) {
                    return false
                }
            }
            
            // Vintage range filter
            if !criteria.vintageFrom.isEmpty || !criteria.vintageTo.isEmpty {
                guard let vintageString = wine.vintage,
                      let vintage = Int(vintageString) else {
                    return false
                }
                
                if !criteria.vintageFrom.isEmpty {
                    if let fromYear = Int(criteria.vintageFrom), vintage < fromYear {
                        return false
                    }
                }
                
                if !criteria.vintageTo.isEmpty {
                    if let toYear = Int(criteria.vintageTo), vintage > toYear {
                        return false
                    }
                }
            }
            
            // Alcohol range filter
            if !criteria.alcoholFrom.isEmpty || !criteria.alcoholTo.isEmpty {
                guard let alcoholString = wine.alcohol?.replacingOccurrences(of: "%", with: ""),
                      let alcohol = Double(alcoholString) else {
                    return false
                }
                
                if !criteria.alcoholFrom.isEmpty {
                    if let fromAlcohol = Double(criteria.alcoholFrom), alcohol < fromAlcohol {
                        return false
                    }
                }
                
                if !criteria.alcoholTo.isEmpty {
                    if let toAlcohol = Double(criteria.alcoholTo), alcohol > toAlcohol {
                        return false
                    }
                }
            }
            
            // Price range filter
            if !criteria.priceFrom.isEmpty || !criteria.priceTo.isEmpty {
                guard let priceDecimal = wine.price,
                      let price = Double(priceDecimal.stringValue) else {
                    return false
                }
                
                if !criteria.priceFrom.isEmpty {
                    if let fromPrice = Double(criteria.priceFrom), price < fromPrice {
                        return false
                    }
                }
                
                if !criteria.priceTo.isEmpty {
                    if let toPrice = Double(criteria.priceTo), price > toPrice {
                        return false
                    }
                }
            }
            
            // Quantity range filter
            if !criteria.quantityFrom.isEmpty || !criteria.quantityTo.isEmpty {
                let quantity = Int(wine.quantity)
                
                if !criteria.quantityFrom.isEmpty {
                    if let fromQuantity = Int(criteria.quantityFrom), quantity < fromQuantity {
                        return false
                    }
                }
                
                if !criteria.quantityTo.isEmpty {
                    if let toQuantity = Int(criteria.quantityTo), quantity > toQuantity {
                        return false
                    }
                }
            }
            
            // Ready to drink range filter
            if !criteria.readyToTrinkFrom.isEmpty || !criteria.readyToTrinkTo.isEmpty {
                guard let readyString = wine.readyToTrinkYear,
                      let readyYear = Int(readyString) else {
                    return false
                }
                
                if !criteria.readyToTrinkFrom.isEmpty {
                    if let fromYear = Int(criteria.readyToTrinkFrom), readyYear < fromYear {
                        return false
                    }
                }
                
                if !criteria.readyToTrinkTo.isEmpty {
                    if let toYear = Int(criteria.readyToTrinkTo), readyYear > toYear {
                        return false
                    }
                }
            }
            
            // Best before range filter
            if !criteria.bestBeforeFrom.isEmpty || !criteria.bestBeforeTo.isEmpty {
                guard let bestBeforeString = wine.bestBeforeYear,
                      let bestBeforeYear = Int(bestBeforeString) else {
                    return false
                }
                
                if !criteria.bestBeforeFrom.isEmpty {
                    if let fromYear = Int(criteria.bestBeforeFrom), bestBeforeYear < fromYear {
                        return false
                    }
                }
                
                if !criteria.bestBeforeTo.isEmpty {
                    if let toYear = Int(criteria.bestBeforeTo), bestBeforeYear > toYear {
                        return false
                    }
                }
            }
            
            // Bottle size filter
            if !criteria.bottleSizeFilter.isEmpty {
                guard let bottleSize = wine.bottleSize else {
                    return false
                }
                
                // Extract numeric value from bottle size
                let numericString = bottleSize.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                if let bottleSizeValue = Double(numericString) {
                    // Convert filter value to ml if needed based on settings
                    let filterInMl = settings.convertToMilliliters(criteria.bottleSizeFilter, from: settings.bottleSizeUnit)
                    if let filterMl = Double(filterInMl.replacingOccurrences(of: "ml", with: "")) {
                        if abs(bottleSizeValue - filterMl) > 1.0 { // Allow small tolerance
                            return false
                        }
                    }
                }
            }
            
            return true
        }
    }

    var totalQuantity: Int {
        filteredWines.reduce(0) { $0 + Int($1.quantity) }
    }
    
    var totalBottleSize: Double {
        filteredWines.reduce(0.0) { total, wine in
            guard let bottleSize = wine.bottleSize else { return total }
            // Extract numeric value from bottle size (e.g., "750ml" -> 750)
            let numericString = bottleSize.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            if let numericValue = Double(numericString) {
                return total + (numericValue * Double(wine.quantity))
            }
            return total
        }
    }
    
    var totalPrice: Decimal {
        filteredWines.reduce(0) { total, wine in
            guard let price = wine.price, price != 0 else { return total }
            return total + (price.decimalValue * Decimal(wine.quantity))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Title Header
                HStack {
                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Text("Simple Wine Manager")
                        .font(.system(size: 100, weight: .bold, design: .default))
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 44)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Search Bar and Total Quantity
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        TextField("Search wines...", text: $viewModel.searchText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: {
                            showingAdvancedSearch = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(viewModel.advancedSearchCriteria.hasActiveCriteria() ? .accentColor : .secondary)
                                .font(.system(size: 16, weight: viewModel.advancedSearchCriteria.hasActiveCriteria() ? .bold : .regular))
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewModel.advancedSearchCriteria.hasActiveCriteria() ? Color.accentColor.opacity(0.1) : Color.clear)
                                        .strokeBorder(
                                            viewModel.advancedSearchCriteria.hasActiveCriteria() ? Color.accentColor : Color.secondary.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    
                    // Show active advanced search indicator
                    if viewModel.advancedSearchCriteria.hasActiveCriteria() {
                        HStack {
                            Text("Advanced filters active")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            
                            Button("Clear") {
                                viewModel.advancedSearchCriteria.reset()
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Total Quantity aligned with wine item quantities
                    HStack {
                        Text("Total Qty: \(totalQuantity)")
                        if totalBottleSize > 0 {
                            Text("•")
                            Text(settings.getDisplayBottleSize("\(Int(totalBottleSize))ml"))
                        }
                        if totalPrice > 0 {
                            Text("•")
                            Text("\(totalPrice) \(settings.currencySymbol)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                }
                
                // Wine List with hierarchical sections
                List {
                    ForEach(Array(groupedWines().enumerated()), id: \.offset) { index, group in
                        if let wine = group.wine {
                            // Display single wine
                            let wineDetail = WineDetailView(wine: wine).environmentObject(settings)
                            let wineId = "\(wine.id?.uuidString ?? "")-\(wine.quantity)-\(viewModel.lastRefresh)"
                            
                            NavigationLink(destination: wineDetail) {
                                WineRowView(wine: wine)
                            }
                            .id(wineId)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    deleteWine(wine)
                                }
                            }
                            .listRowSeparator(.visible)
                            .deleteDisabled(false)
                        } else if !group.title.isEmpty {
                            // Display section title with custom separator
                            let fontSize = group.level == 0 ? 28.0 : 22.0
                            let fontWeight: Font.Weight = group.level == 0 ? .bold : .regular
                            let topPadding = group.level == 0 ? 16.0 : 8.0
                            let textColor = group.level == 0 ? Color.primary : Color.secondary
                            
                            VStack(spacing: 0) {
                                Text(formatSectionTitle(group.title))
                                    .font(.system(size: fontSize))
                                    .fontWeight(fontWeight)
                                    .padding(.top, topPadding)
                                    .padding(.bottom, 4)
                                    .foregroundStyle(textColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                // Add very thin separator line after title if next item is a wine
                                if shouldShowSeparatorAfterTitle(at: index, in: groupedWines()) {
                                    Divider()
                                        .padding(.horizontal, 16)
                                        .opacity(0.6)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .deleteDisabled(true)
                        }
                    }
                    .onDelete(perform: deleteWinesFromList)
                }
                .listStyle(.plain)
                .listStyle(.plain)
                .refreshable {
                    viewContext.rollback() // Discard any pending changes
                    viewModel.refreshData()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                        }
                        Button(action: {
                            showingPrintView = true
                        }) {
                            Image(systemName: "printer")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddWine = true
                    }) {
                        Label("Add Wine", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWine) {
                NavigationStack {
                    AddWineView()
                        .environmentObject(settings)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings, context: viewContext)
            }
            .sheet(isPresented: $showingPrintView) {
                PrintView(viewModel: viewModel)
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showingAdvancedSearch) {
                AdvancedSearchView(criteria: viewModel.advancedSearchCriteria)
                    .environmentObject(settings)
            }
        }
        .environmentObject(settings)
        .onChange(of: settings.selectedSortOrderId) { _, _ in
            updateSortDescriptors()
        }
        .onChange(of: settings.sortOrders) { _, newValue in
            // If the current sort order was deleted, update to use the first available one
            if let currentId = settings.selectedSortOrderId,
               !newValue.contains(where: { $0.id == currentId }) {
                settings.selectedSortOrderId = newValue.first?.id
            }
            updateSortDescriptors()
        }
        .onAppear {
            updateSortDescriptors()
        }
    }

    private func deleteWine(_ wine: Wine) {
        withAnimation {
            viewContext.delete(wine)
            try? viewContext.save()
            viewModel.refreshData()
        }
    }
    
    private func deleteWinesFromList(offsets: IndexSet) {
        withAnimation {
            let groupedItems = groupedWines()
            for index in offsets {
                if let wine = groupedItems[index].wine {
                    viewContext.delete(wine)
                }
            }
            try? viewContext.save()
            viewModel.refreshData()
        }
    }
    
    private func shouldShowSeparatorAfterTitle(at index: Int, in groups: [(level: Int, title: String, wine: Wine?)]) -> Bool {
        // Check if the next item is a wine
        if index < groups.count - 1 {
            let nextGroup = groups[index + 1]
            return nextGroup.wine != nil
        }
        return false
    }
    
    private func formatSectionTitle(_ title: String) -> String {
        // Check if the title looks like a padded bottle size (e.g., "00750")
        if title.count == 5 && title.allSatisfy(\.isNumber) {
            // Remove leading zeros and add unit
            let numericValue = Int(title) ?? 0
            if numericValue > 0 {
                return settings.getDisplayBottleSize("\(numericValue)ml")
            }
        }
        
        // Check if it's a padded quantity (e.g., "001", "012")
        if title.count == 3 && title.allSatisfy(\.isNumber) {
            let numericValue = Int(title) ?? 0
            return "\(numericValue)"
        }
        
        return title
    }
}

struct WineRowView: View {
    @ObservedObject var wine: Wine
    @EnvironmentObject var settings: SettingsStore
    
    var body: some View {
        VStack(alignment: .leading) {
            // Always show name and vintage as the main title
            Text("\(wine.name ?? "Unknown") \(wine.vintage ?? "")")
                .font(.headline)
            // Always show producer as the secondary line
            Text(wine.producer ?? "-")
                .font(.subheadline)
            // Bottom metadata line
            HStack {
                Text("Qty: \(wine.quantity)")
                if let size = wine.bottleSize, !size.isEmpty {
                    Text("•")
                    Text(settings.getDisplayBottleSize(size))
                }
                if let alcohol = wine.alcohol, !alcohol.isEmpty {
                    Text("•")
                    Text("\(alcohol)%")
                }
                if let price = wine.price, price != 0,
                   !(settings.selectedSortOrder?.fields.contains(.price) ?? false) {
                    Text("•")
                    Text("\(price) \(settings.currencySymbol)")
                }
                if let storageLocation = wine.storageLocation, !storageLocation.isEmpty {
                    Text("•")
                    Text(storageLocation)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SettingsStore())
}
