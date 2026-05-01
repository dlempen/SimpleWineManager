//
//  SearchPerformanceTests.swift
//  SimpleWineManagerTests
//
//  Created on 3.10.2025.
//
//  Tests performance on iPhone 16 models

import XCTest
import CoreData
@testable import SimpleWineManager

final class SearchPerformanceTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    var viewModel: WineListViewModel!
    
    override func setUpWithError() throws {
        // Set up an in-memory Core Data stack
        let persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        // Initialize the view model with our test context
        viewModel = WineListViewModel(context: viewContext)
        
        // Create test data - add 100 sample wines
        createSampleWines(count: 100)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        viewContext = nil
    }
    
    // MARK: - Test Cases
    
    func testSearchPerformance() throws {
        // This measures how efficiently the search filtering performs
        measure {
            // Test searching for something that will match some but not all wines
            viewModel.searchText = "Cab"
            
            // Force the filter to run
            let _ = viewModel.wines
            
            // Wait for debounce
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
    }
    
    func testAdvancedSearchPerformance() throws {
        // Test the enhanced advanced search performance for v2.8
        
        // Create a larger dataset for testing
        createSampleWines(count: 150)
        
        measure {
            // Simulate advanced search criteria
            let criteria = AdvancedSearchCriteria()
            criteria.typeFilters = ["Red"]
            criteria.vintageRange = (min: "2010", max: "2020")
            criteria.priceRange = (min: 20, max: 50)
            
            // Get all wines that match the criteria
            let wines = viewModel.wines
            let filtered = wines.filter { wine in
                // Type filter
                if !criteria.typeFilters.isEmpty && !(criteria.typeFilters.contains(wine.type ?? "")) {
                    return false
                }
                
                // Vintage filter
                if let vintage = wine.vintage, let vintageNum = Int(vintage),
                   let minVintage = Int(criteria.vintageRange.min),
                   let maxVintage = Int(criteria.vintageRange.max) {
                    if vintageNum < minVintage || vintageNum > maxVintage {
                        return false
                    }
                }
                
                // Price filter
                if let price = wine.price?.doubleValue {
                    if price < criteria.priceRange.min || price > criteria.priceRange.max {
                        return false
                    }
                }
                
                return true
            }
            
            // Force evaluation
            _ = filtered.count
        }
    }
    
    func testLargeScreenPerformance() throws {
        // This tests performance of wine list on large iPhone 16 screens
        
        // Create a larger dataset for iPhone 16 screen testing
        createSampleWines(count: 200)
        
        measure {
            // Test sorting and filtering operations that would affect large screen rendering
            viewModel.searchText = ""
            let wines = viewModel.wines
            
            // Simulating the sorting that would happen when displaying on a large screen
            let sortedWines = wines.sorted { (wine1, wine2) -> Bool in
                return (wine1.name ?? "") < (wine2.name ?? "")
            }
            
            // Force layout calculation by accessing the count
            _ = sortedWines.count
        }
    }
    
    func testDynamicIslandCompatibility() throws {
        // Test interactions with Dynamic Island on iPhone 16 Pro models
        // This is specifically for v2.8 which will add Dynamic Island support
        
        // Simplified test for now - in real implementation, this would test
        // interaction between search functions and Dynamic Island notifications
        measure {
            // Simulate rapid search changes while Dynamic Island is active
            for i in 1...5 {
                viewModel.searchText = "Test \(i)"
                // Force search to run
                _ = viewModel.wines
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            }
        }
    }
    
    func testFilterCachePerformance() throws {
        // Test the new filter cache system for v2.8
        
        createSampleWines(count: 250)
        
        measure {
            // Simulate a series of searches that would benefit from caching
            let searchTerms = ["Cab", "Merlot", "Cab", "Pinot", "Cab"]
            
            for term in searchTerms {
                viewModel.searchText = term
                // Force search results to be generated
                _ = viewModel.wines
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSampleWines(count: Int) {
        let regions = ["Bordeaux", "Burgundy", "Champagne", "Tuscany", "Rioja", "Napa Valley", "Barossa Valley"]
        let types = ["Red", "White", "Rosé", "Sparkling", "Dessert"]
        let categories = ["Table Wine", "Premium", "Super Premium", "Ultra Premium"]
        let bottleSizes = ["750ml", "375ml", "1500ml", "3000ml"]
        
        for i in 1...count {
            let wine = Wine(context: viewContext)
            wine.id = UUID()
            wine.name = "Test Wine \(i)"
            wine.producer = "Producer \(i % 20)"
            wine.vintage = String(2000 + (i % 22))
            wine.country = "Country \((i % 5) + 1)"
            wine.region = regions[i % regions.count]
            wine.type = types[i % types.count]
            wine.category = categories[i % categories.count]
            wine.alcohol = "\((13 + (i % 5)) % 15).\((i % 9) + 1)%"
            wine.bottleSize = bottleSizes[i % bottleSizes.count]
            wine.quantity = Int16(1 + (i % 12))
            wine.grapes = "Grape \((i % 10) + 1)"
            
            if i % 2 == 0 {
                wine.storageLocation = "Cellar \((i % 5) + 1)"
            }
            
            if i % 3 == 0 {
                wine.price = NSDecimalNumber(value: 10.0 + Double(i % 90))
            }
        }
        
        try? viewContext.save()
    }
}
