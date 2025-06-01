import Foundation
import CoreData

extension Wine {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Wine> {
        return NSFetchRequest<Wine>(entityName: "Wine")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var producer: String?
    @NSManaged public var vintage: String?
    @NSManaged public var alcohol: String?
    @NSManaged public var quantity: Int16
    @NSManaged public var frontImageData: Data?
    @NSManaged public var backImageData: Data?
    @NSManaged public var country: String?
    @NSManaged public var region: String?
    @NSManaged public var subregion: String?
    @NSManaged public var type: String?
    @NSManaged public var category: String?
}

extension Wine: Identifiable { }
