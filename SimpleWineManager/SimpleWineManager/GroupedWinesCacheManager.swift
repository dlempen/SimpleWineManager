import Foundation

/// A cache manager for grouped wine results to avoid expensive re-computations
class GroupedWinesCacheManager: ObservableObject {
    static let shared = GroupedWinesCacheManager()
    
    private struct CacheKey: Hashable {
        let sortOrderId: String
        let wineIds: Set<UUID>
        let filterHash: Int
        
        init(sortOrder: SortOrder?, wines: [Wine], filterCriteria: AdvancedSearchCriteria, searchText: String) {
            self.sortOrderId = sortOrder?.id.uuidString ?? "default"
            self.wineIds = Set(wines.compactMap { $0.id })
            
            // Create a hash for the filter criteria
            var hasher = Hasher()
            hasher.combine(filterCriteria.name)
            hasher.combine(filterCriteria.producer)
            hasher.combine(filterCriteria.grapes)
            hasher.combine(filterCriteria.category)
            hasher.combine(filterCriteria.country)
            hasher.combine(filterCriteria.region)
            hasher.combine(filterCriteria.subregion)
            hasher.combine(filterCriteria.type)
            hasher.combine(filterCriteria.storageLocation)
            hasher.combine(filterCriteria.vintageFrom)
            hasher.combine(filterCriteria.vintageTo)
            hasher.combine(filterCriteria.alcoholFrom)
            hasher.combine(filterCriteria.alcoholTo)
            hasher.combine(filterCriteria.priceFrom)
            hasher.combine(filterCriteria.priceTo)
            hasher.combine(filterCriteria.quantityFrom)
            hasher.combine(filterCriteria.quantityTo)
            hasher.combine(filterCriteria.readyToTrinkFrom)
            hasher.combine(filterCriteria.readyToTrinkTo)
            hasher.combine(filterCriteria.bestBeforeFrom)
            hasher.combine(filterCriteria.bestBeforeTo)
            hasher.combine(filterCriteria.bottleSizeFrom)
            hasher.combine(filterCriteria.bottleSizeTo)
            hasher.combine(searchText)
            
            self.filterHash = hasher.finalize()
        }
    }
    
    private var cache: [CacheKey: [(level: Int, title: String, wine: Wine?)]] = [:]
    private let maxCacheSize = 10 // Keep last 10 grouping results
    private var accessOrder: [CacheKey] = []
    
    private init() {}
    
    /// Get grouped wines from cache or compute if not cached
    func getGroupedWines(
        sortOrder: SortOrder?,
        wines: [Wine],
        filterCriteria: AdvancedSearchCriteria,
        searchText: String,
        getFieldValue: (SortField, Wine) -> String
    ) -> [(level: Int, title: String, wine: Wine?)] {
        
        let cacheKey = CacheKey(
            sortOrder: sortOrder,
            wines: wines,
            filterCriteria: filterCriteria,
            searchText: searchText
        )
        
        // Check if we have a cached result
        if let cachedResult = cache[cacheKey] {
            // Move to end of access order (most recently used)
            updateAccessOrder(for: cacheKey)
            return cachedResult
        }
        
        // Compute grouped wines
        let groupedResult = computeGroupedWines(
            sortOrder: sortOrder,
            wines: wines,
            getFieldValue: getFieldValue
        )
        
        // Cache the result
        cacheResult(groupedResult, for: cacheKey)
        
        return groupedResult
    }
    
    private func computeGroupedWines(
        sortOrder: SortOrder?,
        wines: [Wine],
        getFieldValue: (SortField, Wine) -> String
    ) -> [(level: Int, title: String, wine: Wine?)] {
        
        guard let sortOrder = sortOrder,
              !sortOrder.subtitleFields.isEmpty else {
            return wines.map { (0, "", $0) }
        }
        
        // First, sort all wines according to the sort order
        let sortedWines = wines.sorted { wine1, wine2 in
            for field in sortOrder.fields {
                let value1 = getFieldValue(field, wine1)
                let value2 = getFieldValue(field, wine2)
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
            // Check if we need to add any new titles/subtitles
            for (index, field) in orderedSubtitleFields.enumerated() {
                let currentValue = getFieldValue(field, wine)
                
                // If this value is different from the previous, we need new titles from this level down
                if currentValue != previousValues[index] {
                    // Add titles for this level and all subsequent levels that change
                    for levelIndex in index..<orderedSubtitleFields.count {
                        let levelField = orderedSubtitleFields[levelIndex]
                        let levelValue = getFieldValue(levelField, wine)
                        result.append((levelIndex, levelValue, nil))
                        previousValues[levelIndex] = levelValue
                    }
                    break
                }
            }
            
            // Add the wine itself
            result.append((orderedSubtitleFields.count, "", wine))
        }
        
        return result
    }
    
    private func cacheResult(_ result: [(level: Int, title: String, wine: Wine?)], for key: CacheKey) {
        cache[key] = result
        updateAccessOrder(for: key)
        
        // Evict oldest entries if cache is too large
        while cache.count > maxCacheSize && !accessOrder.isEmpty {
            let oldestKey = accessOrder.removeFirst()
            cache.removeValue(forKey: oldestKey)
        }
    }
    
    private func updateAccessOrder(for key: CacheKey) {
        // Remove from current position
        accessOrder.removeAll { $0 == key }
        // Add to end (most recently used)
        accessOrder.append(key)
    }
    
    /// Clear the cache (useful when wine data changes significantly)
    func clearCache() {
        cache.removeAll()
        accessOrder.removeAll()
    }
    
    /// Get cache statistics for debugging
    func getCacheStatistics() -> (cacheSize: Int, maxSize: Int, hitRate: Double) {
        return (
            cacheSize: cache.count,
            maxSize: maxCacheSize,
            hitRate: 0.0 // TODO: Implement hit rate tracking if needed
        )
    }
}

/// Performance monitoring for grouped wines computation
class GroupingPerformanceMonitor {
    private static var computationTimes: [TimeInterval] = []
    private static let maxStoredTimes = 100
    
    static func measureComputationTime<T>(operation: () -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Store computation time
        computationTimes.append(timeElapsed)
        if computationTimes.count > maxStoredTimes {
            computationTimes.removeFirst()
        }
        
        // Log if computation takes too long
        if timeElapsed > 0.1 { // 100ms threshold
            print("⚠️ Slow grouping computation: \(String(format: "%.3f", timeElapsed))s")
        }
        
        return result
    }
    
    static func getAverageComputationTime() -> TimeInterval {
        guard !computationTimes.isEmpty else { return 0 }
        return computationTimes.reduce(0, +) / Double(computationTimes.count)
    }
    
    static func getMaxComputationTime() -> TimeInterval {
        return computationTimes.max() ?? 0
    }
    
    static func resetStatistics() {
        computationTimes.removeAll()
    }
}
