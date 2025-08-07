import Foundation
import CoreData
import SwiftUI

extension WineHistory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WineHistory> {
        return NSFetchRequest<WineHistory>(entityName: "WineHistory")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var action: String?
    @NSManaged public var changeDetails: String?
    @NSManaged public var wineSnapshot: String?
    @NSManaged public var quantityChange: Int16
    @NSManaged public var priceAtTime: NSDecimalNumber?
    @NSManaged public var wineName: String?
    @NSManaged public var wineProducer: String?
    @NSManaged public var wineVintage: String?
    @NSManaged public var wineId: UUID?
    @NSManaged public var totalQuantityAtTime: Int32
    @NSManaged public var totalValueAtTime: NSDecimalNumber?

}

extension WineHistory : Identifiable {

}

// MARK: - History Action Types
extension WineHistory {
    enum ActionType: String, CaseIterable {
        case added = "Added"
        case edited = "Edited"
        case deleted = "Deleted"
        case consumed = "Consumed"
        
        var icon: String {
            switch self {
            case .added: return "plus.circle.fill"
            case .edited: return "pencil.circle.fill"
            case .deleted: return "trash.circle.fill"
            case .consumed: return "wineglass.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .added: return .green
            case .edited: return .blue
            case .deleted, .consumed: return .orange
            }
        }
        
        var description: String {
            return self.rawValue
        }
    }
    
    var actionType: ActionType {
        return ActionType(rawValue: action ?? "") ?? .edited
    }
}
