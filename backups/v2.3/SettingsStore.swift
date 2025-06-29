import Foundation

struct SortOrder: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var fields: [SortField]
    
    init(id: UUID = UUID(), name: String, fields: [SortField]) {
        self.id = id
        self.name = name
        self.fields = fields
    }
}

enum SortField: String, Codable, CaseIterable {
    case name = "Name"
    case producer = "Producer"
    case vintage = "Vintage"
    case country = "Country"
    case region = "Region"
    case type = "Type"
    case category = "Category"
    case price = "Price"
    
    var keyPath: String {
        switch self {
        case .name: return "name"
        case .producer: return "producer"
        case .vintage: return "vintage"
        case .country: return "country"
        case .region: return "region"
        case .type: return "type"
        case .category: return "category"
        case .price: return "price"
        }
    }
}

class SettingsStore: ObservableObject {
    @Published var selectedCurrency: String {
        didSet {
            UserDefaults.standard.set(selectedCurrency, forKey: "selectedCurrency")
        }
    }
    
    @Published var bottleSizeUnit: String {
        didSet {
            UserDefaults.standard.set(bottleSizeUnit, forKey: "bottleSizeUnit")
        }
    }
    
    @Published var sortOrders: [SortOrder] {
        didSet {
            if let encoded = try? JSONEncoder().encode(sortOrders) {
                UserDefaults.standard.set(encoded, forKey: "sortOrders")
            }
        }
    }
    
    @Published var selectedSortOrderId: UUID? {
        didSet {
            UserDefaults.standard.set(selectedSortOrderId?.uuidString, forKey: "selectedSortOrderId")
        }
    }
    
    static let currencies = [
        "USD ($)", "EUR (€)", "JPY (¥)", "GBP (£)", "CNY (¥)", 
        "AUD ($)", "CAD ($)", "CHF (Fr)", "HKD ($)", "SGD ($)", 
        "INR (₹)", "NZD ($)", "SEK (kr)", "KRW (₩)", "NOK (kr)"
    ]
    
    static let bottleSizeUnits = ["ml", "cl", "dl", "l"]
    
    // Default sort orders
    static let defaultSortOrders = [
        SortOrder(name: "Producer", fields: [.producer, .type, .vintage]),
        SortOrder(name: "Country", fields: [.country, .producer, .type, .vintage])
    ]
    
    init() {
        self.selectedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "EUR (€)"
        self.bottleSizeUnit = UserDefaults.standard.string(forKey: "bottleSizeUnit") ?? "ml"
        
        // Load sort orders
        if let data = UserDefaults.standard.data(forKey: "sortOrders"),
           let decoded = try? JSONDecoder().decode([SortOrder].self, from: data) {
            self.sortOrders = decoded
        } else {
            self.sortOrders = SettingsStore.defaultSortOrders
        }
        
        // Load selected sort order
        if let idString = UserDefaults.standard.string(forKey: "selectedSortOrderId"),
           let id = UUID(uuidString: idString) {
            self.selectedSortOrderId = id
        } else {
            self.selectedSortOrderId = sortOrders.first?.id
        }
    }
    
    var selectedSortOrder: SortOrder? {
        sortOrders.first { $0.id == selectedSortOrderId }
    }
    
    var currencySymbol: String {
        let startIndex = selectedCurrency.firstIndex(of: "(")!
        let endIndex = selectedCurrency.lastIndex(of: ")")!
        return String(selectedCurrency[selectedCurrency.index(after: startIndex)...selectedCurrency.index(before: endIndex)])
    }
    
    func convertToMilliliters(_ value: String, from unit: String) -> String {
        guard let numericValue = Double(value) else { return value }
        
        switch unit {
        case "cl":
            return String(format: "%.0f", numericValue * 10)
        case "dl":
            return String(format: "%.0f", numericValue * 100)
        case "l":
            return String(format: "%.0f", numericValue * 1000)
        default: // ml
            return value
        }
    }
    
    func convertFromMilliliters(_ value: String, to unit: String) -> String {
        guard let numericValue = Double(value) else { return value }
        
        let convertedValue: Double
        switch unit {
        case "cl":
            convertedValue = numericValue / 10
        case "dl":
            convertedValue = numericValue / 100
        case "l":
            convertedValue = numericValue / 1000
        default: // ml
            return String(format: "%.0f", numericValue) // No decimals for ml
        }
        
        // Convert to string and remove trailing zeros while preserving necessary decimal places
        let stringValue = String(convertedValue)
        let parts = stringValue.split(separator: ".")
        
        if parts.count == 1 {
            // It's a whole number
            return String(convertedValue)
        } else {
            // Remove trailing zeros but keep all significant decimal places
            let decimals = parts[1].replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            return decimals.isEmpty ? String(parts[0]) : "\(parts[0]).\(decimals)"
        }
    }
    
    func getDisplayBottleSize(_ storedSize: String?) -> String {
        guard let size = storedSize, !size.isEmpty else { return "" }
        
        // Remove 'ml' suffix and convert to user's preferred unit
        let mlValue = size.replacingOccurrences(of: "ml", with: "")
        let convertedValue = convertFromMilliliters(mlValue, to: bottleSizeUnit)
        return "\(convertedValue)\(bottleSizeUnit)"
    }

    func formatBottleSize(_ size: String?) -> String {
        guard let size = size, !size.isEmpty else { return "" }
        
        // If the size already ends with a unit, convert it to ml
        if size.hasSuffix("ml") {
            return size
        } else if size.hasSuffix("cl") {
            let value = size.replacingOccurrences(of: "cl", with: "")
            return "\(convertToMilliliters(value, from: "cl"))ml"
        } else if size.hasSuffix("dl") {
            let value = size.replacingOccurrences(of: "dl", with: "")
            return "\(convertToMilliliters(value, from: "dl"))ml"
        } else if size.hasSuffix("l") {
            let value = size.replacingOccurrences(of: "l", with: "")
            return "\(convertToMilliliters(value, from: "l"))ml"
        }
        
        // Convert from current unit to ml for storage
        return "\(convertToMilliliters(size, from: bottleSizeUnit))ml"
    }
}
