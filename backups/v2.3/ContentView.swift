//
//  ContentView.swift
//  SimpleWineManager
//
//  Created by Lempen Dieter on 31.05.2025.
//

import SwiftUI
import CoreData

class WineListViewModel: ObservableObject {
    private var viewContext: NSManagedObjectContext
    @Published private(set) var lastRefresh = Date()
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        
        // Listen for CoreData and manual refresh notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshData),
            name: .NSManagedObjectContextObjectsDidChange,
            object: viewContext)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshData),
            name: NSNotification.Name("WineDataDidChange"),
            object: nil)
    }
    
    @objc func refreshData() {
        DispatchQueue.main.async {
            self.lastRefresh = Date()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: WineListViewModel
    @StateObject private var settings = SettingsStore()
    @State private var showingAddWine = false
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var isEditing = false
    
    // Use standard @FetchRequest instead of a State variable
    @FetchRequest private var wines: FetchedResults<Wine>
    
    init(context: NSManagedObjectContext? = nil) {
        let context = context ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: WineListViewModel(context: context))
        
        // Initialize the FetchRequest with default sorting
        _wines = FetchRequest(
            entity: Wine.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Wine.name, ascending: true)],
            animation: .default
        )
    }
    
    private func updateSortDescriptors() {
        guard let sortOrder = settings.selectedSortOrder else { return }
        
        let sortDescriptors = sortOrder.fields.map { field -> NSSortDescriptor in
            NSSortDescriptor(key: field.keyPath, ascending: true)
        }
        
        // Update the fetch request's sort descriptors
        wines.nsSortDescriptors = sortDescriptors
    }
    
    var filteredWines: [Wine] {
        if searchText.isEmpty {
            return Array(wines)
        }
        
        let lowercasedSearch = searchText.lowercased()
        return wines.filter { wine in
            let name = wine.name?.lowercased() ?? ""
            let producer = wine.producer?.lowercased() ?? ""
            let vintage = wine.vintage?.lowercased() ?? ""
            let alcohol = wine.alcohol?.lowercased() ?? ""
            let category = wine.category?.lowercased() ?? ""
            let country = wine.country?.lowercased() ?? ""
            let region = wine.region?.lowercased() ?? ""
            let subregion = wine.subregion?.lowercased() ?? ""
            let type = wine.type?.lowercased() ?? ""
            let bottleSize = wine.bottleSize?.lowercased() ?? ""
            let readyToTrinkYear = wine.readyToTrinkYear?.lowercased() ?? ""
            let bestBeforeYear = wine.bestBeforeYear?.lowercased() ?? ""
            let price = wine.price?.stringValue ?? ""
            
            return name.contains(lowercasedSearch) ||
                   producer.contains(lowercasedSearch) ||
                   vintage.contains(lowercasedSearch) ||
                   alcohol.contains(lowercasedSearch) ||
                   category.contains(lowercasedSearch) ||
                   country.contains(lowercasedSearch) ||
                   region.contains(lowercasedSearch) ||
                   subregion.contains(lowercasedSearch) ||
                   type.contains(lowercasedSearch) ||
                   bottleSize.contains(lowercasedSearch) ||
                   readyToTrinkYear.contains(lowercasedSearch) ||
                   bestBeforeYear.contains(lowercasedSearch) ||
                   price.contains(lowercasedSearch)
        }
    }

    var totalQuantity: Int {
        filteredWines.reduce(0) { $0 + Int($1.quantity) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar and Total Quantity
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Search wines...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                    
                    // Total Quantity aligned with wine item quantities
                    Text("Total Qty: \(totalQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Wine List
                List {
                    ForEach(filteredWines) { wine in
                        NavigationLink(destination: WineDetailView(wine: wine).environmentObject(settings)) {
                            WineRowView(wine: wine)
                        }
                        .id("\(wine.id?.uuidString ?? "")-\(wine.quantity)-\(viewModel.lastRefresh)")
                    }
                    .onDelete(perform: deleteWines)
                }
                .listStyle(.plain)
                .refreshable {
                    viewContext.rollback() // Discard any pending changes
                    viewModel.refreshData()
                }
            }
            .navigationTitle("🍷 My Wine Cellar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                        }
                        Button(action: {
                            showingAddWine = true
                        }) {
                            Label("Add Wine", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddWine) {
                NavigationStack {
                    AddWineView()
                        .environmentObject(settings)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
        }
        .environmentObject(settings)
        .onChange(of: settings.selectedSortOrderId) { _, _ in
            updateSortDescriptors()
        }
        .onChange(of: settings.sortOrders) { _, newValue in
            // If the current sort order was deleted, update to use the first available one
            if let currentId = settings.selectedSortOrderId,
               !newValue.contains(where: { $0.id == currentId }) {
                settings.selectedSortOrderId = newValue.first?.id
            }
            updateSortDescriptors()
        }
        .onAppear {
            updateSortDescriptors()
        }
    }

    private func deleteWines(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredWines[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
            viewModel.refreshData()
        }
    }
}

struct WineRowView: View {
    @ObservedObject var wine: Wine
    @EnvironmentObject var settings: SettingsStore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(wine.name ?? "Unknown") \(wine.vintage ?? "")")
                .font(.headline)
            Text(wine.producer ?? "-")
                .font(.subheadline)
            HStack {
                Text("Qty: \(wine.quantity)")
                if let size = wine.bottleSize, !size.isEmpty {
                    Text("•")
                    Text(settings.getDisplayBottleSize(size))
                }
                if let alcohol = wine.alcohol, !alcohol.isEmpty {
                    Text("•")
                    Text("\(alcohol)%")
                }
                if let price = wine.price, price != 0 {
                    Text("•")
                    Text("\(price) \(settings.currencySymbol)")
                }
                if let storageLocation = wine.storageLocation, !storageLocation.isEmpty {
                    Text("•")
                    Text(storageLocation)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SettingsStore())
}
