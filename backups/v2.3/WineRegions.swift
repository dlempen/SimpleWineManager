import Foundation

class WineRegions: ObservableObject {
    struct RegionHierarchy: Codable {
        var wineRegions: [String: [String: [String: [String: [String]]]]]
    }
    
    @Published var countries: [String] = []
    @Published var regions: [String] = []
    @Published var subregions: [String] = []
    @Published var types: [String] = []
    
    private var hierarchy: RegionHierarchy?
    
    init() {
        loadRegionData()
    }
    
    private func loadRegionData() {
        do {
            guard let url = Bundle.main.url(forResource: "WineRegions", withExtension: "json") else {
                print("WineRegions.json file not found in bundle")
                return
            }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.hierarchy = try decoder.decode(RegionHierarchy.self, from: data)
            
            if let wineRegions = self.hierarchy?.wineRegions {
                self.countries = Array(wineRegions.keys).sorted()
                // Load all available regions, subregions, and types
                updateAllOptions()
            }
        } catch let error {
            print("Error loading wine regions: \(error.localizedDescription)")
            self.hierarchy = nil
            self.countries = []
        }
    }
    
    private func updateAllOptions() {
        guard let wineRegions = hierarchy?.wineRegions else { return }
        
        // Collect all unique regions
        var allRegions = Set<String>()
        var allSubregions = Set<String>()
        var allTypes = Set<String>()
        
        for (_, regions) in wineRegions {
            for (region, subregions) in regions {
                allRegions.insert(region)
                for (subregion, typeDict) in subregions {
                    allSubregions.insert(subregion)
                    if let types = typeDict["types"] {
                        types.forEach { allTypes.insert($0) }
                    }
                }
            }
        }
        
        regions = Array(allRegions).sorted()
        subregions = Array(allSubregions).sorted()
        types = Array(allTypes).sorted()
    }
    
    func updateRegions(for country: String) {
        if let countryRegions = hierarchy?.wineRegions[country] {
            regions = Array(countryRegions.keys).sorted()
        }
    }
    
    func updateSubregions(for country: String, region: String) {
        if let regionSubregions = hierarchy?.wineRegions[country]?[region] {
            subregions = Array(regionSubregions.keys).sorted()
        }
    }
    
    func updateTypes(for country: String, region: String, subregion: String) {
        types = hierarchy?.wineRegions[country]?[region]?[subregion]?["types"] ?? []
    }
    
    func findMatches(in text: String) -> (country: String?, region: String?, subregion: String?, type: String?) {
        let lowercasedText = text.lowercased()
        
        guard let wineRegions = hierarchy?.wineRegions else {
            return (nil, nil, nil, nil)
        }
        
        // First try to find a type match as it's most specific
        for (country, regions) in wineRegions {
            for (region, subregions) in regions {
                for (subregion, typeDict) in subregions {
                    if let types = typeDict["types"] {
                        for type in types {
                            if lowercasedText.contains(type.lowercased()) {
                                return (country, region, subregion, type)
                            }
                        }
                    }
                }
            }
        }
        
        // Then try to find a subregion match
        for (country, regions) in wineRegions {
            for (region, subregions) in regions {
                for (subregion, _) in subregions {
                    if lowercasedText.contains(subregion.lowercased()) {
                        return (country, region, subregion, nil)
                    }
                }
            }
        }
        
        // Then try to find a region match
        for (country, regions) in wineRegions {
            for (region, _) in regions {
                if lowercasedText.contains(region.lowercased()) {
                    return (country, region, nil, nil)
                }
            }
        }
        
        // Finally try to find a country match
        for (country, _) in wineRegions {
            if lowercasedText.contains(country.lowercased()) {
                return (country, nil, nil, nil)
            }
        }
        
        return (nil, nil, nil, nil)
    }
    
    func findMatchByRegion(_ searchRegion: String) -> (country: String, region: String)? {
        guard let wineRegions = hierarchy?.wineRegions else {
            return nil
        }
        
        for (country, regions) in wineRegions {
            if regions.keys.contains(searchRegion) {
                return (country, searchRegion)
            }
        }
        return nil
    }
    
    func findMatchBySubregion(_ searchSubregion: String) -> (country: String, region: String, subregion: String)? {
        guard let wineRegions = hierarchy?.wineRegions else {
            return nil
        }
        
        for (country, regions) in wineRegions {
            for (region, subregions) in regions {
                if subregions.keys.contains(searchSubregion) {
                    return (country, region, searchSubregion)
                }
            }
        }
        return nil
    }
    
    func findMatchByType(_ searchType: String) -> (country: String, region: String, subregion: String, type: String)? {
        guard let wineRegions = hierarchy?.wineRegions else {
            return nil
        }
        
        for (country, regions) in wineRegions {
            for (region, subregions) in regions {
                for (subregion, typeDict) in subregions {
                    if let types = typeDict["types"], types.contains(searchType) {
                        return (country, region, subregion, searchType)
                    }
                }
            }
        }
        return nil
    }
}
