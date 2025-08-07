import SwiftUI
import CoreData

struct WineSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var wines: [Wine] = []
    @State private var selectedWines: Set<NSManagedObjectID> = []
    @State private var searchText = ""
    @State private var includeImages = true
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @StateObject private var exportManager: WineExportImportManager
    
    init(context: NSManagedObjectContext, settings: SettingsStore) {
        _exportManager = StateObject(wrappedValue: WineExportImportManager(context: context, settings: settings))
    }
    
    var filteredWines: [Wine] {
        if searchText.isEmpty {
            return wines
        } else {
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
                let storageLocation = wine.storageLocation?.lowercased() ?? ""
                let remarks = wine.remarks?.lowercased() ?? ""
                let wineRating = wine.wineRating?.lowercased() ?? ""
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
                       storageLocation.contains(lowercasedSearch) ||
                       remarks.contains(lowercasedSearch) ||
                       wineRating.contains(lowercasedSearch) ||
                       price.contains(lowercasedSearch)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search wines...", text: $searchText)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Selection summary
                HStack {
                    if !selectedWines.isEmpty {
                        Text("\(selectedWines.count) wine\(selectedWines.count == 1 ? "" : "s") selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Select All") {
                        selectAll()
                    }
                    .font(.caption)
                    if !selectedWines.isEmpty {
                        Button("Clear All") {
                            selectedWines.removeAll()
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                // Export options
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Include wine images", isOn: $includeImages)
                            .font(.caption)
                        Spacer()
                    }
                    if !includeImages {
                        Text("Excluding images creates smaller export files")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Wine list
                List {
                    ForEach(filteredWines, id: \.objectID) { wine in
                        WineSelectionRow(
                            wine: wine,
                            isSelected: selectedWines.contains(wine.objectID)
                        ) {
                            toggleSelection(wine)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Wines to Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        exportSelectedWines()
                    }
                    .disabled(selectedWines.isEmpty || isExporting)
                }
            }
            .onAppear {
                loadWines()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Export Status", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadWines() {
        let request: NSFetchRequest<Wine> = Wine.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Wine.name, ascending: true)
        ]
        
        do {
            wines = try viewContext.fetch(request)
        } catch {
            print("Error loading wines: \(error)")
        }
    }
    
    private func toggleSelection(_ wine: Wine) {
        if selectedWines.contains(wine.objectID) {
            selectedWines.remove(wine.objectID)
        } else {
            selectedWines.insert(wine.objectID)
        }
    }
    
    private func selectAll() {
        selectedWines = Set(filteredWines.map { $0.objectID })
    }
    
    private func exportSelectedWines() {
        isExporting = true
        
        let selectedWineObjects = wines.filter { selectedWines.contains($0.objectID) }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let url = exportManager.exportWines(selectedWineObjects, includeImages: includeImages) {
                DispatchQueue.main.async {
                    self.exportURL = url
                    self.isExporting = false
                    self.showingShareSheet = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.alertMessage = "Failed to export wines. Please try again."
                    self.showingAlert = true
                }
            }
        }
    }
}

struct WineSelectionRow: View {
    let wine: Wine
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onTap) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(wine.name ?? "Unknown Wine")
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    if let producer = wine.producer, !producer.isEmpty {
                        Text(producer)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let vintage = wine.vintage, !vintage.isEmpty {
                        Text("• \(vintage)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Qty: \(wine.quantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
