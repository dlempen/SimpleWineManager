import SwiftUI

#if canImport(Charts)
import Charts
#endif

struct HistoryStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var historyService: WineHistoryService
    
    @State private var statistics: HistoryStatistics?
    @State private var selectedTimeframe: StatisticsTimeframe = .all
    @State private var isLoadingCharts = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if let stats = statistics {
                        // Overview Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Total Actions",
                                value: "\(stats.totalActions)",
                                icon: "list.bullet.circle",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Wines Added",
                                value: "\(stats.totalWinesAdded)",
                                icon: "plus.circle",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Wines Consumed",
                                value: "\(stats.totalWinesConsumed)",
                                icon: "wineglass",
                                color: .purple
                            )
                            
                            StatCard(
                                title: "Total Edits",
                                value: "\(stats.totalEdits)",
                                icon: "pencil.circle",
                                color: .orange
                            )                        }
                        
                        // Time Period Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(StatisticsTimeframe.allCases, id: \.self) { timeframe in
                                    StatisticsFilterChip(
                                        title: timeframe.displayName,
                                        isSelected: selectedTimeframe == timeframe,
                                        action: {
                                            withAnimation {
                                                isLoadingCharts = true
                                                selectedTimeframe = timeframe
                                            }
                                            
                                            // Slight delay to allow UI to update
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation {
                                                    isLoadingCharts = false
                                                }
                                            }
                                        }
                                    )
                                    .disabled(isLoadingCharts)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // Activity Over Time Chart (replacing Most Active Period)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Activity Over Time")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if isLoadingCharts {
                                VStack {
                                    ProgressView()
                                    Text("Loading chart data...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                            } else if #available(iOS 16.0, *) {
#if canImport(Charts)
                                Chart(getActivityChartData()) { item in
                                    LineMark(
                                        x: .value("Date", item.date),
                                        y: .value("Activity", item.activity)
                                    )
                                    .foregroundStyle(.orange.gradient)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                }
                                .frame(height: 200)
                                .padding(.horizontal)
                                .id("activity-chart-\(selectedTimeframe.displayName)")
#else
                                Text("Charts require iOS 16.0+")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200)
                                    .padding(.horizontal)
#endif
                            } else {
                                // Fallback for iOS 15
                                VStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("Charts require iOS 16+")
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Total Quantity Over Time Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Total Quantity Over Time")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if isLoadingCharts {
                                VStack {
                                    ProgressView()
                                    Text("Loading chart data...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                            } else if #available(iOS 16.0, *) {
#if canImport(Charts)
                                Chart(getQuantityChartData()) { item in
                                    LineMark(
                                        x: .value("Date", item.date),
                                        y: .value("Quantity", item.quantity)
                                    )
                                    .foregroundStyle(.blue.gradient)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                }
                                .frame(height: 200)
                                .padding(.horizontal)
                                .id("quantity-chart-\(selectedTimeframe.displayName)")
#else
                                Text("Charts require iOS 16.0+")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200)
                                    .padding(.horizontal)
#endif
                            } else {
                                // Fallback for iOS 15
                                VStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("Charts require iOS 16+")
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Total Value Over Time Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Total Value Over Time")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if isLoadingCharts {
                                VStack {
                                    ProgressView()
                                    Text("Loading chart data...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                            } else if #available(iOS 16.0, *) {
#if canImport(Charts)
                                Chart(getValueChartData()) { item in
                                    LineMark(
                                        x: .value("Date", item.date),
                                        y: .value("Value", item.value)
                                    )
                                    .foregroundStyle(.green.gradient)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                }
                                .frame(height: 200)
                                .padding(.horizontal)
                                .id("value-chart-\(selectedTimeframe.displayName)")
#else
                                Text("Charts require iOS 16.0+")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200)
                                    .padding(.horizontal)
#endif
                            } else {
                                // Fallback for iOS 15
                                VStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("Charts require iOS 16+")
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Consumption Over Time Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Consumption Over Time")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if isLoadingCharts {
                                VStack {
                                    ProgressView()
                                    Text("Loading chart data...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                            } else if #available(iOS 16.0, *) {
#if canImport(Charts)
                                Chart(getConsumptionChartData()) { item in
                                    LineMark(
                                        x: .value("Date", item.date),
                                        y: .value("Consumed", item.consumed)
                                    )
                                    .foregroundStyle(.purple.gradient)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                }
                                .frame(height: 200)
                                .padding(.horizontal)
                                .id("consumption-chart-\(selectedTimeframe.displayName)")
#else
                                Text("Charts require iOS 16.0+")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200)
                                    .padding(.horizontal)
#endif
                            } else {
                                // Fallback for iOS 15
                                VStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("Charts require iOS 16+")
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        ProgressView("Loading statistics...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadStatistics()
            }
        }
    }
    
    private func loadStatistics() {
        statistics = historyService.getStatistics()
    }
    
    private func getActivityChartData() -> [ActivityDataPoint] {
        guard statistics != nil else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = selectedTimeframe.getCutoffDate(from: now, historyService: historyService) ?? calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        // Get all history for date range calculation
        let allHistory = historyService.getRecentHistory(limit: nil)
        let allTimestamps = allHistory.compactMap { $0.timestamp }.sorted()
        
        // Determine end date based on timeframe
        let endDate: Date
        if selectedTimeframe == .all {
            // For "All" timeframe, use the last history entry date or now if no history
            endDate = allTimestamps.last ?? now
        } else {
            endDate = now
        }
        
        // Optimize grouping based on timeframe
        let (interval, component): (Int, Calendar.Component)
        let dateFormat: String
        switch selectedTimeframe {
        case .today:
            interval = 1
            component = .hour
            dateFormat = "yyyy-MM-dd-HH"
        case .week:
            interval = 1
            component = .day
            dateFormat = "yyyy-MM-dd"
        case .month:
            interval = 1
            component = .day
            dateFormat = "yyyy-MM-dd"
        case .year:
            interval = 1
            component = .weekOfYear
            dateFormat = "yyyy-ww"
        case .all:
            interval = 1
            component = .month
            dateFormat = "yyyy-MM"
        }
        
        let history = allHistory.filter { $0.timestamp != nil && $0.timestamp! >= cutoffDate && $0.timestamp! <= endDate }
        
        // For "Today" view, ensure we have at least some data points even if no activity today
        if selectedTimeframe == .today && history.isEmpty {
            // Create at least a few hourly data points for today to show the timeline
            var data: [ActivityDataPoint] = []
            var currentHour = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: currentHour) ?? now
            
            while currentHour < endOfDay {
                data.append(ActivityDataPoint(date: currentHour, activity: 0))
                currentHour = calendar.date(byAdding: .hour, value: 1, to: currentHour) ?? currentHour
            }
            return data.prefix(24).map { $0 } // Limit to 24 hours
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        var activityByPeriod: [String: Int] = [:]
        
        // Group activities by the appropriate time period
        for entry in history {
            guard let timestamp = entry.timestamp else { continue }
            let periodStart: Date
            switch component {
            case .hour:
                periodStart = calendar.dateInterval(of: .hour, for: timestamp)?.start ?? timestamp
            case .day:
                periodStart = calendar.startOfDay(for: timestamp)
            case .weekOfYear:
                periodStart = calendar.dateInterval(of: .weekOfYear, for: timestamp)?.start ?? timestamp
            case .month:
                periodStart = calendar.dateInterval(of: .month, for: timestamp)?.start ?? timestamp
            default:
                periodStart = calendar.startOfDay(for: timestamp)
            }
            
            let periodKey = dateFormatter.string(from: periodStart)
            activityByPeriod[periodKey, default: 0] += 1
        }
        
        var data: [ActivityDataPoint] = []
        var currentDate = cutoffDate
        
        // Generate data points
        while currentDate <= endDate {
            let periodKey = dateFormatter.string(from: currentDate)
            let activityCount = activityByPeriod[periodKey] ?? 0
            data.append(ActivityDataPoint(date: currentDate, activity: activityCount))
            
            currentDate = calendar.date(byAdding: component, value: interval, to: currentDate) ?? currentDate
            
            // Safety check to prevent infinite loops
            if data.count > 1000 {
                break
            }
        }
        
        // Special handling for "All" timeframe to ensure we have enough data points
        if selectedTimeframe == .all && data.count < 2 && !allTimestamps.isEmpty {
            // If we only have one data point for "All" timeframe, create additional points to show progression
            let firstDate = allTimestamps.first!
            let lastDate = allTimestamps.last!
            
            // Create at least 3-5 data points across the time range
            let timeSpan = lastDate.timeIntervalSince(firstDate)
            let numberOfPoints = min(max(3, Int(timeSpan / (30 * 24 * 3600))), 12) // 3-12 points based on time span
            
            data.removeAll()
            for i in 0..<numberOfPoints {
                let progress = Double(i) / Double(numberOfPoints - 1)
                let date = Date(timeIntervalSince1970: firstDate.timeIntervalSince1970 + progress * timeSpan)
                
                // Count activities up to this date
                let activitiesUpToDate = allHistory.filter { entry in
                    guard let timestamp = entry.timestamp else { return false }
                    return timestamp <= date
                }.count
                
                data.append(ActivityDataPoint(date: date, activity: activitiesUpToDate))
            }
        }
        
        // Limit data points for performance
        if data.count > 100 {
            let step = data.count / 50
            data = stride(from: 0, to: data.count, by: step).map { data[$0] }
        }
        
        return data.sorted { $0.date < $1.date }
    }
    
    private func getQuantityChartData() -> [QuantityDataPoint] {
        guard statistics != nil else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = selectedTimeframe.getCutoffDate(from: now, historyService: historyService) ?? calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        // Get all history for date range calculation
        let allHistory = historyService.getRecentHistory(limit: nil)
        let allTimestamps = allHistory.compactMap { $0.timestamp }.sorted()
        
        // Determine end date based on timeframe
        let endDate: Date
        if selectedTimeframe == .all {
            // For "All" timeframe, use the last history entry date or now if no history
            endDate = allTimestamps.last ?? now
        } else {
            endDate = now
        }
        
        // Optimize data points based on timeframe to prevent memory issues
        let (interval, component): (Int, Calendar.Component)
        switch selectedTimeframe {
        case .today:
            interval = 1
            component = .hour // Hourly data for today
        case .week:
            interval = 1
            component = .day // Daily data for week
        case .month:
            interval = 1
            component = .day // Daily data for month
        case .year:
            interval = 1
            component = .weekOfYear // Weekly data for year (52 points instead of 365)
        case .all:
            interval = 1
            component = .month // Monthly data for all time
        }
        
        // Get and sort history once
        let history = allHistory
            .filter { $0.timestamp != nil && $0.timestamp! >= cutoffDate && $0.timestamp! <= endDate }
            .sorted { $0.timestamp! < $1.timestamp! }
        
        var data: [QuantityDataPoint] = []
        var currentDate = cutoffDate
        
        // For "Today" view, ensure we have at least some data points even if no activity today
        if selectedTimeframe == .today && history.isEmpty {
            // Get the latest quantity from all history for baseline
            let latestQuantity = allHistory.last?.totalQuantityAtTime ?? 0
            
            // Create hourly data points for today
            var currentHour = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: currentHour) ?? now
            
            while currentHour < endOfDay {
                data.append(QuantityDataPoint(date: currentHour, quantity: Int(latestQuantity)))
                currentHour = calendar.date(byAdding: .hour, value: 1, to: currentHour) ?? currentHour
            }
            return Array(data.prefix(24)) // Limit to 24 hours
        }
        
        // Generate data points efficiently
        while currentDate <= endDate {
            let periodEnd = calendar.date(byAdding: component, value: interval, to: currentDate) ?? currentDate
            
            // Find the last entry before or at periodEnd
            let relevantEntries = history.filter { $0.timestamp! <= periodEnd }
            let totalQuantity = relevantEntries.last?.totalQuantityAtTime ?? 0
            
            data.append(QuantityDataPoint(date: currentDate, quantity: Int(totalQuantity)))
            currentDate = periodEnd
            
            // Safety check to prevent infinite loops
            if data.count > 1000 {
                break
            }
        }
        
        // Special handling for "All" timeframe to ensure we have enough data points
        if selectedTimeframe == .all && data.count < 2 && !allTimestamps.isEmpty {
            // If we only have one data point for "All" timeframe, create additional points to show progression
            let firstDate = allTimestamps.first!
            let lastDate = allTimestamps.last!
            
            // Create at least 3-5 data points across the time range
            let timeSpan = lastDate.timeIntervalSince(firstDate)
            let numberOfPoints = min(max(3, Int(timeSpan / (30 * 24 * 3600))), 12) // 3-12 points based on time span
            
            data.removeAll()
            for i in 0..<numberOfPoints {
                let progress = Double(i) / Double(numberOfPoints - 1)
                let date = Date(timeIntervalSince1970: firstDate.timeIntervalSince1970 + progress * timeSpan)
                
                // Find the total quantity at this date
                let entriesUpToDate = allHistory.filter { entry in
                    guard let timestamp = entry.timestamp else { return false }
                    return timestamp <= date
                }.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
                
                let totalQuantity = entriesUpToDate.last?.totalQuantityAtTime ?? 0
                data.append(QuantityDataPoint(date: date, quantity: Int(totalQuantity)))
            }
        }
        
        // Limit data points to prevent UI freezing
        if data.count > 100 {
            let step = data.count / 50 // Reduce to ~50 points
            data = stride(from: 0, to: data.count, by: step).map { data[$0] }
        }
        
        return data
    }
    
    private func getValueChartData() -> [ValueDataPoint] {
        guard statistics != nil else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = selectedTimeframe.getCutoffDate(from: now, historyService: historyService) ?? calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        // Get all history for date range calculation
        let allHistory = historyService.getRecentHistory(limit: nil)
        let allTimestamps = allHistory.compactMap { $0.timestamp }.sorted()
        
        // Determine end date based on timeframe
        let endDate: Date
        if selectedTimeframe == .all {
            // For "All" timeframe, use the last history entry date or now if no history
            endDate = allTimestamps.last ?? now
        } else {
            endDate = now
        }
        
        // Optimize data points based on timeframe to prevent memory issues
        let (interval, component): (Int, Calendar.Component)
        switch selectedTimeframe {
        case .today:
            interval = 1
            component = .hour // Hourly data for today
        case .week:
            interval = 1
            component = .day // Daily data for week
        case .month:
            interval = 1
            component = .day // Daily data for month
        case .year:
            interval = 1
            component = .weekOfYear // Weekly data for year (52 points instead of 365)
        case .all:
            interval = 1
            component = .month // Monthly data for all time
        }
        
        // Get and sort history once
        let history = allHistory
            .filter { $0.timestamp != nil && $0.timestamp! >= cutoffDate && $0.timestamp! <= endDate }
            .sorted { $0.timestamp! < $1.timestamp! }
        
        var data: [ValueDataPoint] = []
        var currentDate = cutoffDate
        
        // For "Today" view, ensure we have at least some data points even if no activity today
        if selectedTimeframe == .today && history.isEmpty {
            // Get the latest value from all history for baseline
            let latestValue = allHistory.last?.totalValueAtTime?.doubleValue ?? 0.0
            
            // Create hourly data points for today
            var currentHour = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: currentHour) ?? now
            
            while currentHour < endOfDay {
                data.append(ValueDataPoint(date: currentHour, value: max(0, latestValue)))
                currentHour = calendar.date(byAdding: .hour, value: 1, to: currentHour) ?? currentHour
            }
            return Array(data.prefix(24)) // Limit to 24 hours
        }
        
        // Generate data points efficiently
        while currentDate <= endDate {
            let periodEnd = calendar.date(byAdding: component, value: interval, to: currentDate) ?? currentDate
            
            // Find the last entry before or at periodEnd
            let relevantEntries = history.filter { $0.timestamp! <= periodEnd }
            let totalValue = relevantEntries.last?.totalValueAtTime?.doubleValue ?? 0.0
            
            data.append(ValueDataPoint(date: currentDate, value: max(0, totalValue)))
            currentDate = periodEnd
            
            // Safety check to prevent infinite loops
            if data.count > 1000 {
                break
            }
        }
        
        // Special handling for "All" timeframe to ensure we have enough data points
        if selectedTimeframe == .all && data.count < 2 && !allTimestamps.isEmpty {
            // If we only have one data point for "All" timeframe, create additional points to show progression
            let firstDate = allTimestamps.first!
            let lastDate = allTimestamps.last!
            
            // Create at least 3-5 data points across the time range
            let timeSpan = lastDate.timeIntervalSince(firstDate)
            let numberOfPoints = min(max(3, Int(timeSpan / (30 * 24 * 3600))), 12) // 3-12 points based on time span
            
            data.removeAll()
            for i in 0..<numberOfPoints {
                let progress = Double(i) / Double(numberOfPoints - 1)
                let date = Date(timeIntervalSince1970: firstDate.timeIntervalSince1970 + progress * timeSpan)
                
                // Find the total value at this date
                let entriesUpToDate = allHistory.filter { entry in
                    guard let timestamp = entry.timestamp else { return false }
                    return timestamp <= date
                }.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
                
                let totalValue = entriesUpToDate.last?.totalValueAtTime?.doubleValue ?? 0.0
                data.append(ValueDataPoint(date: date, value: max(0, totalValue)))
            }
        }
        
        // Limit data points to prevent UI freezing
        if data.count > 100 {
            let step = data.count / 50 // Reduce to ~50 points
            data = stride(from: 0, to: data.count, by: step).map { data[$0] }
        }
        
        return data
    }
    
    private func getConsumptionChartData() -> [ConsumptionDataPoint] {
        guard statistics != nil else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = selectedTimeframe.getCutoffDate(from: now, historyService: historyService) ?? calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        // Get all history for date range calculation
        let allHistory = historyService.getRecentHistory(limit: nil)
        let allTimestamps = allHistory.compactMap { $0.timestamp }.sorted()
        
        // Determine end date based on timeframe
        let endDate: Date
        if selectedTimeframe == .all {
            // For "All" timeframe, use the last history entry date or now if no history
            endDate = allTimestamps.last ?? now
        } else {
            endDate = now
        }
        
        // Optimize data points based on timeframe
        let (interval, component): (Int, Calendar.Component)
        let dateFormat: String
        switch selectedTimeframe {
        case .today:
            interval = 1
            component = .hour
            dateFormat = "yyyy-MM-dd-HH"
        case .week:
            interval = 1
            component = .day
            dateFormat = "yyyy-MM-dd"
        case .month:
            interval = 1
            component = .day
            dateFormat = "yyyy-MM-dd"
        case .year:
            interval = 1
            component = .weekOfYear
            dateFormat = "yyyy-ww"
        case .all:
            interval = 1
            component = .month
            dateFormat = "yyyy-MM"
        }
        
        // Get consumed entries and filter efficiently
        let history = allHistory
            .filter { entry in
                guard let timestamp = entry.timestamp else { return false }
                return timestamp >= cutoffDate && timestamp <= endDate && entry.actionType == .consumed
            }
        
        // For "Today" view, ensure we have at least some data points even if no consumption today
        if selectedTimeframe == .today && history.isEmpty {
            // Create hourly data points for today with zero consumption
            var data: [ConsumptionDataPoint] = []
            var currentHour = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: currentHour) ?? now
            
            while currentHour < endOfDay {
                data.append(ConsumptionDataPoint(date: currentHour, consumed: 0))
                currentHour = calendar.date(byAdding: .hour, value: 1, to: currentHour) ?? currentHour
            }
            return Array(data.prefix(24)) // Limit to 24 hours
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        var consumptionByPeriod: [String: Int] = [:]
        
        // Group consumption by the appropriate time period
        for entry in history {
            guard let timestamp = entry.timestamp else { continue }
            let periodStart: Date
            switch component {
            case .hour:
                periodStart = calendar.dateInterval(of: .hour, for: timestamp)?.start ?? timestamp
            case .day:
                periodStart = calendar.startOfDay(for: timestamp)
            case .weekOfYear:
                periodStart = calendar.dateInterval(of: .weekOfYear, for: timestamp)?.start ?? timestamp
            case .month:
                periodStart = calendar.dateInterval(of: .month, for: timestamp)?.start ?? timestamp
            default:
                periodStart = calendar.startOfDay(for: timestamp)
            }
            
            let periodKey = dateFormatter.string(from: periodStart)
            consumptionByPeriod[periodKey, default: 0] += abs(Int(entry.quantityChange))
        }
        
        var data: [ConsumptionDataPoint] = []
        var currentDate = cutoffDate
        
        // Generate data points
        while currentDate <= endDate {
            let periodKey = dateFormatter.string(from: currentDate)
            let consumed = consumptionByPeriod[periodKey] ?? 0
            data.append(ConsumptionDataPoint(date: currentDate, consumed: consumed))
            
            currentDate = calendar.date(byAdding: component, value: interval, to: currentDate) ?? currentDate
            
            // Safety check to prevent infinite loops
            if data.count > 1000 {
                break
            }
        }
        
        // Special handling for "All" timeframe to ensure we have enough data points
        if selectedTimeframe == .all && data.count < 2 && !allTimestamps.isEmpty {
            // If we only have one data point for "All" timeframe, create additional points to show progression
            let firstDate = allTimestamps.first!
            let lastDate = allTimestamps.last!
            
            // Create at least 3-5 data points across the time range
            let timeSpan = lastDate.timeIntervalSince(firstDate)
            let numberOfPoints = min(max(3, Int(timeSpan / (30 * 24 * 3600))), 12) // 3-12 points based on time span
            
            data.removeAll()
            for i in 0..<numberOfPoints {
                let progress = Double(i) / Double(numberOfPoints - 1)
                let date = Date(timeIntervalSince1970: firstDate.timeIntervalSince1970 + progress * timeSpan)
                
                // Count consumption events up to this date
                let consumptionUpToDate = allHistory.filter { entry in
                    guard let timestamp = entry.timestamp else { return false }
                    return timestamp <= date && entry.actionType == .consumed
                }.reduce(0) { result, entry in result + abs(Int(entry.quantityChange)) }
                
                data.append(ConsumptionDataPoint(date: date, consumed: consumptionUpToDate))
            }
        }
        
        // Limit data points for performance
        if data.count > 100 {
            let step = data.count / 50
            data = stride(from: 0, to: data.count, by: step).map { data[$0] }
        }
        
        return data.sorted { $0.date < $1.date }
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct StatisticsFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct QuantityDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let quantity: Int
}

struct ValueDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ConsumptionDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let consumed: Int
}

struct ActivityDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let activity: Int
}

enum StatisticsTimeframe: CaseIterable {
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
    
    func getCutoffDate(from date: Date = Date(), historyService: WineHistoryService? = nil) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .today:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: date)
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: date)
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: date)
        case .all:
            // Return the date of the first record in history
            guard let historyService = historyService else { return nil }
            let allHistory = historyService.getRecentHistory(limit: nil)
            let sortedHistory = allHistory.compactMap { $0.timestamp }.sorted()
            return sortedHistory.first
        }
    }
}
