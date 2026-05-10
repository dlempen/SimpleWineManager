import SwiftUI

struct ManualView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var expandedSections = Set<String>()
    
    private let manualSections = [
        ManualSectionData(
            id: "add-wine",
            title: "Adding Wines",
            content: """
Adding wines to your collection is quick and easy:

• **Basic Information**: Enter wine name, winery, variety, and vintage
• **Photos**: Capture or select front and back label images
• **Tasting Notes**: Record your impressions, flavors, and observations
• **Technical Details**: Add alcohol content, region, country, and price information
• **Personal Rating**: Rate wines from 1-5 stars based on your preference
• **Purchase Details**: Track where and when you bought each wine

**Photo Tips:**
• Use good lighting for clear label photos
• Keep labels straight and centered in the frame
• Both front and back label photos are optional but recommended
• Images are automatically optimized for storage efficiency

**Quick Entry:**
• Required fields are marked with an asterisk (*)
• Save time by filling in basic details first, then adding more information later
• Use the camera icon to quickly capture wine labels while shopping
"""
        ),
        ManualSectionData(
            id: "edit-wine",
            title: "Editing Wine Information",
            content: """
Modify and update your wine information anytime:

• **Edit Any Field**: Tap on wine details to modify information
• **Update Photos**: Replace or add new label images
• **Revise Tasting Notes**: Update your impressions after re-tasting
• **Adjust Ratings**: Change your rating as your palate evolves
• **Add Missing Details**: Fill in information you didn't have when first adding the wine

**Best Practices:**
• Keep tasting notes detailed and specific
• Update ratings after multiple tastings for accuracy
• Add purchase location and date for reference
• Include food pairing experiences in your notes

**Bulk Updates:**
• Use search to find similar wines for consistent updates
• Copy wine information to maintain consistency across similar bottles
• Update region/country information for better organization
"""
        ),
        ManualSectionData(
            id: "copy-wine",
            title: "Copying Wine Entries",
            content: """
Save time by copying existing wine entries:

• **Duplicate Similar Wines**: Copy wines from the same winery or vintage
• **Preserve Details**: All information except tasting notes and rating are copied
• **Quick Variations**: Create entries for different vintages of the same wine
• **Batch Entry**: Efficiently add multiple wines with similar characteristics

**How to Copy:**
1. Find the wine you want to copy in your collection
2. Tap the "Copy Wine" option in the wine details menu
3. A new entry will be created with the same details
4. Modify the copied entry as needed (vintage, tasting notes, etc.)

**What Gets Copied:**
• Wine name and winery information
• Variety and region details
• Technical specifications
• Purchase information template

**What Doesn't Get Copied:**
• Personal tasting notes (start fresh for each wine)
• Ratings (each wine deserves its own evaluation)
• Photos (add specific label images for each wine)
"""
        ),
        ManualSectionData(
            id: "search",
            title: "Basic Search",
            content: """
Find wines in your collection quickly using basic search:

• **Text Search**: Enter any text to search across all wine fields
• **Instant Results**: See results update as you type
• **Comprehensive Coverage**: Searches wine names, wineries, varieties, regions, and notes
• **Case Insensitive**: Search works regardless of capitalization
• **Partial Matches**: Find wines even with incomplete search terms

**Search Tips:**
• Use specific terms for better results (e.g., "Cabernet" vs "red")
• Search by winery name to find all wines from a producer
• Look for wines by region (e.g., "Napa Valley", "Tuscany")
• Search vintage years to find wines from specific years
• Use rating numbers to find highly-rated wines

**Examples:**
• "2018 Pinot" - finds 2018 Pinot Noir wines
• "Bordeaux" - shows all wines from Bordeaux region  
• "Caymus" - displays all wines from Caymus winery
• "5" - finds all 5-star rated wines in your collection
"""
        ),
        ManualSectionData(
            id: "advanced-search",
            title: "Advanced Search",
            content: """
Use advanced search for precise wine discovery:

• **Multiple Filters**: Combine different criteria for specific results
• **Rating Filters**: Find wines within specific rating ranges
• **Vintage Filters**: Search by year or year range
• **Price Filters**: Filter by purchase price ranges
• **Region Filters**: Narrow down by geographic areas
• **Variety Filters**: Focus on specific grape types

**Filter Combinations:**
• Mix and match filters for precise results
• Clear individual filters without affecting others
• See result count update as you add/remove filters
• Save time finding wines that match multiple criteria

**Advanced Techniques:**
• Use rating filters to find wines ready to drink
• Combine vintage and region filters for specific wine styles
• Filter by price to find wines within budget ranges
• Search varieties to explore different grape expressions

**Quick Access:**
• Access advanced search from the main wine list
• Filters remain active until manually cleared
• Return to basic search anytime
• Export filtered results for sharing
"""
        ),
        ManualSectionData(
            id: "print-wine-list",
            title: "Printing Wine Lists",
            content: """
Create physical copies of your wine collection:

• **Print Current View**: Print exactly what you see in your wine list
• **Include Photos**: Option to include wine label images in printouts
• **Custom Formatting**: Choose layout and information to include
• **Filter Before Printing**: Use search/filters to print specific wines only
• **Multiple Formats**: Select from different print layouts and styles

**Print Options:**
• Summary view with basic information
• Detailed view with tasting notes and ratings
• Photo-included versions for visual reference
• Compact lists for storage and reference

**Use Cases:**
• Wine cellar inventory lists
• Shopping reference guides
• Insurance documentation
• Sharing collections with friends
• Backup physical records

**Preparation Tips:**
• Filter your collection to show only wines you want to print
• Check printer settings for best quality
• Consider paper size for optimal layout
• Preview before printing to avoid waste
"""
        ),
        ManualSectionData(
            id: "history-statistics",
            title: "History and Statistics",
            content: """
Track your wine journey with comprehensive analytics:

• **Collection Growth**: See how your collection has grown over time
• **Purchase Patterns**: Analyze your buying habits and preferences
• **Rating Trends**: Track how your ratings change over time
• **Variety Distribution**: View breakdown of grape varieties in your collection
• **Geographic Analysis**: See distribution of wines by region and country
• **Price Analytics**: Understand your spending patterns and value trends

**History Tracking:**
• Date added for each wine
• Purchase price and location tracking
• Rating changes over time
• Tasting note evolution

**Statistical Insights:**
• Most collected varieties and regions
• Average ratings by wine type
• Price ranges and spending analysis
• Collection value estimates

**Trend Analysis:**
• Seasonal purchasing patterns
• Rating consistency across wine types
• Geographic preference evolution
• Price-to-rating correlation insights

**Export Statistics:**
• Generate reports for insurance purposes
• Share collection insights with fellow enthusiasts
• Track collection value over time
• Identify gaps or opportunities in your collection
"""
        ),
        ManualSectionData(
            id: "sort-order",
            title: "Sort Order Settings",
            content: """
Wine Manager allows you to customize how your wine collection is displayed and organized:

• **Create Custom Sort Orders**: Set up different sorting arrangements based on your preferences
• **Multiple Sort Fields**: Chain multiple sorting criteria (e.g., first by region, then by vintage, then by variety)
• **Section Headers**: Toggle fields to appear as section headers for better organization
• **Quick Selection**: Choose from predefined sort orders or create your own
• **Field Priority**: Arrange fields in order of importance for your wine list display

**Available Sort Fields:**
• Wine Name - The name of the wine
• Winery - The producer/winery name  
• Variety - Grape variety (e.g., Cabernet Sauvignon)
• Vintage - Year the wine was produced
• Region - Geographic region where grapes were grown
• Country - Country of origin
• Rating - Your personal rating
• Price - Purchase price
• Date Added - When you added the wine to your collection

**Tips:**
• Use section headers (blue fields) to create visual groupings in your wine list
• Combine geographic sorting (Country → Region) for location-based organization
• Sort by rating and price to quickly find your favorites or budget options
"""
        ),
        ManualSectionData(
            id: "ai-fill",
            title: "AI Fill — Auto-complete Wine Details",
            content: """
The ✨ AI Fill button uses OpenAI to automatically look up and fill in missing information about a wine based on the name and/or producer you've already entered.

**What it fills in:**
• Producer / winery name
• Vintage year
• Grape variety / blend
• Country and region
• Sub-region / appellation
• Wine type and category
• Alcohol content
• Drink-from and best-before years
• Tasting notes and remarks
• Average market price

**How to use it:**
1. Start adding or editing a wine — enter at least the wine name or producer
2. Tap the **✨ AI Fill** button in the toolbar
3. Wait a moment while the AI searches the web for information
4. A preview screen appears showing everything the AI found
5. Each field has a checkmark on the right — uncheck any field you don't want to apply
6. Tap **Apply** to copy the selected fields into your wine entry

**Tips:**
• The more detail you enter first (name + producer + vintage), the better the results
• Already-filled fields are not overwritten unless you explicitly check them in the preview
• The Sources section at the bottom of the preview lists the web pages the AI used — tap any link to verify the information
• AI suggestions are a starting point — always review before saving

**Getting an OpenAI API key:**
1. Go to **platform.openai.com** in your browser
2. Sign in or create a free account
3. Navigate to **API keys** in the left sidebar (or visit platform.openai.com/api-keys directly)
4. Click **Create new secret key**, give it a name, and copy it
5. In Wine Manager, open **Settings → AI Integration** and paste your key into the API Key field
6. Your key is stored securely in the device Keychain — it never leaves your device in plain text

**Usage and cost:**
• OpenAI charges a small amount per request (typically a fraction of a cent per wine lookup)
• New accounts receive free credits to get started
• You can monitor your usage at platform.openai.com/usage
"""
        ),
        ManualSectionData(
            id: "import-export",
            title: "Import and Export",
            content: """
Share and backup your wine collection data:

**Export Options:**
• **Share Collection**: Export selected wines or entire collection
• **CSV Format**: Standard format compatible with spreadsheet applications
• **Custom Selection**: Choose specific wines to export
• **Include Photos**: Option to include wine label images in exports
• **Metadata Included**: All wine information, ratings, and notes preserved

**Import Capabilities:**
• **CSV Import**: Import wines from spreadsheet files
• **Merge or Replace**: Choose how to handle existing wines
• **Data Validation**: Automatic checking for valid wine information
• **Error Reporting**: Clear feedback on import issues
• **Preview Before Import**: Review wines before adding to collection

**Supported Import Formats:**
• Wine Manager export files (.swm)
• Comma-separated values (.csv)
• Standard text files with wine data

**Best Practices:**
• Export your collection regularly as backup
• Use CSV format for compatibility with other wine apps
• Include photos in exports for complete backup
• Validate import data before processing
• Keep original files as additional backup

**Sharing Scenarios:**
• Send collection to friends and family
• Backup before device changes
• Collaborate on wine selections
• Import wine lists from wine shops or events
"""
        )
    ]
    
    var filteredSections: [ManualSectionData] {
        if searchText.isEmpty {
            return manualSections
        } else {
            return manualSections.filter { section in
                section.title.localizedCaseInsensitiveContains(searchText) ||
                section.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search manual...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            // Manual content
            if filteredSections.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Try searching for different terms or browse all sections")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredSections) { section in
                            CollapsibleManualSection(
                                section: section,
                                isExpanded: expandedSections.contains(section.id)
                            ) {
                                if expandedSections.contains(section.id) {
                                    expandedSections.remove(section.id)
                                } else {
                                    expandedSections.insert(section.id)
                                }
                            }
                            
                            if section.id != filteredSections.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Tips section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Wine Management Tips")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TipRow(icon: "sparkles", text: "Use ✨ AI Fill to auto-complete wine details — just enter the name or producer first")
                                TipRow(icon: "camera", text: "Take clear photos of wine labels for easy identification")
                                TipRow(icon: "star", text: "Rate wines immediately after tasting for accurate records")
                                TipRow(icon: "square.and.pencil", text: "Keep detailed tasting notes to track your preferences")
                                TipRow(icon: "location", text: "Record where you purchased wines for future reference")
                                TipRow(icon: "clock", text: "Note optimal drinking windows in your wine descriptions")
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6).opacity(0.5))
                    }
                }
            }
        }
        .navigationTitle("User Manual")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ManualSectionData: Identifiable {
    let id: String
    let title: String
    let content: String
}

struct CollapsibleManualSection: View {
    let section: ManualSectionData
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .background(Color(.systemGray6).opacity(0.3))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}