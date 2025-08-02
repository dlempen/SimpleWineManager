import SwiftUI
import QuickLook

struct PrintView: View {
    @ObservedObject var viewModel: WineListViewModel
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    // Local editable state for print titles
    @State private var editableTitle: String = ""
    @State private var editableSubtitle: String = ""
    @State private var editableTotal: String = ""
    
    // PDF-related state variables
    @State private var showingPDFPreview = false
    @State private var pdfURL: URL?
    
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
                        generatePDFForPrintOrShare()
                    }) {
                        Image(systemName: "printer")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let url = pdfURL {
                PDFPreviewView(pdfURL: url, isPresented: $showingPDFPreview)
            }
        }
    }
    
    // PDF Export Function - Unified approach
    private func generatePDFForPrintOrShare() {
        // Generate HTML content first
        let htmlContent = generateHTMLContent()
        print("Generated HTML content length: \(htmlContent.count)")
        print("Filtered wines count: \(filteredWines.count)")
        
        // Create a print formatter with our HTML content
        let printFormatter = UIMarkupTextPrintFormatter(markupText: htmlContent)
        printFormatter.perPageContentInsets = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36)
        
        // Create a print page renderer
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        // Set up page size (A4) with proper paper and printable rects
        let paperSize = CGSize(width: 595.2, height: 841.8) // A4 in points
        let paperRect = CGRect(origin: .zero, size: paperSize)
        let printableRect = CGRect(
            x: 36, y: 36,
            width: paperSize.width - 72, height: paperSize.height - 72
        )
        
        renderer.setValue(paperRect, forKey: "paperRect")
        renderer.setValue(printableRect, forKey: "printableRect")
        
        // Force prepare for draw to calculate page count
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: 1))
        
        // Debug: Check number of pages
        let numberOfPages = renderer.numberOfPages
        print("PDF will have \(numberOfPages) pages")
        
        if numberOfPages == 0 {
            print("ERROR: No pages to render - check if HTML content is valid")
            return
        }
        
        // Create PDF data
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        
        for pageIndex in 0..<numberOfPages {
            UIGraphicsBeginPDFPage()
            let bounds = UIGraphicsGetPDFContextBounds()
            renderer.drawPage(at: pageIndex, in: bounds)
        }
        
        UIGraphicsEndPDFContext()
        
        print("PDF data size: \(pdfData.length) bytes")
        
        // Save PDF to temporary file
        let documentsPath = FileManager.default.temporaryDirectory
        let pdfPath = documentsPath.appendingPathComponent("WineList_\(Date().timeIntervalSince1970).pdf")
        
        do {
            try pdfData.write(to: pdfPath)
            print("PDF saved to: \(pdfPath)")
            pdfURL = pdfPath
            showingPDFPreview = true
        } catch {
            print("Error creating PDF: \(error)")
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
                    font-size: 12px;
                }
                .header { 
                    text-align: center; 
                    margin-bottom: 20px; 
                    border-bottom: 2px solid #000;
                    padding-bottom: 10px;
                }
                .title { 
                    font-size: 24px; 
                    font-weight: bold; 
                    margin-bottom: 8px;
                }
                .subtitle { 
                    font-size: 16px; 
                    color: #666; 
                    margin-bottom: 4px;
                }
                .section-title-main { 
                    font-size: 18px; 
                    font-weight: bold; 
                    margin-top: 16px; 
                    margin-bottom: 8px; 
                    border-bottom: 1px solid #000;
                    padding-bottom: 2px;
                }
                .section-title-sub { 
                    font-size: 14px; 
                    font-weight: 600; 
                    margin-top: 12px; 
                    margin-bottom: 6px; 
                    color: #333;
                }
                .wine-row { 
                    margin-bottom: 8px; 
                    padding: 4px 0;
                    border-bottom: 1px solid #eee;
                }
                .wine-name { 
                    font-weight: 500; 
                    margin-bottom: 2px;
                }
                .wine-details { 
                    font-size: 11px; 
                    color: #666; 
                }
                .title-with-content {
                    page-break-inside: avoid;
                }
                @media print {
                    body { margin: 0; }
                    .title-with-content {
                        page-break-inside: avoid;
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
        
        html += "<div class=\"subtitle\">\(editableTotal)</div>"
        html += "</div>"
        
        // Group section titles with their content to prevent page breaks
        let groupedItems = groupedWines()
        var i = 0
        var hasSectionTitle = false
        var currentSectionHTML = ""
        
        while i < groupedItems.count {
            let group = groupedItems[i]
            
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
                    currentSectionHTML += wineHTML
                } else {
                    html += wineHTML
                }
                
            } else if !group.title.isEmpty {
                // Close any previous section
                if hasSectionTitle {
                    html += "<div class=\"title-with-content\">\(currentSectionHTML)</div>"
                }
                
                // Start new section
                let cssClass = group.level == 0 ? "section-title-main" : "section-title-sub"
                let formattedTitle = formatSectionTitle(group.title)
                currentSectionHTML = "<div class=\"\(cssClass)\">\(formattedTitle)</div>"
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

// PDF Preview View with Print and Share options
struct PDFPreviewView: UIViewControllerRepresentable {
    let pdfURL: URL
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        previewController.delegate = context.coordinator
        
        let navController = UINavigationController(rootViewController: previewController)
        
        // Add custom toolbar items
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.donePressed)
        )
        
        let printButton = UIBarButtonItem(
            image: UIImage(systemName: "printer"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.printPressed)
        )
        
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: context.coordinator,
            action: #selector(Coordinator.sharePressed)
        )
        
        previewController.navigationItem.leftBarButtonItem = doneButton
        previewController.navigationItem.rightBarButtonItems = [shareButton, printButton]
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: PDFPreviewView
        
        init(_ parent: PDFPreviewView) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.pdfURL as QLPreviewItem
        }
        
        @objc func donePressed() {
            parent.isPresented = false
        }
        
        @objc func printPressed() {
            let printController = UIPrintInteractionController.shared
            printController.printingItem = parent.pdfURL
            
            // Get the current view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                var topController = rootViewController
                while let presentedController = topController.presentedViewController {
                    topController = presentedController
                }
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // iPad - use popover
                    printController.present(from: CGRect(x: window.bounds.maxX - 60, y: 100, width: 1, height: 1), in: topController.view, animated: true) { _, _, _ in }
                } else {
                    // iPhone - use sheet
                    printController.present(animated: true) { _, _, _ in }
                }
            }
        }
        
        @objc func sharePressed() {
            // Get the current view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            let activityViewController = UIActivityViewController(
                activityItems: [parent.pdfURL],
                applicationActivities: nil
            )
            
            // Configure for iPad
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: window.bounds.maxX - 60, y: 100, width: 1, height: 1)
                popover.permittedArrowDirections = [.up]
            }
            
            topController.present(activityViewController, animated: true)
        }
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
