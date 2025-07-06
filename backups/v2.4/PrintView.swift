import SwiftUI

struct PrintView: View {
    @ObservedObject var viewModel: WineListViewModel
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    private var filteredWines: [Wine] {
        if viewModel.searchText.isEmpty {
            return viewModel.wines
        } else {
            return viewModel.wines.filter { wine in
                let searchLower = viewModel.searchText.lowercased()
                return (wine.name?.lowercased().contains(searchLower) ?? false) ||
                       (wine.producer?.lowercased().contains(searchLower) ?? false) ||
                       (wine.vintage?.lowercased().contains(searchLower) ?? false) ||
                       (wine.country?.lowercased().contains(searchLower) ?? false) ||
                       (wine.region?.lowercased().contains(searchLower) ?? false) ||
                       (wine.subregion?.lowercased().contains(searchLower) ?? false) ||
                       (wine.type?.lowercased().contains(searchLower) ?? false) ||
                       (wine.category?.lowercased().contains(searchLower) ?? false) ||
                       (wine.storageLocation?.lowercased().contains(searchLower) ?? false)
            }
        }
    }
    
    private var totalQuantity: Int {
        filteredWines.reduce(0) { $0 + Int($1.quantity) }
    }
    
    private func getFieldValue(_ field: SortField, for wine: Wine) -> String {
        switch field {
        case .name: return wine.name ?? ""
        case .producer: return wine.producer ?? ""
        case .vintage: return wine.vintage ?? ""
        case .country: return wine.country ?? ""
        case .region: return wine.region ?? ""
        case .type: return wine.type ?? ""
        case .category: return wine.category ?? ""
        case .price: return wine.price?.stringValue ?? "0"
        }
    }
    
    private func groupedWines() -> [(level: Int, title: String, wine: Wine?)] {
        guard let sortOrder = settings.selectedSortOrder,
              !sortOrder.subtitleFields.isEmpty else {
            return filteredWines.map { (0, "", $0) }
        }
        
        // First, sort all wines according to the sort order
        let sortedWines = filteredWines.sorted { wine1, wine2 in
            for field in sortOrder.fields {
                let value1 = getFieldValue(field, for: wine1)
                let value2 = getFieldValue(field, for: wine2)
                if value1 != value2 {
                    return value1 < value2
                }
            }
            return false
        }
        
        // Get subtitle fields in the order they appear in fields array
        let orderedSubtitleFields = sortOrder.fields.filter { sortOrder.subtitleFields.contains($0) }
        
        var result: [(level: Int, title: String, wine: Wine?)] = []
        var previousValues: [String] = Array(repeating: "", count: orderedSubtitleFields.count)
        
        for wine in sortedWines {
            let currentValues = orderedSubtitleFields.map { getFieldValue($0, for: wine) }
            
            // Check which level changed and add headers from that level down
            for (level, _) in orderedSubtitleFields.enumerated() {
                if level < currentValues.count && currentValues[level] != previousValues[level] {
                    // This level changed, so we need to add headers from this level down
                    for headerLevel in level..<currentValues.count {
                        let value = currentValues[headerLevel]
                        if !value.isEmpty {
                            result.append((headerLevel, value, nil))
                        }
                    }
                    break
                }
            }
            
            // Add the wine
            result.append((0, "", wine))
            previousValues = currentValues
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .center, spacing: 8) {
                        Text(settings.printTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if !settings.printSubtitle.isEmpty {
                            Text(settings.printSubtitle)
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Total Wines: \(totalQuantity)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.top, 8)
                    }
                    .padding()
                    
                    // Wine List with hierarchical sections
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(groupedWines().enumerated()), id: \.offset) { index, group in
                            if let wine = group.wine {
                                // Display single wine for print
                                PrintWineRowView(wine: wine)
                                    .padding(.horizontal)
                                    .padding(.vertical, 2)
                            } else if !group.title.isEmpty {
                                // Display section title
                                VStack(spacing: 0) {
                                    Text(group.title)
                                        .font(.system(size: group.level == 0 ? 28 : 22))
                                        .fontWeight(group.level == 0 ? .bold : .semibold)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                        .padding(.top, group.level == 0 ? 16 : 8)
                                        .padding(.bottom, 4)
                                    
                                    // Add separator line after titles
                                    if group.level == 0 {
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Print Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Trigger system print dialog
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           windowScene.windows.first != nil {
                            let printController = UIPrintInteractionController.shared
                            let printInfo = UIPrintInfo.printInfo()
                            printInfo.outputType = .general
                            printInfo.jobName = "Wine Collection"
                            printController.printInfo = printInfo
                            
                            // Create a print formatter for the view
                            let printFormatter = UIMarkupTextPrintFormatter(markupText: generateHTMLContent())
                            printController.printFormatter = printFormatter
                            
                            printController.present(animated: true, completionHandler: nil)
                        }
                    }) {
                        Image(systemName: "printer")
                    }
                }
            }
        }
    }
    
    private func generateHTMLContent() -> String {
        var html = """
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; }
                .header { text-align: center; margin-bottom: 30px; }
                .title { font-size: 24pt; font-weight: bold; margin-bottom: 10px; }
                .subtitle { font-size: 16pt; color: #666; margin-bottom: 5px; }
                .sort-info { font-size: 12pt; color: #666; }
                .section-title-main { font-size: 20pt; font-weight: bold; margin-top: 20px; margin-bottom: 10px; border-bottom: 1px solid #000; }
                .section-title-sub { font-size: 16pt; font-weight: 600; margin-top: 15px; margin-bottom: 8px; }
                .wine-row { margin-bottom: 8px; padding: 5px 0; }
                .wine-name { font-size: 14pt; font-weight: 600; }
                .wine-details { font-size: 12pt; color: #666; margin-top: 2px; }
                hr { border: none; height: 1px; background-color: #ccc; margin: 10px 0; }
            </style>
        </head>
        <body>
            <div class="header">
                <div class="title">\(settings.printTitle)</div>
        """
        
        if !settings.printSubtitle.isEmpty {
            html += "<div class=\"subtitle\">\(settings.printSubtitle)</div>"
        }
        
        html += "<div class=\"subtitle\">Total Wines: \(totalQuantity)</div>"
        html += "</div>"
        
        for group in groupedWines() {
            if let wine = group.wine {
                // Wine row for print
                let vintage = wine.vintage ?? ""
                let producer = wine.producer ?? "-"
                let nameAndVintage = "\(wine.name ?? "Unknown") \(vintage)".trimmingCharacters(in: .whitespaces)
                
                var details: [String] = []
                details.append("Qty: \(wine.quantity)")
                
                if let size = wine.bottleSize, !size.isEmpty {
                    details.append(settings.getDisplayBottleSize(size))
                }
                if let alcohol = wine.alcohol, !alcohol.isEmpty {
                    details.append("\(alcohol)%")
                }
                if let price = wine.price, price != 0,
                   !(settings.selectedSortOrder?.fields.contains(.price) ?? false) {
                    details.append("\(price) \(settings.currencySymbol)")
                }
                if let storageLocation = wine.storageLocation, !storageLocation.isEmpty {
                    details.append(storageLocation)
                }
                
                html += """
                <div class="wine-row">
                    <div class="wine-name">\(nameAndVintage), \(producer)</div>
                    <div class="wine-details">\(details.joined(separator: " • "))</div>
                </div>
                """
            } else if !group.title.isEmpty {
                // Section title
                let cssClass = group.level == 0 ? "section-title-main" : "section-title-sub"
                html += "<div class=\"\(cssClass)\">\(group.title)</div>"
            }
        }
        
        html += "</body></html>"
        return html
    }
}

struct PrintWineRowView: View {
    @ObservedObject var wine: Wine
    @EnvironmentObject var settings: SettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // First line: Name, vintage, and producer combined
            HStack {
                Text("\(wine.name ?? "Unknown") \(wine.vintage ?? ""), \(wine.producer ?? "-")")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            
            // Second line: Bottom metadata (same as third line in ContentView)
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
                if let price = wine.price, price != 0,
                   !(settings.selectedSortOrder?.fields.contains(.price) ?? false) {
                    Text("•")
                    Text("\(price) \(settings.currencySymbol)")
                }
                if let storageLocation = wine.storageLocation, !storageLocation.isEmpty {
                    Text("•")
                    Text(storageLocation)
                }
                Spacer()
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 1)
    }
}
