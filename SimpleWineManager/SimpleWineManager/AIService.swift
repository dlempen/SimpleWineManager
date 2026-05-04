import Foundation

// MARK: - AI Provider

enum AIProvider: String, CaseIterable, Codable {
    case openAI    = "OpenAI"
    case anthropic = "Anthropic Claude"
    case gemini    = "Google Gemini"

    /// Hint text displayed below the API key field in Settings.
    var apiKeyHint: String {
        switch self {
        case .openAI:    return "Get your key at platform.openai.com"
        case .anthropic: return "Get your key at console.anthropic.com"
        case .gemini:    return "Get your key at aistudio.google.com"
        }
    }

    /// SF Symbol name used as an icon in the provider picker.
    var systemImageName: String {
        switch self {
        case .openAI:    return "brain"
        case .anthropic: return "sparkles"
        case .gemini:    return "globe"
        }
    }
}

// MARK: - AI Search Source (web citation)

struct AISearchSource: Identifiable {
    let id = UUID()
    let title: String
    let url: String
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
        provider: AIProvider
    ) async throws -> AIWineSuggestion {

        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.notConfigured
        }

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty ||
              !producer.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.noUsefulFields
        }

        switch provider {
        case .openAI:
            // Hardcoded: gpt-4o-mini-search-preview with web search enabled
            let prompt = buildPrompt(
                name: name, producer: producer, vintage: vintage,
                alcohol: alcohol, grapes: grapes, country: country,
                region: region, subregion: subregion, type: type,
                category: category, readyToTrinkYear: readyToTrinkYear,
                bestBeforeYear: bestBeforeYear, remarks: remarks,
                currency: currency
            )
            let (responseText, sources) = try await callOpenAIChatAPI(prompt: prompt, apiKey: apiKey)
            return parseSuggestion(from: responseText, sources: sources)

        case .anthropic:
            // TODO: Implement Anthropic Claude support.
            // Endpoint: POST https://api.anthropic.com/v1/messages
            // Headers: x-api-key: <key>, anthropic-version: 2023-06-01, content-type: application/json
            // Body: { "model": "claude-opus-4-5", "max_tokens": 600,
            //         "messages": [{ "role": "user", "content": prompt }] }
            // Response: json["content"][0]["text"]
            throw AIServiceError.providerNotYetSupported("Anthropic Claude")

        case .gemini:
            // TODO: Implement Google Gemini support.
            // Endpoint: POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=<key>
            // Headers: content-type: application/json
            // Body: { "contents": [{ "parts": [{ "text": prompt }] }] }
            // Response: json["candidates"][0]["content"]["parts"][0]["text"]
            throw AIServiceError.providerNotYetSupported("Google Gemini")
        }
    }

    // MARK: - Private helpers

    private func buildPrompt(
        name: String, producer: String, vintage: String,
        alcohol: String, grapes: String, country: String,
        region: String, subregion: String, type: String,
        category: String, readyToTrinkYear: String,
        bestBeforeYear: String, remarks: String,
        currency: String
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

        // Extract just the currency code for the prompt (e.g. "EUR" from "EUR (€)")
        let currencyCode: String
        if let spaceIdx = currency.firstIndex(of: " ") {
            currencyCode = String(currency[currency.startIndex..<spaceIdx])
        } else {
            currencyCode = currency
        }

        return """
You are a wine expert assistant. Based on the information provided about a wine, fill in as many of the MISSING fields as possible.

You have access to real-time web search. Use it to look up the current average retail price.

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
  "remarks": "Brief tasting notes or interesting facts about this wine."
}

Rules:
- "vintage" must be a 4-digit year string (e.g. "2019") or omit.
- "alcohol" must be a number only, no % sign (e.g. "13.5") or omit.
- "readyToTrinkYear" and "bestBeforeYear" must be 4-digit year strings or omit.
- "category" must be one of: Red, White, Rosé, Sparkling, Dessert, Port.
- "price" must be the average retail price in \(currencyCode), as a plain number only (no currency symbol, no spaces). Example: "24.50". If you cannot find a reliable price, omit this field.
- Only include fields that are MISSING from the known information above.
"""
    }

    private func callOpenAIChatAPI(
        prompt: String,
        apiKey: String
    ) async throws -> (content: String, sources: [AISearchSource]) {
        let baseURL = "https://api.openai.com/v1"
        let model   = "gpt-4o-mini-search-preview"

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIServiceError.networkError("Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60   // web search calls take longer

        // temperature is not supported on search-preview models — omit it entirely.
        // web_search_options is the top-level parameter for Chat Completions web search;
        // NOT a custom tool. Only search-preview models support it.
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful wine expert. You respond only with valid JSON."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 600,
            "web_search_options": ["search_context_size": "medium"]
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

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }

        // Extract web search citations from annotations (OpenAI search-preview models)
        var sources: [AISearchSource] = []
        if let annotations = message["annotations"] as? [[String: Any]] {
            for annotation in annotations {
                if let urlCitation = annotation["url_citation"] as? [String: Any],
                   let urlStr = urlCitation["url"] as? String {
                    let title = urlCitation["title"] as? String ?? urlStr
                    sources.append(AISearchSource(title: title, url: urlStr))
                }
            }
        }

        return (content, sources)
    }

    private func parseSuggestion(from text: String, sources: [AISearchSource]) -> AIWineSuggestion {
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
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return suggestion
        }

        suggestion.producer        = json["producer"]
        suggestion.vintage         = json["vintage"]
        suggestion.alcohol         = json["alcohol"]
        suggestion.grapes          = json["grapes"]
        suggestion.country         = json["country"]
        suggestion.region          = json["region"]
        suggestion.subregion       = json["subregion"]
        suggestion.type            = json["type"]
        suggestion.category        = json["category"]
        suggestion.readyToTrinkYear = json["readyToTrinkYear"]
        suggestion.bestBeforeYear  = json["bestBeforeYear"]
        suggestion.remarks         = json["remarks"]
        suggestion.price           = json["price"]
        suggestion.sources         = sources

        return suggestion
    }
}
