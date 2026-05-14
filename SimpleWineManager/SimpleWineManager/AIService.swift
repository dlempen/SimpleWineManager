import Foundation

// MARK: - AI Provider

enum AIProvider: String, CaseIterable, Codable {
    case openAI = "OpenAI"

    /// Hint text displayed below the API key field in Settings.
    var apiKeyHint: String {
        return "Get your free API key at platform.openai.com → API keys"
    }

    /// SF Symbol name used as an icon.
    var systemImageName: String {
        return "brain"
    }
}

// MARK: - AI Search Source (web citation)

struct AISearchSource: Identifiable {
    let id = UUID()
    let title: String
    let url: String
}

/// A single price data point found by the AI from one source.
struct AIPriceDataPoint: Identifiable {
    let id = UUID()
    let source: String        // retailer / site name
    let url: String
    let price: String         // price converted to target currency, e.g. "EUR 24.50"
    let originalPrice: String? // price as found on the website if it was in a different currency, e.g. "GBP 21.00"
}

/// A single drinking-window data point found by the AI from one source.
struct AIDrinkingWindowDataPoint: Identifiable {
    let id = UUID()
    let source: String   // critic / site name
    let url: String
    let readyYear: String
    let bestBeforeYear: String
}

// MARK: - AI Wine Suggestion

struct AIWineSuggestion {
    var producer: String?
    var vintage: String?
    var alcohol: String?
    var grapes: String?
    var country: String?
    var region: String?
    var subregion: String?
    var type: String?
    var category: String?
    var readyToTrinkYear: String?
    var bestBeforeYear: String?
    var remarks: String?
    /// Average retail price in the user's chosen currency (numeric string, no symbol)
    var price: String?
    /// Web search citations returned by the API
    var sources: [AISearchSource] = []
    /// Individual price data points that were averaged to produce `price`
    var priceDetails: [AIPriceDataPoint] = []
    /// Individual drinking-window data points that were averaged to produce readyToTrinkYear/bestBeforeYear
    var drinkingWindowDetails: [AIDrinkingWindowDataPoint] = []
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case notConfigured
    case noUsefulFields
    case networkError(String)
    case invalidResponse
    case apiError(String)
    case providerNotYetSupported(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI is not configured. Please add your API key in Settings."
        case .noUsefulFields:
            return "Please fill in at least the wine name or producer before using AI enrichment."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .invalidResponse:
            return "The AI returned an unexpected response. Please try again."
        case .apiError(let msg):
            return "API error: \(msg)"
        case .providerNotYetSupported(let name):
            return "\(name) support is coming soon. Please use OpenAI for now."
        }
    }
}

// MARK: - AI Service

class AIService {

    // MARK: Shared instance
    static let shared = AIService()

    // MARK: - Public API

    /// Build a wine suggestion from whatever fields the user has already filled in.
    /// Only empty/missing fields will be populated in the returned suggestion.
    func enrichWine(
        name: String,
        producer: String,
        vintage: String,
        alcohol: String,
        grapes: String,
        country: String,
        region: String,
        subregion: String,
        type: String,
        category: String,
        readyToTrinkYear: String,
        bestBeforeYear: String,
        remarks: String,
        currency: String,
        apiKey: String,
        provider: AIProvider,
        searchCountries: [String] = []
    ) async throws -> AIWineSuggestion {

        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.notConfigured
        }

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty ||
              !producer.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.noUsefulFields
        }

        // Extract ISO currency code (e.g. "CHF" from "CHF (Fr.)")
        let targetCurrencyCode: String
        if let spaceIdx = currency.firstIndex(of: " ") {
            targetCurrencyCode = String(currency[currency.startIndex..<spaceIdx])
        } else {
            targetCurrencyCode = currency
        }

        switch provider {
        case .openAI:
            let prompt = buildPrompt(
                name: name, producer: producer, vintage: vintage,
                alcohol: alcohol, grapes: grapes, country: country,
                region: region, subregion: subregion, type: type,
                category: category, readyToTrinkYear: readyToTrinkYear,
                bestBeforeYear: bestBeforeYear, remarks: remarks,
                currency: currency, searchCountries: searchCountries
            )
            let (responseText, sources) = try await callOpenAIChatAPI(
                prompt: prompt, apiKey: apiKey, searchCountries: searchCountries
            )
            var suggestion = parseSuggestion(from: responseText, sources: sources)
            // Convert prices to the user's chosen currency using live exchange rates
            await applyPriceConversion(to: &suggestion, targetCurrencyCode: targetCurrencyCode)
            return suggestion
        }
    }

    // MARK: - Private helpers

    private func buildPrompt(
        name: String, producer: String, vintage: String,
        alcohol: String, grapes: String, country: String,
        region: String, subregion: String, type: String,
        category: String, readyToTrinkYear: String,
        bestBeforeYear: String, remarks: String,
        currency: String,
        searchCountries: [String]
    ) -> String {

        var knownLines: [String] = []
        if !name.isEmpty      { knownLines.append("Name: \(name)") }
        if !producer.isEmpty  { knownLines.append("Producer: \(producer)") }
        if !vintage.isEmpty   { knownLines.append("Vintage: \(vintage)") }
        if !alcohol.isEmpty   { knownLines.append("Alcohol: \(alcohol)%") }
        if !grapes.isEmpty    { knownLines.append("Grapes: \(grapes)") }
        if !country.isEmpty   { knownLines.append("Country: \(country)") }
        if !region.isEmpty    { knownLines.append("Region: \(region)") }
        if !subregion.isEmpty { knownLines.append("Subregion: \(subregion)") }
        if !type.isEmpty      { knownLines.append("Type: \(type)") }
        if !category.isEmpty  { knownLines.append("Category: \(category)") }
        if !readyToTrinkYear.isEmpty { knownLines.append("Ready to drink from year: \(readyToTrinkYear)") }
        if !bestBeforeYear.isEmpty   { knownLines.append("Best before year: \(bestBeforeYear)") }
        if !remarks.isEmpty   { knownLines.append("Remarks: \(remarks)") }

        let knownSection = knownLines.joined(separator: "\n")

        // Build the geo-restriction instruction for the prompt
        let geoInstruction: String
        if searchCountries.isEmpty {
            geoInstruction = "You may search globally for wine information and pricing."
        } else {
            let countryList = searchCountries.joined(separator: ", ")
            geoInstruction = "When searching the web, ONLY use sources from the following countries: \(countryList). Prefer wine retailers, wine shops, and wine databases from these countries. The price should reflect what this wine costs in those markets."
        }

        return """
You are a wine expert assistant. Based on the information provided about a wine, fill in as many of the MISSING fields as possible.

You have access to real-time web search.
\(geoInstruction)

**IMPORTANT — Multi-source research:**
- For PRICE: Search at least 3 different wine retailers or shops. Record every individual price you find EXACTLY as shown on the website (keep the original currency, e.g. "EUR 18.90" or "USD 22.00"). Do NOT convert currencies yourself — report prices verbatim. The app will handle currency conversion automatically.
- For DRINKING WINDOW: Search at least 3 different wine critics, wine databases, or producer pages. Record every recommended window you find. Calculate the consensus and return "readyToTrinkYear" and "bestBeforeYear" as the average. Also return every individual window you found in "drinkingWindowDetails".
- For SOURCES: List ALL websites you consulted for any field — not just price. Every search result used must appear in "sources".

Known information:
\(knownSection)

Respond ONLY with a JSON object. Do not include any explanation, markdown, or code fences — just the raw JSON.

For fields you already know from the input, omit them from the response (do not repeat them).
For fields you cannot determine with reasonable confidence, omit them.

The JSON must use exactly these keys (only include keys you can fill):
{
  "producer": "...",
  "vintage": "...",
  "alcohol": "...",
  "grapes": "Grape1, Grape2",
  "country": "...",
  "region": "...",
  "subregion": "...",
  "type": "...",
  "category": "Red | White | Rosé | Sparkling | Dessert | Port",
  "readyToTrinkYear": "YYYY",
  "bestBeforeYear": "YYYY",
  "price": "...",
  "remarks": "Brief tasting notes or interesting facts about this wine.",
  "priceDetails": [
    { "source": "Retailer name", "url": "https://...", "price": "EUR 24.50" }
  ],
  "drinkingWindowDetails": [
    { "source": "Critic or site name", "url": "https://...", "readyYear": "YYYY", "bestBeforeYear": "YYYY" }
  ],
  "sources": [
    { "title": "Page title", "url": "https://..." }
  ]
}

Rules:
- "vintage" must be a 4-digit year string (e.g. "2019") or omit.
- "alcohol" must be a number only, no % sign (e.g. "13.5") or omit.
- "readyToTrinkYear" and "bestBeforeYear" must be 4-digit year strings or omit.
- "category" must be one of: Red, White, Rosé, Sparkling, Dessert, Port.
- "price" must be the AVERAGE of the prices found across all sources, as a plain number (no currency symbol, no spaces). Example: "24.50". Use the currency actually shown on the websites (do not convert). Omit if no prices found.
- "priceDetails" must list EVERY individual price found. For each entry, "price" must be the value exactly as shown on the website, formatted as "CCC XX.XX" (e.g. "EUR 18.90", "USD 22.00"). The app will convert to the user's currency automatically. Omit the entire "priceDetails" key if no prices found.
- "drinkingWindowDetails" must list EVERY individual drinking window found. Include source name, URL, readyYear and bestBeforeYear as 4-digit strings. Omit if no windows found.
- "sources" must list ALL web pages consulted for any field. Omit only if no web search was performed.
- Only include fields that are MISSING from the known information above.
"""
    }

    /// Builds the web_search_preview tool dict, optionally including a user_location
    /// derived from the first selected search country's ISO-3166-1 alpha-2 code.
    private func buildWebSearchTool(searchCountries: [String]) -> [String: Any] {
        var tool: [String: Any] = [
            "type": "web_search_preview",
            "search_context_size": "medium"
        ]
        // Map country name → ISO code using the same list as SettingsStore
        if let firstCountry = searchCountries.first,
           let match = SettingsStore.aiSearchableCountries.first(where: { $0.name == firstCountry }) {
            tool["user_location"] = [
                "type": "approximate",
                "country": match.code
            ]
        }
        return tool
    }

    private func callOpenAIChatAPI(
        prompt: String,
        apiKey: String,
        searchCountries: [String]
    ) async throws -> (content: String, sources: [AISearchSource]) {

        // ── Endpoint ────────────────────────────────────────────────────────
        // We use the Responses API (POST /v1/responses) because it is the only
        // OpenAI endpoint that accepts web search as an entry in the `tools` array.
        //
        // The Chat Completions API (/v1/chat/completions) uses a top-level
        // `web_search_options` field — NOT a tools[] entry — and only works with
        // the dedicated "search-preview" model family.
        //
        // ── Model ───────────────────────────────────────────────────────────
        // gpt-4.1 is the latest generally-available model in the GPT-4 series
        // (released April 2025) and supports the web_search_preview tool.
        // NOTE: The user requested "gpt-5.5" which does not exist.
        //       Update the model name here when a newer model becomes available.
        //
        // ── Tool ────────────────────────────────────────────────────────────
        // Source: openai/openai-node — responses.ts WebSearchPreviewTool
        //   { type: "web_search_preview", search_context_size: "low"|"medium"|"high" }
        //
        // ── Response structure ───────────────────────────────────────────────
        // {
        //   "output": [
        //     { "type": "web_search_call", ... },          // tool call item
        //     { "type": "message",                          // assistant message
        //       "content": [
        //         { "type": "output_text",
        //           "text": "...",
        //           "annotations": [
        //             { "type": "url_citation",
        //               "url": "https://...",
        //               "title": "Page title",
        //               "start_index": 0, "end_index": 42 }
        //           ]
        //         }
        //       ]
        //     }
        //   ]
        // }

        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw AIServiceError.networkError("Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": "gpt-4.1",
            "input": [
                ["role": "system", "content": "You are a helpful wine expert. You respond only with valid JSON."],
                ["role": "user",   "content": prompt]
            ],
            // web_search_preview adds live web search to the tools array.
            // search_context_size controls how much context window is reserved for results.
            // user_location biases search results geographically (uses the first selected country's ISO code).
            "tools": [
                buildWebSearchTool(searchCountries: searchCountries)
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse Responses API output array
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [[String: Any]] else {
            throw AIServiceError.invalidResponse
        }

        var content = ""
        var sources: [AISearchSource] = []

        for item in output {
            // We only care about "message" type items (skip "web_search_call" items)
            guard (item["type"] as? String) == "message",
                  let contentItems = item["content"] as? [[String: Any]] else { continue }

            for contentItem in contentItems {
                guard (contentItem["type"] as? String) == "output_text" else { continue }

                if let text = contentItem["text"] as? String {
                    content += text
                }

                // Extract URL citations from annotations
                if let annotations = contentItem["annotations"] as? [[String: Any]] {
                    for annotation in annotations {
                        guard (annotation["type"] as? String) == "url_citation",
                              let urlStr = annotation["url"] as? String else { continue }
                        let title = annotation["title"] as? String ?? urlStr
                        // Deduplicate by URL
                        if !sources.contains(where: { $0.url == urlStr }) {
                            sources.append(AISearchSource(title: title, url: urlStr))
                        }
                    }
                }
            }
        }

        guard !content.isEmpty else {
            throw AIServiceError.invalidResponse
        }

        return (content, sources)
    }

    private func parseSuggestion(from text: String, sources annotationSources: [AISearchSource]) -> AIWineSuggestion {
        var suggestion = AIWineSuggestion()

        // Strip markdown code fences if present
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return suggestion
        }

        // String fields
        suggestion.producer         = json["producer"]         as? String
        suggestion.vintage          = json["vintage"]          as? String
        suggestion.alcohol          = json["alcohol"]          as? String
        suggestion.grapes           = json["grapes"]           as? String
        suggestion.country          = json["country"]          as? String
        suggestion.region           = json["region"]           as? String
        suggestion.subregion        = json["subregion"]        as? String
        suggestion.type             = json["type"]             as? String
        suggestion.category         = json["category"]         as? String
        suggestion.readyToTrinkYear = json["readyToTrinkYear"] as? String
        suggestion.bestBeforeYear   = json["bestBeforeYear"]   as? String
        suggestion.remarks          = json["remarks"]          as? String
        // "price" may be returned as a JSON string OR a JSON number — handle both
        if let priceStr = json["price"] as? String {
            suggestion.price = priceStr
        } else if let priceNum = json["price"] as? NSNumber {
            suggestion.price = priceNum.stringValue
        }

        // priceDetails — prices are in their original/source currency; conversion happens in applyPriceConversion()
        if let rawPrices = json["priceDetails"] as? [[String: Any]] {
            var points: [AIPriceDataPoint] = []
            for p in rawPrices {
                guard let price = p["price"] as? String, !price.isEmpty else { continue }
                let source = p["source"] as? String ?? ""
                let url    = p["url"]    as? String ?? ""
                points.append(AIPriceDataPoint(source: source, url: url, price: price, originalPrice: nil))
            }
            suggestion.priceDetails = points
        }

        // drinkingWindowDetails
        if let rawWindows = json["drinkingWindowDetails"] as? [[String: Any]] {
            var points: [AIDrinkingWindowDataPoint] = []
            for w in rawWindows {
                guard let readyYear = w["readyYear"] as? String, !readyYear.isEmpty else { continue }
                let source         = w["source"]        as? String ?? ""
                let url            = w["url"]           as? String ?? ""
                let bestBefore     = w["bestBeforeYear"] as? String ?? ""
                points.append(AIDrinkingWindowDataPoint(source: source, url: url, readyYear: readyYear, bestBeforeYear: bestBefore))
            }
            suggestion.drinkingWindowDetails = points
        }

        // Sources: prefer explicit JSON array; fall back to annotation-derived sources
        if let rawSources = json["sources"] as? [[String: Any]] {
            var jsonSources: [AISearchSource] = []
            for s in rawSources {
                guard let url = s["url"] as? String, !url.isEmpty else { continue }
                let title = s["title"] as? String ?? url
                if !jsonSources.contains(where: { $0.url == url }) {
                    jsonSources.append(AISearchSource(title: title, url: url))
                }
            }
            // Merge with any annotation sources that aren't already listed
            var merged = jsonSources
            for src in annotationSources where !merged.contains(where: { $0.url == src.url }) {
                merged.append(src)
            }
            suggestion.sources = merged
        } else {
            suggestion.sources = annotationSources
        }

        return suggestion
    }

    // MARK: - Currency conversion

    /// Parses a price string like "EUR 18.90" or "18.90" into (currencyCode, amount).
    private func parsePriceString(_ raw: String) -> (currency: String, amount: Double)? {
        let parts = raw.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
        if parts.count >= 2,
           parts[0].count == 3,
           parts[0] == parts[0].uppercased(),
           let amount = Double(parts[1...].joined(separator: "").replacingOccurrences(of: ",", with: ".")) {
            return (parts[0].uppercased(), amount)
        }
        // Fallback: bare number without a currency code — cannot convert, return nil
        return nil
    }

    /// Fetches the exchange rate from `from` currency to `to` currency using
    /// the free Frankfurter API (https://www.frankfurter.app). No API key required.
    /// Returns 1.0 if the currencies are the same or if the request fails.
    private func fetchExchangeRate(from: String, to: String) async -> Double {
        guard from != to else { return 1.0 }
        let urlStr = "https://api.frankfurter.app/latest?from=\(from)&to=\(to)"
        guard let url = URL(string: urlStr) else { return 1.0 }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rates = json["rates"] as? [String: Any],
              let rate = rates[to] as? Double else { return 1.0 }
        return rate
    }

    /// Converts all prices in the suggestion to `targetCurrencyCode` using live exchange rates.
    /// Updates each AIPriceDataPoint and recalculates the average `suggestion.price`.
    private func applyPriceConversion(to suggestion: inout AIWineSuggestion, targetCurrencyCode: String) async {
        guard !suggestion.priceDetails.isEmpty else {
            // No priceDetails — attempt a best-effort conversion of the bare price field
            if let rawPrice = suggestion.price,
               let amount = Double(rawPrice.replacingOccurrences(of: ",", with: ".")),
               amount > 0 {
                // Nothing to convert without knowing the source currency — leave as-is
                _ = amount
            }
            return
        }

        // Cache exchange rates so we don't make duplicate calls
        var rateCache: [String: Double] = [:]

        var convertedPoints: [AIPriceDataPoint] = []
        var convertedAmounts: [Double] = []

        for point in suggestion.priceDetails {
            guard let parsed = parsePriceString(point.price) else {
                convertedPoints.append(point)
                continue
            }
            let sourceCurrency = parsed.currency
            let sourceAmount   = parsed.amount

            if sourceCurrency == targetCurrencyCode {
                // Already in the right currency
                let formatted = String(format: "%@ %.2f", targetCurrencyCode, sourceAmount)
                convertedPoints.append(AIPriceDataPoint(
                    source: point.source, url: point.url,
                    price: formatted, originalPrice: nil
                ))
                convertedAmounts.append(sourceAmount)
            } else {
                // Need conversion — fetch rate (cached)
                if rateCache[sourceCurrency] == nil {
                    rateCache[sourceCurrency] = await fetchExchangeRate(from: sourceCurrency, to: targetCurrencyCode)
                }
                let rate = rateCache[sourceCurrency] ?? 1.0
                let converted = sourceAmount * rate
                let convertedFormatted  = String(format: "%@ %.2f", targetCurrencyCode, converted)
                let originalFormatted   = String(format: "%@ %.2f", sourceCurrency, sourceAmount)
                convertedPoints.append(AIPriceDataPoint(
                    source: point.source, url: point.url,
                    price: convertedFormatted, originalPrice: originalFormatted
                ))
                convertedAmounts.append(converted)
            }
        }

        suggestion.priceDetails = convertedPoints

        // Recalculate average from the now-converted amounts
        if !convertedAmounts.isEmpty {
            let avg = convertedAmounts.reduce(0, +) / Double(convertedAmounts.count)
            suggestion.price = String(format: "%.1f", avg)
        }
    }
}
