import Foundation
import CoreData
import SwiftUI

class WineHistoryService: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - History Logging Methods
    
    func logWineAdded(wine: Wine) {
        createHistoryEntry(
            wine: wine,
            action: .added,
            changeDetails: "New wine added to collection",
            quantityChange: Int16(wine.quantity)
        )
    }
    
    func logWineEdited(wine: Wine, oldValues: [String: Any?] = [:]) {
        var changeDetails: [String] = []
        var quantityChange: Int16 = 0
        
        if !oldValues.isEmpty {
            // If old values are provided, compare them
            for (field, oldValue) in oldValues {
                let newValue = getWineFieldValue(wine: wine, field: field)
                let oldStr = formatValue(oldValue)
                let newStr = formatValue(newValue)
                
                if field == "quantity", let oldQty = oldValue as? Int16 {
                    quantityChange = wine.quantity - oldQty
                    if oldQty != wine.quantity {
                        changeDetails.append("Quantity: \(oldQty) → \(wine.quantity)")
                    }
                } else if oldStr != newStr {
                    changeDetails.append("\(field.capitalized): \(oldStr) → \(newStr)")
                }
            }
        } else {
            changeDetails.append("Wine information updated")
        }
        
        createHistoryEntry(
            wine: wine,
            action: .edited,
            changeDetails: changeDetails.isEmpty ? "Wine updated" : changeDetails.joined(separator: ", "),
            quantityChange: quantityChange
        )
    }
    
    func logWineDeleted(wine: Wine) {
        createHistoryEntry(
            wine: wine,
            action: .deleted,
            changeDetails: "Wine removed from collection",
            quantityChange: -Int16(wine.quantity)
        )
    }
    
    func logWineConsumed(wine: Wine, quantityConsumed: Int) {
        createHistoryEntry(
            wine: wine,
            action: .consumed,
            changeDetails: "Consumed \(quantityConsumed) bottle\(quantityConsumed == 1 ? "" : "s")",
            quantityChange: -Int16(quantityConsumed)
        )
    }
    
    // MARK: - History Retrieval Methods
    
    func getRecentHistory(limit: Int?) -> [WineHistory] {
        let request: NSFetchRequest<WineHistory> = WineHistory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WineHistory.timestamp, ascending: false)]
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching recent history: \(error)")
            return []
        }
    }
    
    func getHistoryForWineId(_ wineId: UUID) -> [WineHistory] {
        let request: NSFetchRequest<WineHistory> = WineHistory.fetchRequest()
        request.predicate = NSPredicate(format: "wineId == %@", wineId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WineHistory.timestamp, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching history for wine: \(error)")
            return []
        }
    }
    
    func getStatistics() -> HistoryStatistics {
        let request: NSFetchRequest<WineHistory> = WineHistory.fetchRequest()
        
        do {
            let allHistory = try viewContext.fetch(request)
            return HistoryStatistics(from: allHistory)
        } catch {
            print("Error fetching statistics: \(error)")
            return HistoryStatistics()
        }
    }
    
    // MARK: - Migration Methods
    
    func migrateHistoryEntriesToIncludeRunningTotals() {
        let request: NSFetchRequest<WineHistory> = WineHistory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WineHistory.timestamp, ascending: true)]
        
        do {
            let allHistory = try viewContext.fetch(request)
            
            // Check if migration is needed (look for entries without running totals)
            let entriesNeedingMigration = allHistory.filter { $0.totalQuantityAtTime == 0 && $0.totalValueAtTime == nil }
            
            if entriesNeedingMigration.isEmpty {
                print("History migration: No entries need migration")
                return
            }
            
            print("History migration: Found \(entriesNeedingMigration.count) entries needing migration")
            
            var runningQuantity = 0
            var runningValue: Double = 0.0
            
            // Process all history entries in chronological order to calculate running totals
            for entry in allHistory {
                // Apply the quantity change
                runningQuantity += Int(entry.quantityChange)
                
                // Apply the value change
                if let price = entry.priceAtTime {
                    let valueChange = price.doubleValue * Double(entry.quantityChange)
                    runningValue += valueChange
                }
                
                // Update the entry with calculated running totals
                entry.totalQuantityAtTime = Int32(max(0, runningQuantity)) // Ensure non-negative
                entry.totalValueAtTime = NSDecimalNumber(value: max(0, runningValue)) // Ensure non-negative
            }
            
            try viewContext.save()
            print("History migration: Successfully migrated \(entriesNeedingMigration.count) entries")
            
        } catch {
            print("Error during history migration: \(error)")
            viewContext.rollback()
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateCurrentTotals() -> (totalQuantity: Int, totalValue: Double) {
        let request: NSFetchRequest<Wine> = Wine.fetchRequest()
        
        do {
            let wines = try viewContext.fetch(request)
            let totalQuantity = wines.reduce(0) { $0 + Int($1.quantity) }
            let totalValue = wines.reduce(0.0) { total, wine in
                guard let price = wine.price, price.doubleValue > 0 else { return total }
                return total + (price.doubleValue * Double(wine.quantity))
            }
            return (totalQuantity, totalValue)
        } catch {
            print("Error calculating current totals: \(error)")
            return (0, 0.0)
        }
    }
    
    private func createHistoryEntry(
        wine: Wine,
        action: WineHistory.ActionType,
        changeDetails: String,
        quantityChange: Int16
    ) {
        let history = WineHistory(context: viewContext)
        history.id = UUID()
        history.timestamp = Date()
        history.action = action.rawValue
        history.changeDetails = changeDetails
        history.wineSnapshot = createWineSnapshot(wine)
        history.quantityChange = quantityChange
        history.priceAtTime = wine.price
        history.wineName = wine.name
        history.wineProducer = wine.producer
        history.wineVintage = wine.vintage
        history.wineId = wine.id
        
        // Calculate and store running totals
        let totals = calculateCurrentTotals()
        history.totalQuantityAtTime = Int32(totals.totalQuantity)
        history.totalValueAtTime = NSDecimalNumber(value: totals.totalValue)
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving history entry: \(error)")
            viewContext.rollback()
        }
    }
    
    private func createWineSnapshot(_ wine: Wine) -> String {
        var components: [String] = []
        
        if let name = wine.name, !name.isEmpty { components.append("Name: \(name)") }
        if let producer = wine.producer, !producer.isEmpty { components.append("Producer: \(producer)") }
        if let vintage = wine.vintage, !vintage.isEmpty { components.append("Vintage: \(vintage)") }
        components.append("Quantity: \(wine.quantity)")
        if let price = wine.price, price.doubleValue > 0 { components.append("Price: $\(price)") }
        if let alcohol = wine.alcohol, !alcohol.isEmpty { components.append("Alcohol: \(alcohol)%") }
        if let bottleSize = wine.bottleSize, !bottleSize.isEmpty { components.append("Size: \(bottleSize)") }
        if let country = wine.country, !country.isEmpty { components.append("Country: \(country)") }
        if let region = wine.region, !region.isEmpty { components.append("Region: \(region)") }
        if let subregion = wine.subregion, !subregion.isEmpty { components.append("Subregion: \(subregion)") }
        if let type = wine.type, !type.isEmpty { components.append("Type: \(type)") }
        if let category = wine.category, !category.isEmpty { components.append("Category: \(category)") }
        if let storage = wine.storageLocation, !storage.isEmpty { components.append("Storage: \(storage)") }
        if let readyYear = wine.readyToTrinkYear, !readyYear.isEmpty { components.append("Ready: \(readyYear)") }
        if let bestBefore = wine.bestBeforeYear, !bestBefore.isEmpty { components.append("Best before: \(bestBefore)") }
        
        return components.joined(separator: ", ")
    }
    
    private func getWineFieldValue(wine: Wine, field: String) -> Any? {
        switch field {
        case "name": return wine.name
        case "producer": return wine.producer
        case "vintage": return wine.vintage
        case "quantity": return wine.quantity
        case "price": return wine.price
        case "alcohol": return wine.alcohol
        case "bottleSize": return wine.bottleSize
        case "country": return wine.country
        case "region": return wine.region
        case "subregion": return wine.subregion
        case "type": return wine.type
        case "category": return wine.category
        case "storageLocation": return wine.storageLocation
        case "readyToTrinkYear": return wine.readyToTrinkYear
        case "bestBeforeYear": return wine.bestBeforeYear
        default: return nil
        }
    }
    
    private func formatValue(_ value: Any?) -> String {
        guard let value = value else { return "None" }
        
        if let string = value as? String {
            return string.isEmpty ? "None" : string
        } else if let number = value as? NSDecimalNumber {
            return number.doubleValue == 0 ? "0" : "$\(number)"
        } else if let int = value as? Int16 {
            return "\(int)"
        } else {
            return "\(value)"
        }
    }
    
    // MARK: - Migration Methods
    
    func migrateExistingHistoryEntries() {
        let request: NSFetchRequest<WineHistory> = WineHistory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WineHistory.timestamp, ascending: true)]
        
        do {
            let allHistory = try viewContext.fetch(request)
            
            // Check if migration is needed (if any entry has zero values for the new fields)
            let needsMigration = allHistory.contains { entry in
                entry.totalQuantityAtTime == 0 && entry.totalValueAtTime?.doubleValue == 0
            }
            
            guard needsMigration else {
                print("History entries already have running totals - skipping migration")
                return
            }
            
            print("Migrating \(allHistory.count) history entries to include running totals...")
            
            var runningQuantity = 0
            var runningValue: Double = 0.0
            
            for entry in allHistory {
                // Update running totals based on this entry's changes
                runningQuantity += Int(entry.quantityChange)
                
                if let price = entry.priceAtTime {
                    let valueChange = price.doubleValue * Double(entry.quantityChange)
                    runningValue += valueChange
                }
                
                // Store the running totals at this point in time
                entry.totalQuantityAtTime = Int32(runningQuantity)
                entry.totalValueAtTime = NSDecimalNumber(value: max(0, runningValue))
            }
            
            try viewContext.save()
            print("Migration completed successfully")
            
        } catch {
            print("Error during history migration: \(error)")
        }
    }
}

// MARK: - History Statistics
struct HistoryStatistics {
    let totalActions: Int
    let totalWinesAdded: Int
    let totalWinesDeleted: Int
    let totalWinesConsumed: Int
    let totalEdits: Int
    let mostActiveMonth: Date?
    let mostActiveMonthCount: Int
    let totalValueAdded: Double
    let totalValueConsumed: Double
    
    init() {
        self.totalActions = 0
        self.totalWinesAdded = 0
        self.totalWinesDeleted = 0
        self.totalWinesConsumed = 0
        self.totalEdits = 0
        self.mostActiveMonth = nil
        self.mostActiveMonthCount = 0
        self.totalValueAdded = 0
        self.totalValueConsumed = 0
    }
    
    init(from history: [WineHistory]) {
        self.totalActions = history.count
        
        let addedEntries = history.filter { $0.action == WineHistory.ActionType.added.rawValue }
        let deletedEntries = history.filter { $0.action == WineHistory.ActionType.deleted.rawValue }
        let consumedEntries = history.filter { $0.action == WineHistory.ActionType.consumed.rawValue }
        let editedEntries = history.filter { $0.action == WineHistory.ActionType.edited.rawValue }
        
        self.totalWinesAdded = addedEntries.count
        self.totalWinesDeleted = deletedEntries.count
        self.totalWinesConsumed = abs(consumedEntries.reduce(0) { $0 + Int($1.quantityChange) })
        self.totalEdits = editedEntries.count
        
        // Calculate most active month
        let calendar = Calendar.current
        let monthCounts = Dictionary(grouping: history.compactMap { $0.timestamp }) { date in
            calendar.dateInterval(of: .month, for: date)?.start ?? date
        }.mapValues { $0.count }
        
        if let mostActive = monthCounts.max(by: { $0.value < $1.value }) {
            self.mostActiveMonth = mostActive.key
            self.mostActiveMonthCount = mostActive.value
        } else {
            self.mostActiveMonth = nil
            self.mostActiveMonthCount = 0
        }
        
        // Calculate total values
        self.totalValueAdded = (addedEntries).reduce(0.0) { total, entry in
            guard let price = entry.priceAtTime else { return total }
            return total + (price.doubleValue * Double(abs(entry.quantityChange)))
        }
        
        self.totalValueConsumed = (consumedEntries + deletedEntries).reduce(0.0) { total, entry in
            guard let price = entry.priceAtTime else { return total }
            return total + (price.doubleValue * Double(abs(entry.quantityChange)))
        }
    }
}
