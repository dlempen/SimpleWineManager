import Foundation

// MARK: - AI Provider

enum AIProvider: String, CaseIterable, Codable {
    case openAI = "OpenAI (ChatGPT)"
    case openAICompatible = "OpenAI-Compatible"

    var baseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .openAICompatible: return "" // user-supplied
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .openAICompatible: return "gpt-4o-mini"
        }
    }
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
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case notConfigured
    case noUsefulFields
    case networkError(String)
    case invalidResponse
    case apiError(String)

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
        apiKey: String,
        provider: AIProvider,
        customBaseURL: String,
        model: String
    ) async throws -> AIWineSuggestion {

        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.notConfigured
        }

        // Require at least name or producer
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty ||
              !producer.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIServiceError.noUsefulFields
        }

        let prompt = buildPrompt(
            name: name, producer: producer, vintage: vintage,
            alcohol: alcohol, grapes: grapes, country: country,
            region: region, subregion: subregion, type: type,
            category: category, readyToTrinkYear: readyToTrinkYear,
            bestBeforeYear: bestBeforeYear, remarks: remarks
        )

        let baseURL = provider == .openAICompatible
            ? customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            : provider.baseURL

        let responseText = try await callChatAPI(
            prompt: prompt,
            apiKey: apiKey,
            baseURL: baseURL,
            model: model.isEmpty ? provider.defaultModel : model
        )

        return parseSuggestion(from: responseText)
    }

    // MARK: - Private helpers

    private func buildPrompt(
        name: String, producer: String, vintage: String,
        alcohol: String, grapes: String, country: String,
        region: String, subregion: String, type: String,
        category: String, readyToTrinkYear: String,
        bestBeforeYear: String, remarks: String
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

        return """
You are a wine expert assistant. Based on the information provided about a wine, fill in as many of the MISSING fields as possible using your knowledge.

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
  "remarks": "Brief tasting notes or interesting facts about this wine."
}

Rules:
- "vintage" must be a 4-digit year string (e.g. "2019") or omit.
- "alcohol" must be a number only, no % sign (e.g. "13.5") or omit.
- "readyToTrinkYear" and "bestBeforeYear" must be 4-digit year strings or omit.
- "category" must be one of: Red, White, Rosé, Sparkling, Dessert, Port.
- Only include fields that are MISSING from the known information above.
"""
    }

    private func callChatAPI(
        prompt: String,
        apiKey: String,
        baseURL: String,
        model: String
    ) async throws -> String {

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIServiceError.networkError("Invalid API URL: \(baseURL)/chat/completions")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful wine expert. You respond only with valid JSON."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 500
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            // Try to extract error message
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

        return content
    }

    private func parseSuggestion(from text: String) -> AIWineSuggestion {
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

        return suggestion
    }
}
