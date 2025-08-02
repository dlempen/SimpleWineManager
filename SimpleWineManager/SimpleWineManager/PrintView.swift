import SwiftUI

struct PrintView: View {
    @ObservedObject var viewModel: WineListViewModel
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    // Local editable state for print titles
    @State private var editableTitle: String = ""
    @State private var editableSubtitle: String = ""
    @State private var editableTotal: String = ""
    
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
    
    // Helper function to get current date in dd.mm.yyyy format
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: Date())
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
        case .quantity: return String(format: "%03d", wine.quantity) // Pad with zeros for proper sorting
        case .bottleSize: 
            // Extract numeric value from bottle size for proper numerical sorting
            guard let bottleSize = wine.bottleSize else { return "00000" }
            let numericString = bottleSize.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            if let numericValue = Double(numericString) {
                return String(format: "%05.0f", numericValue) // Pad with zeros for proper sorting
            }
            return "00000" // Default for invalid values
        case .readyToTrinkYear: return wine.readyToTrinkYear ?? ""
        case .bestBeforeYear: return wine.bestBeforeYear ?? ""
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
                    // Editable Header Section
                    VStack(alignment: .center, spacing: 12) {
                        // Editable Title
                        TextField("Title", text: $editableTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                        
                        // Editable Subtitle
                        TextField("Subtitle", text: $editableSubtitle)
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                        
                        // Editable Total Count
                        TextField("Total", text: $editableTotal)
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                        
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
                                    Text(formatSectionTitle(group.title))
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
            .onAppear {
                // Initialize with default values
                editableTitle = "Wine List"
                editableSubtitle = currentDateString
                editableTotal = "Total Wines: \(totalQuantity)"
            }
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
    
    private func formatSectionTitle(_ title: String) -> String {
        // Check if the title looks like a padded bottle size (e.g., "00750")
        if title.count == 5 && title.allSatisfy(\.isNumber) {
            // Remove leading zeros and add unit
            let numericValue = Int(title) ?? 0
            if numericValue > 0 {
                return settings.getDisplayBottleSize("\(numericValue)ml")
            }
        }
        
        // Check if it's a padded quantity (e.g., "001", "012")
        if title.count == 3 && title.allSatisfy(\.isNumber) {
            let numericValue = Int(title) ?? 0
            return "\(numericValue)"
        }
        
        return title
    }
    
    private func generateHTMLContent() -> String {
        var html = """
        <html>
        <head>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                    margin: 20px; 
                    line-height: 1.2;
                    -webkit-print-color-adjust: exact;
                    color-adjust: exact;
                    /* Prevent any text from breaking across pages */
                    -webkit-region-break-inside: avoid;
                    break-inside: avoid;
                }
                .header { 
                    text-align: center; 
                    margin-bottom: 20px; 
                    page-break-after: avoid;
                }
                .title { 
                    font-size: 22pt; 
                    font-weight: bold; 
                    margin-bottom: 8px; 
                    line-height: 1.2;
                    /* Keep title together as a block */
                    page-break-inside: avoid;
                    break-inside: avoid;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                .subtitle { 
                    font-size: 14pt; 
                    color: #666; 
                    margin-bottom: 4px; 
                    line-height: 1.2;
                    /* Keep subtitle together as a block */
                    page-break-inside: avoid;
                    break-inside: avoid;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                .sort-info { 
                    font-size: 12pt; 
                    color: #666; 
                }
                .section-group {
                    page-break-inside: avoid;
                    break-inside: avoid;
                    margin-bottom: 4px;
                }
                .section-title-main { 
                    font-size: 18pt; 
                    font-weight: bold; 
                    margin-top: 16px; 
                    margin-bottom: 8px; 
                    border-bottom: 1px solid #000; 
                    /* CRITICAL: Never allow titles to be the last line of a page */
                    page-break-after: avoid !important;
                    page-break-inside: avoid !important;
                    break-after: avoid !important;
                    break-inside: avoid !important;
                    /* Force titles to always have content following them */
                    orphans: 10 !important;
                    widows: 10 !important;
                    line-height: 1.3;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                    /* Absolutely ensure title cannot be alone at end of page */
                    keep-with-next: always !important;
                    -webkit-column-break-after: avoid !important;
                    column-break-after: avoid !important;
                }
                .section-title-sub { 
                    font-size: 15pt; 
                    font-weight: 600; 
                    margin-top: 18px; 
                    margin-bottom: 8px; 
                    /* CRITICAL: Never allow subtitles to be the last line of a page */
                    page-break-after: avoid !important;
                    page-break-inside: avoid !important;
                    break-after: avoid !important;
                    break-inside: avoid !important;
                    /* Force subtitles to always have content following them */
                    orphans: 10 !important;
                    widows: 10 !important;
                    line-height: 1.3;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                    /* Absolutely ensure subtitle cannot be alone at end of page */
                    keep-with-next: always !important;
                    -webkit-column-break-after: avoid !important;
                    column-break-after: avoid !important;
                }
                .section-group {
                    page-break-inside: avoid;
                    break-inside: avoid;
                    margin-bottom: 4px;
                    /* Ensure the entire section group stays together */
                    orphans: 3;
                    widows: 2;
                }
                .title-with-content {
                    /* Group titles with their first wine entries */
                    page-break-inside: avoid !important;
                    break-inside: avoid !important;
                    display: block !important;
                    /* Ensure minimum content stays with title */
                    orphans: 4 !important;
                    widows: 3 !important;
                    margin-bottom: 8px !important;
                    /* Prevent any breaking within this container */
                    -webkit-column-break-inside: avoid !important;
                    column-break-inside: avoid !important;
                    /* Keep the entire section together */
                    keep-together: always !important;
                }
                .wine-row { 
                    margin-bottom: 6px; 
                    padding: 4px 0; 
                    page-break-inside: avoid;
                    break-inside: avoid;
                    display: block;
                    min-height: 3em;
                    position: relative;
                    line-height: 1.4;
                    /* Keep wine entries together but allow text wrapping within */
                }
                .wine-name { 
                    font-size: 14pt; 
                    font-weight: 600; 
                    line-height: 1.3;
                    margin-bottom: 3px;
                    /* Allow text wrapping but keep name block together */
                    page-break-inside: avoid;
                    break-inside: avoid;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                .wine-details { 
                    font-size: 12pt; 
                    color: #666; 
                    line-height: 1.3;
                    margin-top: 0;
                    /* Allow text wrapping but keep details block together */
                    page-break-inside: avoid;
                    break-inside: avoid;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                hr { 
                    border: none; 
                    height: 1px; 
                    background-color: #ccc; 
                    margin: 10px 0; 
                }
                
                /* Print-specific styles */
                @media print {
                    * {
                        box-sizing: border-box !important;
                        -webkit-print-color-adjust: exact !important;
                        color-adjust: exact !important;
                        /* Global line break prevention */
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                    }
                    
                    body {
                        margin: 12px !important;
                        line-height: 1.15 !important;
                        font-size: 12pt !important;
                        /* Prevent any breaking in body */
                        -webkit-region-break-inside: avoid !important;
                        break-inside: avoid !important;
                    }
                    
                    .header {
                        page-break-after: avoid !important;
                        break-after: avoid !important;
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        margin-bottom: 16px !important;
                    }
                    
                    .title {
                        page-break-after: avoid !important;
                        break-after: avoid !important;
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        word-wrap: break-word !important;
                        overflow-wrap: break-word !important;
                        font-size: 20pt !important;
                        line-height: 1.2 !important;
                    }
                    
                    .subtitle {
                        page-break-after: avoid !important;
                        break-after: avoid !important;
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        word-wrap: break-word !important;
                        overflow-wrap: break-word !important;
                        font-size: 13pt !important;
                        line-height: 1.2 !important;
                    }
                    
                    .section-title-main {
                        /* ABSOLUTE RULE: Main titles can NEVER be the last line of a page */
                        page-break-after: avoid !important;
                        break-after: avoid !important;
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        /* Maximum orphan protection - force multiple lines to follow */
                        orphans: 15 !important;
                        widows: 10 !important;
                        margin-top: 14px !important;
                        margin-bottom: 6px !important;
                        padding-bottom: 2px !important;
                        min-height: 24px !important;
                        word-wrap: break-word !important;
                        overflow-wrap: break-word !important;
                        font-size: 16pt !important;
                        line-height: 1.2 !important;
                        /* Strongest possible keep-with-next properties */
                        keep-with-next: always !important;
                        -webkit-column-break-after: avoid !important;
                        column-break-after: avoid !important;
                        /* Additional properties to force page break before if needed */
                        -webkit-region-break-after: avoid !important;
                        region-break-after: avoid !important;
                    }
                    
                    .section-title-sub {
                        /* ABSOLUTE RULE: Subtitles can NEVER be the last line of a page */
                        page-break-after: avoid !important;
                        break-after: avoid !important;
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        /* Maximum orphan protection - force multiple lines to follow */
                        orphans: 15 !important;
                        widows: 10 !important;
                        margin-top: 16px !important;
                        margin-bottom: 8px !important;
                        min-height: 20px !important;
                        word-wrap: break-word !important;
                        overflow-wrap: break-word !important;
                        font-size: 14pt !important;
                        line-height: 1.2 !important;
                        /* Strongest possible keep-with-next properties */
                        keep-with-next: always !important;
                        -webkit-column-break-after: avoid !important;
                        column-break-after: avoid !important;
                        /* Additional properties to force page break before if needed */
                        -webkit-region-break-after: avoid !important;
                        region-break-after: avoid !important;
                        /* Normalize any special character spacing */
                        text-rendering: optimizeLegibility !important;
                        font-kerning: normal !important;
                    }
                    
                    .wine-row {
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        page-break-before: auto !important;
                        page-break-after: auto !important;
                        margin-bottom: 4px !important;
                        padding: 3px 0 !important;
                        min-height: 36px !important;
                        position: relative !important;
                        overflow: visible !important;
                        /* Ensure the entire wine row never breaks */
                        display: block !important;
                        line-height: 1.3 !important;
                    }
                    
                    .wine-name {
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        margin-bottom: 2px !important;
                        line-height: 1.2 !important;
                        font-size: 13pt !important;
                        word-wrap: break-word !important;
                        overflow-wrap: break-word !important;
                        display: block !important;
                    }
                    
                    .wine-details {
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        margin-top: 0 !important;
                        line-height: 1.2 !important;
                        font-size: 11pt !important;
                        word-wrap: break-word !important;
                        overflow-wrap: break-word !important;
                        display: block !important;
                    }
                    
                    /* Specific rules for smaller paper sizes */
                    @page {
                        margin: 12mm !important;
                        orphans: 4 !important;
                        widows: 4 !important;
                    }
                    
                    /* Force consistent spacing regardless of content */
                    .section-title-main + .wine-row,
                    .section-title-sub + .wine-row {
                        margin-top: 0 !important;
                        padding-top: 2px !important;
                    }
                    
                    /* Prevent ANY element from breaking across pages while allowing text wrapping */
                    h1, h2, h3, h4, h5, h6,
                    .section-title-main,
                    .section-title-sub,
                    .wine-row,
                    .wine-name,
                    .wine-details,
                    div, p, span {
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        word-wrap: break-word !important;
                        overflow-wrap: break-word !important;
                    }
                    
                    /* Allow proper text wrapping */
                    .wine-row .wine-name,
                    .wine-row .wine-details {
                        word-break: normal !important;
                        word-wrap: break-word !important;
                        overflow-wrap: break-word !important;
                        hyphens: auto !important;
                        -webkit-hyphens: auto !important;
                        -ms-hyphens: auto !important;
                    }
                    
                    /* STRONGEST ORPHAN PREVENTION RULES */
                    /* These rules ensure no title/subtitle can ever be at the end of a page */
                    .section-title-main,
                    .section-title-sub {
                        /* Force minimum 5 lines to follow any title/subtitle */
                        orphans: 20 !important;
                        widows: 20 !important;
                        /* Multiple fallback mechanisms for different browsers */
                        page-break-after: avoid !important;
                        break-after: avoid !important;
                        -webkit-column-break-after: avoid !important;
                        column-break-after: avoid !important;
                        -moz-page-break-after: avoid !important;
                        -webkit-region-break-after: avoid !important;
                        region-break-after: avoid !important;
                        /* Absolutely force them to stay with next element */
                        keep-with-next: always !important;
                        -webkit-keep-with-next: always !important;
                        /* Additional display properties to strengthen the constraint */
                        display: block !important;
                        float: none !important;
                        clear: both !important;
                    }
                    
                    /* Ensure wine rows immediately following titles stay with them */
                    .section-title-main + .wine-row,
                    .section-title-sub + .wine-row {
                        page-break-before: avoid !important;
                        break-before: avoid !important;
                        margin-top: 0 !important;
                        padding-top: 2px !important;
                        /* These wine rows cannot be separated from their titles */
                        orphans: 1 !important;
                        widows: 1 !important;
                    }
                    
                    /* Title containers must stay together with their content */
                    .title-with-content {
                        page-break-inside: avoid !important;
                        break-inside: avoid !important;
                        page-break-after: auto !important;
                        break-after: auto !important;
                        /* Ensure the entire container is treated as a unit */
                        display: block !important;
                        overflow: visible !important;
                        orphans: 10 !important;
                        widows: 10 !important;
                    }
                }
            </style>
        </head>
        <body>
            <div class="header">
                <div class="title">\(editableTitle)</div>
        """
        
        if !editableSubtitle.isEmpty {
            html += "<div class=\"subtitle\">\(editableSubtitle)</div>"
        }
        
        if !editableTotal.isEmpty {
            html += "<div class=\"subtitle\">\(editableTotal)</div>"
        }
        html += "</div>"
        
        // Process groups and create sections that keep titles with their wine entries
        let allGroups = groupedWines()
        var i = 0
        var currentSectionHTML = ""
        var hasSectionTitle = false
        
        while i < allGroups.count {
            let group = allGroups[i]
            
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
                
                let wineHTML = """
                <div class="wine-row">
                    <div class="wine-name">\(nameAndVintage), \(producer)</div>
                    <div class="wine-details">\(details.joined(separator: " • "))</div>
                </div>
                """
                
                if hasSectionTitle {
                    // Add this wine to the current section
                    currentSectionHTML += wineHTML
                    
                    // Check if the next item is another wine or if we're at the end
                    let nextIndex = i + 1
                    let isLastItem = nextIndex >= allGroups.count
                    let nextIsTitle = !isLastItem && allGroups[nextIndex].wine == nil
                    
                    if isLastItem || nextIsTitle {
                        // Close the current section and add it to HTML
                        html += "<div class=\"title-with-content\">\(currentSectionHTML)</div>"
                        currentSectionHTML = ""
                        hasSectionTitle = false
                    }
                } else {
                    // No section title, add wine directly
                    html += wineHTML
                }
                
            } else if !group.title.isEmpty {
                // Section title - clean the title to prevent any spacing issues
                let cleanTitle = formatSectionTitle(group.title.trimmingCharacters(in: .whitespacesAndNewlines))
                let cssClass = group.level == 0 ? "section-title-main" : "section-title-sub"
                
                // If we have an open section, close it first
                if hasSectionTitle {
                    html += "<div class=\"title-with-content\">\(currentSectionHTML)</div>"
                }
                
                // Start a new section
                currentSectionHTML = "<div class=\"\(cssClass)\">\(cleanTitle)</div>"
                hasSectionTitle = true
            }
            
            i += 1
        }
        
        // Close any remaining open section
        if hasSectionTitle {
            html += "<div class=\"title-with-content\">\(currentSectionHTML)</div>"
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
