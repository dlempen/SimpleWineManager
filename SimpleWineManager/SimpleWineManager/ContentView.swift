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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Wine.name, ascending: true)],
        animation: .default)
    private var wines: FetchedResults<Wine>
    
    @State private var showingAddWine = false
    @State private var searchText = ""
    
    init(context: NSManagedObjectContext? = nil) {
        let context = context ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: WineListViewModel(context: context))
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
            
            return name.contains(lowercasedSearch) ||
                   producer.contains(lowercasedSearch) ||
                   vintage.contains(lowercasedSearch) ||
                   alcohol.contains(lowercasedSearch) ||
                   category.contains(lowercasedSearch) ||
                   country.contains(lowercasedSearch) ||
                   region.contains(lowercasedSearch) ||
                   subregion.contains(lowercasedSearch) ||
                   type.contains(lowercasedSearch)
        }
    }

    var totalQuantity: Int {
        filteredWines.reduce(0) { $0 + Int($1.quantity) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
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
                        NavigationLink(destination: WineDetailView(wine: wine)) {
                            WineRowView(wine: wine)
                                .id("\(wine.id?.uuidString ?? "")-\(wine.quantity)-\(viewModel.lastRefresh)")
                        }
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
                if !showingAddWine {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddWine = true }) {
                            Label("Add Wine", systemImage: "plus")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddWine) {
                NavigationStack {
                    AddWineView()
                }
            }
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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(wine.name ?? "Unknown") \(wine.vintage ?? "")")
                .font(.headline)
            Text("Producer: \(wine.producer ?? "-")")
                .font(.subheadline)
            Text("Qty: \(wine.quantity)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
