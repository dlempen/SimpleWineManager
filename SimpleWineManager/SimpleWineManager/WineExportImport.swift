import Foundation
import CoreData
import UniformTypeIdentifiers

// MARK: - Data Structures for Export/Import

struct WineCollection: Codable {
    let version: String = "1.0"
    let exportDate: Date
    let exportedBy: String
    let wines: [SharedWine]
    
    enum CodingKeys: String, CodingKey {
        case version, exportDate, exportedBy, wines
    }
    
    init(wines: [SharedWine], exportedBy: String = "Wine Manager") {
        self.exportDate = Date()
        self.exportedBy = exportedBy
        self.wines = wines
    }
}

struct SharedWine: Codable, Identifiable {
    let id: UUID
    let name: String?
    let producer: String?
    let vintage: String?
    let alcohol: String?
    let quantity: Int16
    let country: String?
    let region: String?
    let subregion: String?
    let type: String?
    let category: String?
    let price: Double?
    let bottleSize: String?
    let readyToTrinkYear: String?
    let bestBeforeYear: String?
    let storageLocation: String?
    let frontImageData: Data?
    let backImageData: Data?
    
    init(from wine: Wine, includeImages: Bool = true) {
        self.id = wine.id ?? UUID()
        self.name = wine.name
        self.producer = wine.producer
        self.vintage = wine.vintage
        self.alcohol = wine.alcohol
        self.quantity = wine.quantity
        self.country = wine.country
        self.region = wine.region
        self.subregion = wine.subregion
        self.type = wine.type
        self.category = wine.category
        self.price = wine.price?.doubleValue
        self.bottleSize = wine.bottleSize
        self.readyToTrinkYear = wine.readyToTrinkYear
        self.bestBeforeYear = wine.bestBeforeYear
        self.storageLocation = wine.storageLocation
        self.frontImageData = includeImages ? wine.frontImageData : nil
        self.backImageData = includeImages ? wine.backImageData : nil
    }
    
    func toWine(context: NSManagedObjectContext, importQuantity: Bool = false) -> Wine {
        let wine = Wine(context: context)
        wine.id = self.id
        wine.name = self.name
        wine.producer = self.producer
        wine.vintage = self.vintage
        wine.alcohol = self.alcohol
        wine.quantity = importQuantity ? self.quantity : 0
        wine.country = self.country
        wine.region = self.region
        wine.subregion = self.subregion
        wine.type = self.type
        wine.category = self.category
        wine.price = self.price.map { NSDecimalNumber(value: $0) }
        wine.bottleSize = self.bottleSize
        wine.readyToTrinkYear = self.readyToTrinkYear
        wine.bestBeforeYear = self.bestBeforeYear
        wine.storageLocation = self.storageLocation
        wine.frontImageData = self.frontImageData
        wine.backImageData = self.backImageData
        return wine
    }
}

// MARK: - Export/Import Manager

class WineExportImportManager: ObservableObject {
    private let context: NSManagedObjectContext
    private let settings: SettingsStore
    
    init(context: NSManagedObjectContext, settings: SettingsStore) {
        self.context = context
        self.settings = settings
    }
    
    func exportWines(_ wines: [Wine], includeImages: Bool = true) -> URL? {
        let sharedWines = wines.map { SharedWine(from: $0, includeImages: includeImages) }
        let collection = WineCollection(wines: sharedWines)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(collection)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let suffix = includeImages ? "" : "_NoImages"
            let fileName = "WineCollection_\(DateFormatter.fileNameFormatter.string(from: Date()))\(suffix).simplewinemanager"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
    
    func importWines(from url: URL) -> Result<ImportResult, ImportError> {
        do {
            // Request access to security-scoped resource
            let accessGranted = url.startAccessingSecurityScopedResource()
            defer {
                if accessGranted {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let collection = try decoder.decode(WineCollection.self, from: data)
            
            var importedCount = 0
            var skippedCount = 0
            
            for sharedWine in collection.wines {
                // Check if wine already exists to prevent duplicates
                // Uses UUID first, then name+producer+vintage (case-insensitive)
                let existingWine = fetchExistingWine(sharedWine)
                
                if existingWine == nil {
                    // Wine doesn't exist, safe to import - use settings to determine if quantity should be imported
                    _ = sharedWine.toWine(context: context, importQuantity: settings.importWithQuantity)
                    importedCount += 1
                } else {
                    // Wine already exists, skip to prevent overwriting
                    skippedCount += 1
                }
            }
            
            try context.save()
            return .success(ImportResult(imported: importedCount, skipped: skippedCount))
            
        } catch DecodingError.dataCorrupted(_) {
            return .failure(.invalidFormat)
        } catch DecodingError.keyNotFound(_, _) {
            return .failure(.invalidFormat)
        } catch DecodingError.typeMismatch(_, _) {
            return .failure(.invalidFormat)
        } catch DecodingError.valueNotFound(_, _) {
            return .failure(.invalidFormat)
        } catch CocoaError.fileReadNoSuchFile {
            return .failure(.fileNotFound)
        } catch CocoaError.fileReadNoPermission {
            return .failure(.fileAccessDenied)
        } catch let error as NSError where error.domain == NSPOSIXErrorDomain && error.code == 1 {
            // EPERM (Operation not permitted) - common permission error
            return .failure(.fileAccessDenied)
        } catch {
            // Check if the error description contains permission-related keywords
            let errorDesc = error.localizedDescription.lowercased()
            if errorDesc.contains("permission") || errorDesc.contains("access") || errorDesc.contains("denied") {
                return .failure(.fileAccessDenied)
            }
            return .failure(.unknownError(error.localizedDescription))
        }
    }
    
    private func fetchExistingWine(_ sharedWine: SharedWine) -> Wine? {
        let request: NSFetchRequest<Wine> = Wine.fetchRequest()
        
        // First try by ID
        request.predicate = NSPredicate(format: "id == %@", sharedWine.id as CVarArg)
        if let wine = try? context.fetch(request).first {
            return wine
        }
        
        // Then try by name, producer, and vintage if all are available
        // Use case-insensitive comparison and trim whitespace
        if let name = sharedWine.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
           let producer = sharedWine.producer?.trimmingCharacters(in: .whitespacesAndNewlines), !producer.isEmpty,
           let vintage = sharedWine.vintage?.trimmingCharacters(in: .whitespacesAndNewlines), !vintage.isEmpty {
            
            request.predicate = NSPredicate(format: "name ==[c] %@ AND producer ==[c] %@ AND vintage ==[c] %@", name, producer, vintage)
            return try? context.fetch(request).first
        }
        
        return nil
    }
}

struct ImportResult {
    let imported: Int
    let skipped: Int
    
    var total: Int {
        imported + skipped
    }
}

enum ImportError: LocalizedError {
    case fileNotFound
    case invalidFormat
    case fileAccessDenied
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .invalidFormat:
            return "Invalid file format"
        case .fileAccessDenied:
            return "Unable to access the file. Please try importing the file from a different location or ensure it's saved to your device."
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - UTType for .simplewinemanager files

extension UTType {
    static let simpleWineManager = UTType(filenameExtension: "simplewinemanager")!
}

// MARK: - Helper Extensions

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
