//
//  Persistence.swift
//  SimpleWineManager
//
//  Created by Lempen Dieter on 31.05.2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Create sample data for previews
        let sampleWine = Wine(context: viewContext)
        sampleWine.id = UUID()
        sampleWine.name = "Sample Wine"
        sampleWine.producer = "Sample Winery"
        sampleWine.vintage = "2020"
        sampleWine.quantity = 1
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SimpleWineManager")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure the persistent store for concurrent updates
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Configure view context for better change handling
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Enable automatic merging of changes from other contexts
        // Store context in a local variable to avoid capturing self
        let viewContext = container.viewContext
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main) { [weak viewContext] notification in
                guard let context = viewContext else { return }
                
                if let savedContext = notification.object as? NSManagedObjectContext,
                   savedContext !== context {
                    context.perform {
                        context.mergeChanges(fromContextDidSave: notification)
                    }
                }
            }
    }
}
