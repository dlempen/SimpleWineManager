import Foundation
import UIKit

struct SortOrder: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var fields: [SortField]
    var subtitleFields: Set<SortField>
    
    init(id: UUID = UUID(), name: String, fields: [SortField], subtitleFields: Set<SortField> = []) {
        self.id = id
        self.name = name
        self.fields = fields
        self.subtitleFields = subtitleFields
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
    case quantity = "Quantity"
    case bottleSize = "Bottle Size"
    case readyToTrinkYear = "Drink from"
    case bestBeforeYear = "Best before"
    
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
        case .quantity: return "quantity"
        case .bottleSize: return "bottleSize"
        case .readyToTrinkYear: return "readyToTrinkYear"
        case .bestBeforeYear: return "bestBeforeYear"
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
    
    @Published var importWithQuantity: Bool {
        didSet {
            UserDefaults.standard.set(importWithQuantity, forKey: "importWithQuantity")
        }
    }
    
    @Published var hideZeroQuantityWines: Bool {
        didSet {
            UserDefaults.standard.set(hideZeroQuantityWines, forKey: "hideZeroQuantityWines")
        }
    }

    // MARK: - AI Integration Settings

    @Published var aiProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(aiProvider.rawValue, forKey: "aiProvider")
        }
    }

    @Published var aiApiKey: String {
        didSet {
            if aiApiKey.isEmpty {
                KeychainHelper.delete(forKey: "aiApiKey")
            } else {
                KeychainHelper.save(aiApiKey, forKey: "aiApiKey")
            }
            // Remove any legacy value that may have been stored in UserDefaults
            UserDefaults.standard.removeObject(forKey: "aiApiKey")
        }
    }

    /// The OpenAI model used for AI Fill requests.
    @Published var aiModel: String {
        didSet {
            UserDefaults.standard.set(aiModel, forKey: "aiModel")
        }
    }

    /// Models available for selection in Settings.
    /// Each entry is (id, displayName, description).
    static let availableAIModels: [(id: String, name: String, description: String)] = [
        ("gpt-5.5",      "GPT-5.5 ✦ Recommended", "Best model for agentic web search. Performs multi-step searches, reasons about sources, and verifies producer identity most accurately."),
        ("gpt-5.4",      "GPT-5.4",      "Latest stable GPT-5 series. Very capable with web search."),
        ("gpt-5.4-mini", "GPT-5.4 mini", "Faster, cheaper GPT-5.4. Good balance of speed and quality."),
        ("gpt-5.2",      "GPT-5.2",      "Stable GPT-5.2 release."),
        ("gpt-5",        "GPT-5",        "Base GPT-5 with solid web search support."),
        ("gpt-4.1",      "GPT-4.1",      "Latest GPT-4 series. Reliable fallback."),
        ("o3",           "o3",           "Reasoning model. Extremely thorough but slower."),
        ("o4-mini",      "o4-mini",      "Fast reasoning model."),
    ]

    /// Countries whose web sources the AI should prefer when searching for wine info.
    /// Empty array = no geographic restriction (global search).
    @Published var aiSearchCountries: [String] {
        didSet {
            if let encoded = try? JSONEncoder().encode(aiSearchCountries) {
                UserDefaults.standard.set(encoded, forKey: "aiSearchCountries")
            }
        }
    }

    // All countries available for AI search geo-filtering, with their ISO-3166-1 alpha-2
    // country codes used by the OpenAI web_search_preview user_location parameter.
    static let aiSearchableCountries: [(name: String, code: String)] = [
        ("Austria",        "AT"),
        ("Belgium",        "BE"),
        ("Croatia",        "HR"),
        ("Denmark",        "DK"),
        ("Finland",        "FI"),
        ("France",         "FR"),
        ("Germany",        "DE"),
        ("Greece",         "GR"),
        ("Hungary",        "HU"),
        ("Ireland",        "IE"),
        ("Italy",          "IT"),
        ("Luxembourg",     "LU"),
        ("Netherlands",    "NL"),
        ("Norway",         "NO"),
        ("Poland",         "PL"),
        ("Portugal",       "PT"),
        ("Romania",        "RO"),
        ("Serbia",         "RS"),
        ("Slovenia",       "SI"),
        ("South Africa",   "ZA"),
        ("Spain",          "ES"),
        ("Sweden",         "SE"),
        ("Switzerland",    "CH"),
        ("United Kingdom", "GB"),
        ("United States",  "US"),
        ("Australia",      "AU"),
        ("New Zealand",    "NZ"),
        ("Canada",         "CA"),
        ("Argentina",      "AR"),
        ("Chile",          "CL"),
    ]

    @Published var imageQuality: ImageQuality {
        didSet {
            UserDefaults.standard.set(imageQuality.rawValue, forKey: "imageQuality")
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
        self.importWithQuantity = UserDefaults.standard.bool(forKey: "importWithQuantity") // defaults to false
        self.hideZeroQuantityWines = UserDefaults.standard.bool(forKey: "hideZeroQuantityWines") // defaults to false

        // AI settings
        if let providerRaw = UserDefaults.standard.string(forKey: "aiProvider"),
           let provider = AIProvider(rawValue: providerRaw) {
            self.aiProvider = provider
        } else {
            self.aiProvider = .openAI
        }

        self.aiModel = UserDefaults.standard.string(forKey: "aiModel") ?? "gpt-5.5"

        // Read API key from Keychain; fall back to any legacy UserDefaults value and migrate it.
        if let keychainKey = KeychainHelper.read(forKey: "aiApiKey") {
            self.aiApiKey = keychainKey
        } else if let legacyKey = UserDefaults.standard.string(forKey: "aiApiKey"), !legacyKey.isEmpty {
            // Migrate the old UserDefaults value into the Keychain once, then remove it.
            KeychainHelper.save(legacyKey, forKey: "aiApiKey")
            UserDefaults.standard.removeObject(forKey: "aiApiKey")
            self.aiApiKey = legacyKey
        } else {
            self.aiApiKey = ""
        }

        // AI search countries (geo-filter for web search)
        if let data = UserDefaults.standard.data(forKey: "aiSearchCountries"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.aiSearchCountries = decoded
        } else {
            self.aiSearchCountries = [] // empty = global (no restriction)
        }

        // Load image quality setting
        if let imageQualityString = UserDefaults.standard.string(forKey: "imageQuality"),
           let imageQuality = ImageQuality(rawValue: imageQualityString) {
            self.imageQuality = imageQuality
        } else {
            self.imageQuality = .medium // default to medium quality
        }
        
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
    
    // MARK: - Image Compression Functions
    
    /// Compresses an image to fit within the selected quality range
    func compressImage(_ image: UIImage) -> Data? {
        return compressImage(image, to: imageQuality)
    }
    
    /// Compresses an image to fit within the specified quality range
    func compressImage(_ image: UIImage, to quality: ImageQuality) -> Data? {
        let targetRange = quality.targetSizeRange
        let targetSize = (targetRange.min + targetRange.max) / 2 // Target the middle of the range
        
        // First, try to resize the image if it's very large
        let resizedImage = resizeImageIfNeeded(image, targetMaxSize: targetRange.max)
        
        // Start with reasonable quality bounds
        var minQuality: CGFloat = 0.05
        var maxQuality: CGFloat = 1.0
        var bestData: Data?
        var bestDifference = Int.max
        
        // Binary search for optimal compression quality
        for _ in 0..<20 { // More iterations for better precision
            let currentQuality = (minQuality + maxQuality) / 2
            guard let imageData = resizedImage.jpegData(compressionQuality: currentQuality) else {
                break
            }
            
            let size = imageData.count
            let differenceFromTarget = abs(size - targetSize)
            
            // Keep track of the best result (closest to target)
            if differenceFromTarget < bestDifference {
                bestDifference = differenceFromTarget
                bestData = imageData
            }
            
            // Adjust search range based on current size
            if size > targetSize {
                // Image is larger than target, reduce quality
                maxQuality = currentQuality
            } else {
                // Image is smaller than target, increase quality
                minQuality = currentQuality
            }
            
            // If we're very close to target or quality range is too narrow, we can stop
            if differenceFromTarget < 5000 || maxQuality - minQuality < 0.005 {
                break
            }
        }
        
        // Return the best result we found, or fallback to low quality if nothing worked
        return bestData ?? resizedImage.jpegData(compressionQuality: 0.1)
    }
    
    /// Resizes image if it's too large to help with compression
    private func resizeImageIfNeeded(_ image: UIImage, targetMaxSize: Int) -> UIImage {
        // Calculate current image data size
        guard let currentData = image.jpegData(compressionQuality: 0.8) else { return image }
        let currentSize = currentData.count
        
        // If current size is much larger than target, resize the image
        if currentSize > targetMaxSize * 3 { // 3x larger than target max
            let reductionFactor = sqrt(Double(targetMaxSize * 2) / Double(currentSize))
            let newSize = CGSize(
                width: image.size.width * reductionFactor,
                height: image.size.height * reductionFactor
            )
            
            // Ensure minimum size (don't make images too small)
            let minDimension: CGFloat = 400
            let finalSize = CGSize(
                width: max(newSize.width, minDimension),
                height: max(newSize.height, minDimension)
            )
            
            UIGraphicsBeginImageContextWithOptions(finalSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: finalSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage ?? image
        }
        
        return image
    }
    
    /// Gets the file size of image data in a human-readable format
    func getImageSizeString(_ data: Data?) -> String {
        guard let data = data else { return "0 KB" }
        let sizeInKB = Double(data.count) / 1024.0
        return String(format: "%.1f KB", sizeInKB)
    }
}

enum ImageQuality: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .small: return "Small (50-100 KB)"
        case .medium: return "Medium (100-200 KB)"
        case .large: return "Large (200-400 KB)"
        }
    }
    
    var targetSizeRange: (min: Int, max: Int) {
        switch self {
        case .small: return (50_000, 100_000)
        case .medium: return (100_000, 200_000)
        case .large: return (200_000, 400_000)
        }
    }
}
