import SwiftUI
import CoreData

struct WineHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var historyService: WineHistoryService
    
    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedTimeRange: TimeRange = .all
    @State private var searchText = ""
    @State private var showingStatistics = false
    
    private var filteredHistory: [WineHistory] {
        let history = historyService.getRecentHistory(limit: nil)
        
        // Apply action filter
        let actionFiltered = selectedFilter == .all ? history : history.filter { $0.actionType == selectedFilter.actionType }
        
        // Apply time range filter
        let timeFiltered = selectedTimeRange.filterHistory(actionFiltered)
        
        // Apply search filter
        if searchText.isEmpty {
            return timeFiltered
        } else {
            let searchLower = searchText.lowercased()
            return timeFiltered.filter { entry in
                (entry.wineName?.lowercased().contains(searchLower) ?? false) ||
                (entry.wineProducer?.lowercased().contains(searchLower) ?? false) ||
                (entry.changeDetails?.lowercased().contains(searchLower) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search history...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top)
                
                // Filter controls
                VStack(spacing: 12) {
                    // Action filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.displayName,
                                    icon: filter.icon,
                                    isSelected: selectedFilter == filter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Time range filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                FilterChip(
                                    title: range.displayName,
                                    icon: "calendar",
                                    isSelected: selectedTimeRange == range,
                                    action: { selectedTimeRange = range }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                Divider()
                
                // History list
                if filteredHistory.isEmpty {
                    ContentUnavailableView(
                        "No History Found",
                        systemImage: "clock",
                        description: Text("No wine collection changes match your current filters.")
                    )
                } else {
                    List {
                        ForEach(groupHistoryByDate(filteredHistory), id: \.date) { group in
                            Section {
                                ForEach(group.entries, id: \.self) { entry in
                                    HistoryRowView(entry: entry)
                                }
                            } header: {
                                Text(formatSectionDate(group.date))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Wine History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingStatistics = true }) {
                        Image(systemName: "chart.bar")
                    }
                }
            }
            .sheet(isPresented: $showingStatistics) {
                HistoryStatisticsView(historyService: historyService)
            }
        }
    }
    
    private func groupHistoryByDate(_ history: [WineHistory]) -> [HistoryDateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: history) { entry in
            calendar.startOfDay(for: entry.timestamp ?? Date())
        }
        
        return grouped.map { HistoryDateGroup(date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

struct HistoryRowView: View {
    let entry: WineHistory
    
    var body: some View {
        HStack(spacing: 12) {
            // Action icon
            Image(systemName: entry.actionType.icon)
                .font(.title2)
                .foregroundColor(entry.actionType.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                // Wine name and action
                HStack {
                    Text(entry.wineName ?? "Unknown Wine")
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(formatTime(entry.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Producer and vintage
                if let producer = entry.wineProducer, !producer.isEmpty {
                    Text("\(producer)\(entry.wineVintage?.isEmpty == false ? " • \(entry.wineVintage!)" : "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Action description
                Text(entry.actionType.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Change details if available
                if let details = entry.changeDetails, !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct HistoryDateGroup {
    let date: Date
    let entries: [WineHistory]
}

enum HistoryFilter: CaseIterable {
    case all, added, edited, deleted, consumed
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .added: return "Added"
        case .edited: return "Edited"
        case .deleted: return "Deleted"
        case .consumed: return "Consumed"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .added: return "plus.circle"
        case .edited: return "pencil.circle"
        case .deleted: return "trash.circle"
        case .consumed: return "wineglass"
        }
    }
    
    var actionType: WineHistory.ActionType? {
        switch self {
        case .all: return nil
        case .added: return .added
        case .edited: return .edited
        case .deleted: return .deleted
        case .consumed: return .consumed
        }
    }
}

enum TimeRange: CaseIterable {
    case all, today, week, month, year
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .today: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
    
    func filterHistory(_ history: [WineHistory]) -> [WineHistory] {
        switch self {
        case .all:
            return history
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            return history.filter { entry in
                guard let timestamp = entry.timestamp else { return false }
                return Calendar.current.isDate(timestamp, inSameDayAs: today)
            }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            return history.filter { entry in
                guard let timestamp = entry.timestamp else { return false }
                return timestamp >= weekAgo
            }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return history.filter { entry in
                guard let timestamp = entry.timestamp else { return false }
                return timestamp >= monthAgo
            }
        case .year:
            let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            return history.filter { entry in
                guard let timestamp = entry.timestamp else { return false }
                return timestamp >= yearAgo
            }
        }
    }
}
