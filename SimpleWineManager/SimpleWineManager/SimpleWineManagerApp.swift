//
//  SimpleWineManagerApp.swift
//  SimpleWineManager
//
//  Created by Lempen Dieter on 31.05.2025.
//

import SwiftUI

@main
struct SimpleWineManagerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Perform one-time migration for existing history entries
                    let historyService = WineHistoryService(context: persistenceController.container.viewContext)
                    historyService.migrateHistoryEntriesToIncludeRunningTotals()
                }
        }
    }
}
