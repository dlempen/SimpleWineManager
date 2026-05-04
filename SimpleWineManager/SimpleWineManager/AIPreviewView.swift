import SwiftUI

/// Shows the AI-suggested fields to the user before applying them.
/// Only fields that are currently EMPTY and have an AI value are shown.
struct AIPreviewView: View {

    let suggestion: AIWineSuggestion

    // Current values (used to determine which fields are empty)
    let currentName: String
    let currentProducer: String
    let currentVintage: String
    let currentAlcohol: String
    let currentGrapes: String
    let currentPrice: String
    let currentCountry: String
    let currentRegion: String
    let currentSubregion: String
    let currentType: String
    let currentCategory: String
    let currentReadyToTrinkYear: String
    let currentBestBeforeYear: String
    let currentRemarks: String
    /// Currency symbol to display next to the suggested price (e.g. "€", "$")
    let currencySymbol: String

    /// Called with `true` if user tapped "Apply", `false` if "Discard".
    var onDismiss: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed list of fillable fields

    private struct SuggestedField: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    private var fields: [SuggestedField] {
        var result: [SuggestedField] = []

        func add(_ label: String, current: String, suggested: String?) {
            if current.trimmingCharacters(in: .whitespaces).isEmpty,
               let v = suggested, !v.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append(SuggestedField(label: label, value: v))
            }
        }

        add("Producer",         current: currentProducer,         suggested: suggestion.producer)
        add("Vintage",          current: currentVintage,          suggested: suggestion.vintage)
        add("Alcohol",          current: currentAlcohol,          suggested: suggestion.alcohol.map { "\($0)%" })
        add("Grapes",           current: currentGrapes,           suggested: suggestion.grapes)
        add("Price",            current: currentPrice,            suggested: suggestion.price.map { "\($0) \(currencySymbol)" })
        add("Category",         current: currentCategory == "Red" ? "" : currentCategory,
                                suggested: suggestion.category)
        add("Country",          current: currentCountry,          suggested: suggestion.country)
        add("Region",           current: currentRegion,           suggested: suggestion.region)
        add("Subregion",        current: currentSubregion,        suggested: suggestion.subregion)
        add("Type",             current: currentType,             suggested: suggestion.type)
        add("Drink from",       current: currentReadyToTrinkYear, suggested: suggestion.readyToTrinkYear)
        add("Best before",      current: currentBestBeforeYear,   suggested: suggestion.bestBeforeYear)
        add("Remarks",          current: currentRemarks,          suggested: suggestion.remarks)

        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if fields.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        Text("All fields are already filled in.")
                            .font(.headline)
                        Text("The AI did not find any additional information to add.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        Section(
                            header: Text("AI Suggestions"),
                            footer: Text("These fields are empty and will be filled with the AI suggestions above. Tap \u{201C}Apply\u{201D} to confirm, or \u{201C}Discard\u{201D} to cancel.")
                        ) {
                            ForEach(fields) { field in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "sparkle")
                                        .foregroundColor(.purple)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(field.label)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(field.value)
                                            .font(.body)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("AI Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        onDismiss(false)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onDismiss(true)
                        dismiss()
                    }
                    .disabled(fields.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
