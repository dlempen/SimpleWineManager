//
//  ContentView.swift
//  SimpleWineManager
//
//  Created by Lempen Dieter on 31.05.2025.
//

import SwiftUI
import CoreData

class WineListViewModel: ObservableObject {
    private var viewContext: NSManagedObjectContext
    @Published private(set) var lastRefresh = Date()
    @Published var searchText = ""
    
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
    }
    
    @objc func refreshData() {
        DispatchQueue.main.async {
            self.lastRefresh = Date()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: WineListViewModel
    @StateObject private var settings = SettingsStore()
    @StateObject private var historyService = WineHistoryService(context: PersistenceController.shared.container.viewContext)
    @StateObject private var advancedSearchCriteria = AdvancedSearchCriteria()
    @State private var showingAddWine = false
    @State private var showingSettings = false
    @State private var showingPrintView = false
    @State private var showingAdvancedSearch = false
    @State private var showingHistory = false
    
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
        let searchText = viewModel.searchText.lowercased()
        
        var filtered = Array(wines)
        
        // Hide wines with quantity 0 if the setting is enabled
        if settings.hideZeroQuantityWines {
            filtered = filtered.filter { $0.quantity > 0 }
        }
        
        // Apply basic text search if not empty
        if !searchText.isEmpty {
            filtered = filtered.filter { wine in
                wineMatchesSearch(wine: wine, searchTerm: searchText)
            }
        }
        
        // Apply advanced search criteria if any are active
        if advancedSearchCriteria.hasActiveCriteria() {
            filtered = filtered.filter { wine in
                wineMatchesAdvancedCriteria(wine: wine, criteria: advancedSearchCriteria)
            }
        }
        
        return filtered
    }
    
    private func wineMatchesSearch(wine: Wine, searchTerm: String) -> Bool {
        // Check each field individually to avoid complex array operations
        if let name = wine.name, name.lowercased().contains(searchTerm) { return true }
        if let producer = wine.producer, producer.lowercased().contains(searchTerm) { return true }
        if let vintage = wine.vintage, vintage.lowercased().contains(searchTerm) { return true }
        if let alcohol = wine.alcohol, alcohol.lowercased().contains(searchTerm) { return true }
        if let grapes = wine.grapes, grapes.lowercased().contains(searchTerm) { return true }
        if let category = wine.category, category.lowercased().contains(searchTerm) { return true }
        if let country = wine.country, country.lowercased().contains(searchTerm) { return true }
        if let region = wine.region, region.lowercased().contains(searchTerm) { return true }
        if let subregion = wine.subregion, subregion.lowercased().contains(searchTerm) { return true }
        if let type = wine.type, type.lowercased().contains(searchTerm) { return true }
        if let bottleSize = wine.bottleSize, bottleSize.lowercased().contains(searchTerm) { return true }
        if let readyYear = wine.readyToTrinkYear, readyYear.lowercased().contains(searchTerm) { return true }
        if let bestYear = wine.bestBeforeYear, bestYear.lowercased().contains(searchTerm) { return true }
        if let location = wine.storageLocation, location.lowercased().contains(searchTerm) { return true }
        if let purchasedFrom = wine.purchasedFrom, purchasedFrom.lowercased().contains(searchTerm) { return true }
        if let price = wine.price?.stringValue, price.contains(searchTerm) { return true }
        return false
    }
    
    private func wineMatchesAdvancedCriteria(wine: Wine, criteria: AdvancedSearchCriteria) -> Bool {
        // Text field filters (contains)
        if !criteria.name.isEmpty {
            guard let name = wine.name, name.lowercased().contains(criteria.name.lowercased()) else { return false }
        }
        
        if !criteria.producer.isEmpty {
            guard let producer = wine.producer, producer.lowercased().contains(criteria.producer.lowercased()) else { return false }
        }
        
        if !criteria.grapes.isEmpty {
            guard let grapes = wine.grapes, grapes.lowercased().contains(criteria.grapes.lowercased()) else { return false }
        }
        
        if !criteria.storageLocation.isEmpty {
            guard let location = wine.storageLocation, location.lowercased().contains(criteria.storageLocation.lowercased()) else { return false }
        }
        
        if !criteria.purchasedFrom.isEmpty {
            guard let purchasedFrom = wine.purchasedFrom, purchasedFrom.lowercased().contains(criteria.purchasedFrom.lowercased()) else { return false }
        }
        
        // Exact match filters
        if !criteria.category.isEmpty {
            guard wine.category == criteria.category else { return false }
        }
        
        if !criteria.country.isEmpty {
            guard wine.country == criteria.country else { return false }
        }
        
        if !criteria.region.isEmpty {
            guard wine.region == criteria.region else { return false }
        }
        
        if !criteria.subregion.isEmpty {
            guard wine.subregion == criteria.subregion else { return false }
        }
        
        if !criteria.type.isEmpty {
            guard wine.type == criteria.type else { return false }
        }
        
        // Range filters
        if !criteria.vintageFrom.isEmpty || !criteria.vintageTo.isEmpty {
            guard let vintage = wine.vintage, let vintageYear = Int(vintage) else { return false }
            
            if !criteria.vintageFrom.isEmpty, let fromYear = Int(criteria.vintageFrom) {
                guard vintageYear >= fromYear else { return false }
            }
            
            if !criteria.vintageTo.isEmpty, let toYear = Int(criteria.vintageTo) {
                guard vintageYear <= toYear else { return false }
            }
        }
        
        if !criteria.alcoholFrom.isEmpty || !criteria.alcoholTo.isEmpty {
            guard let alcoholStr = wine.alcohol, let alcoholValue = Double(alcoholStr.replacingOccurrences(of: "%", with: "")) else { return false }
            
            if !criteria.alcoholFrom.isEmpty, let fromAlcohol = Double(criteria.alcoholFrom) {
                guard alcoholValue >= fromAlcohol else { return false }
            }
            
            if !criteria.alcoholTo.isEmpty, let toAlcohol = Double(criteria.alcoholTo) {
                guard alcoholValue <= toAlcohol else { return false }
            }
        }
        
        if !criteria.priceFrom.isEmpty || !criteria.priceTo.isEmpty {
            guard let price = wine.price, price != 0 else { return false }
            let priceValue = price.doubleValue
            
            if !criteria.priceFrom.isEmpty, let fromPrice = Double(criteria.priceFrom) {
                guard priceValue >= fromPrice else { return false }
            }
            
            if !criteria.priceTo.isEmpty, let toPrice = Double(criteria.priceTo) {
                guard priceValue <= toPrice else { return false }
            }
        }
        
        if !criteria.quantityFrom.isEmpty || !criteria.quantityTo.isEmpty {
            let quantity = Int(wine.quantity)
            
            if !criteria.quantityFrom.isEmpty, let fromQty = Int(criteria.quantityFrom) {
                guard quantity >= fromQty else { return false }
            }
            
            if !criteria.quantityTo.isEmpty, let toQty = Int(criteria.quantityTo) {
                guard quantity <= toQty else { return false }
            }
        }
        
        if !criteria.readyToTrinkFrom.isEmpty || !criteria.readyToTrinkTo.isEmpty {
            guard let readyYear = wine.readyToTrinkYear, let readyYearInt = Int(readyYear) else { return false }
            
            if !criteria.readyToTrinkFrom.isEmpty, let fromYear = Int(criteria.readyToTrinkFrom) {
                guard readyYearInt >= fromYear else { return false }
            }
            
            if !criteria.readyToTrinkTo.isEmpty, let toYear = Int(criteria.readyToTrinkTo) {
                guard readyYearInt <= toYear else { return false }
            }
        }
        
        if !criteria.bestBeforeFrom.isEmpty || !criteria.bestBeforeTo.isEmpty {
            guard let bestYear = wine.bestBeforeYear, let bestYearInt = Int(bestYear) else { return false }
            
            if !criteria.bestBeforeFrom.isEmpty, let fromYear = Int(criteria.bestBeforeFrom) {
                guard bestYearInt >= fromYear else { return false }
            }
            
            if !criteria.bestBeforeTo.isEmpty, let toYear = Int(criteria.bestBeforeTo) {
                guard bestYearInt <= toYear else { return false }
            }
        }
        
        if !criteria.bottleSizeFrom.isEmpty || !criteria.bottleSizeTo.isEmpty {
            guard let bottleSize = wine.bottleSize else { return false }
            let numericString = bottleSize.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            guard let bottleSizeValue = Double(numericString) else { return false }
            
            // Convert user input from their chosen unit to ml for comparison
            if !criteria.bottleSizeFrom.isEmpty, let fromSizeInput = Double(criteria.bottleSizeFrom) {
                let fromSizeInMl = Double(settings.convertToMilliliters(String(fromSizeInput), from: settings.bottleSizeUnit)) ?? fromSizeInput
                guard bottleSizeValue >= fromSizeInMl else { return false }
            }
            
            if !criteria.bottleSizeTo.isEmpty, let toSizeInput = Double(criteria.bottleSizeTo) {
                let toSizeInMl = Double(settings.convertToMilliliters(String(toSizeInput), from: settings.bottleSizeUnit)) ?? toSizeInput
                guard bottleSizeValue <= toSizeInMl else { return false }
            }
        }
        
        return true
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
                titleHeader
                searchAndTotalsSection
                wineListSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    leadingToolbarButtons
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    addWineButton
                }
            }
            .sheet(isPresented: $showingAddWine) {
                NavigationStack {
                    AddWineView(historyService: historyService)
                        .environmentObject(settings)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings, context: viewContext)
            }
            .sheet(isPresented: $showingPrintView) {
                PrintView(viewModel: viewModel, advancedSearchCriteria: advancedSearchCriteria)
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showingAdvancedSearch) {
                NavigationStack {
                    AdvancedSearchView(criteria: advancedSearchCriteria)
                        .environmentObject(settings)
                }
            }
            .sheet(isPresented: $showingHistory) {
                WineHistoryView(historyService: historyService)
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
    
    // MARK: - Subviews
    
    private var titleHeader: some View {
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
    }
    
    private var searchAndTotalsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Search wines...", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    showingAdvancedSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            // Show advanced filters active indicator with clear button
            if advancedSearchCriteria.hasActiveCriteria() {
                HStack {
                    Text("Advanced filters active")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Button("Clear") {
                        advancedSearchCriteria.reset()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
            
            totalsDisplay
        }
    }
    
    private var totalsDisplay: some View {
        HStack {
            Text("Total Qty: \(totalQuantity)")
            if totalBottleSize > 0 {
                Text("•")
                Text(settings.getDisplayBottleSize("\(Int(totalBottleSize))ml"))
            }
            if totalPrice > 0 {
                Text("•")
                Text("\(NSDecimalNumber(decimal: totalPrice).stringValue) \(settings.currencySymbol)")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }
    
    private var wineListSection: some View {
        List {
            ForEach(Array(groupedWines().enumerated()), id: \.offset) { index, group in
                if let wine = group.wine {
                    wineRowSection(wine: wine)
                } else if !group.title.isEmpty {
                    sectionTitleView(group: group, index: index)
                }
            }
            .onDelete(perform: deleteWinesFromList)
        }
        .listStyle(.plain)
        .refreshable {
            viewContext.rollback() // Discard any pending changes
            viewModel.refreshData()
        }
    }
    
    private func wineRowSection(wine: Wine) -> some View {
        let wineDetail = WineDetailView(wine: wine).environmentObject(settings)
        let wineId = "\(wine.id?.uuidString ?? "")-\(wine.quantity)-\(viewModel.lastRefresh)"
        
        return NavigationLink(destination: wineDetail) {
            WineRowView(wine: wine)
        }
        .id(wineId)
        .swipeActions(edge: .leading) {
            Button {
                consumeWine(wine)
            } label: {
                Label("Consume", systemImage: "wineglass.fill")
            }
            .tint(.orange)
            .disabled(wine.quantity <= 0)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteWine(wine)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .listRowSeparator(.visible)
        .deleteDisabled(false)
    }
    
    private func sectionTitleView(group: (level: Int, title: String, wine: Wine?), index: Int) -> some View {
        let fontSize = group.level == 0 ? 28.0 : 22.0
        let fontWeight: Font.Weight = group.level == 0 ? .bold : .regular
        let topPadding = group.level == 0 ? 16.0 : 8.0
        let textColor = group.level == 0 ? Color.primary : Color.secondary
        
        return VStack(spacing: 0) {
            Text(formatSectionTitle(group.title))
                .font(.system(size: fontSize))
                .fontWeight(fontWeight)
                .padding(.top, topPadding)
                .padding(.bottom, 4)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
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
    
    private var leadingToolbarButtons: some View {
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
            Button(action: {
                showingHistory = true
            }) {
                Image(systemName: "clock")
            }
        }
    }
    
    private var addWineButton: some View {
        Button(action: {
            showingAddWine = true
        }) {
            Label("Add Wine", systemImage: "plus")
        }
    }

    private func consumeWine(_ wine: Wine) {
        // Don't consume if there's nothing to consume
        guard wine.quantity > 0 else { return }
        
        withAnimation {
            let oldQuantity = wine.quantity
            wine.quantity -= 1
            
            do {
                try viewContext.save()
                viewContext.refresh(wine, mergeChanges: true)
                wine.objectWillChange.send()
                viewModel.refreshData()
                
                // Note: History service would need to be initialized here if needed
                // For now, we're keeping it simple without history logging
                
            } catch {
                print("Error saving context: \(error)")
                wine.quantity = oldQuantity
            }
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
