import Foundation

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
    
    static let currencies = [
        "USD ($)", "EUR (€)", "JPY (¥)", "GBP (£)", "CNY (¥)", 
        "AUD ($)", "CAD ($)", "CHF (Fr)", "HKD ($)", "SGD ($)", 
        "INR (₹)", "NZD ($)", "SEK (kr)", "KRW (₩)", "NOK (kr)"
    ]
    
    static let bottleSizeUnits = ["ml", "cl", "l"]
    
    init() {
        self.selectedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "EUR (€)"
        self.bottleSizeUnit = UserDefaults.standard.string(forKey: "bottleSizeUnit") ?? "ml"
    }
    
    var currencySymbol: String {
        let startIndex = selectedCurrency.firstIndex(of: "(")!
        let endIndex = selectedCurrency.lastIndex(of: ")")!
        return String(selectedCurrency[selectedCurrency.index(after: startIndex)...selectedCurrency.index(before: endIndex)])
    }
    
    func formatBottleSize(_ size: String?) -> String {
        guard let size = size, !size.isEmpty else { return "" }
        
        // If the size already ends with a unit, return as is
        if size.hasSuffix("ml") || size.hasSuffix("cl") || size.hasSuffix("l") {
            return size
        }
        
        // If it's just a number, append the current unit
        return "\(size)\(bottleSizeUnit)"
    }
}
