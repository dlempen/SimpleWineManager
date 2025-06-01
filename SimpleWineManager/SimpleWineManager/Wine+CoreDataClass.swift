import Foundation
import CoreData
import Combine

@objc(Wine)
public class Wine: NSManagedObject {
    private var cancellables = Set<AnyCancellable>()
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setupObservation()
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        setupObservation()
    }
    
    private func setupObservation() {
        // Observe changes to this object
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave,
            object: managedObjectContext
        )
        .filter { notification in
            let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []
            return updatedObjects.contains(self)
        }
        .sink { [weak self] _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("WineDataDidChange"), object: nil)
            }
        }
        .store(in: &cancellables)
    }
}
