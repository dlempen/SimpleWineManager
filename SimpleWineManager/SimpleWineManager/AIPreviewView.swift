import SwiftUI

// MARK: - AIPreviewView

/// Shows AI-suggested fields with individual checkboxes so the user can
/// choose exactly which values to accept before pressing "Apply".
/// A "Sources" section at the bottom shows the web citations returned by the API.
struct AIPreviewView: View {

    let suggestion: AIWineSuggestion

    // Current values (used to determine which fields are still empty)
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
    /// Currency symbol shown next to the suggested price (e.g. "€", "$")
    let currencySymbol: String

    /// Called with a filtered AIWineSuggestion containing only the checked fields,
    /// or nil if the user tapped "Discard".
    var onDismiss: (AIWineSuggestion?) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Candidate field model

    private struct CandidateField: Identifiable {
        let id: String        // unique key matching AIWineSuggestion field name
        let label: String
        let icon: String      // SF Symbol
        let value: String
    }

    // MARK: - State

    @State private var checked: Set<String> = []

    // MARK: - Candidate list (only empty fields that the AI filled)

    private var candidates: [CandidateField] {
        var result: [CandidateField] = []

        func add(id: String, label: String, icon: String, current: String, suggested: String?) {
            if current.trimmingCharacters(in: .whitespaces).isEmpty,
               let v = suggested, !v.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append(CandidateField(id: id, label: label, icon: icon, value: v))
            }
        }

        add(id: "producer",         label: "Producer",    icon: "person.fill",         current: currentProducer,         suggested: suggestion.producer)
        add(id: "vintage",          label: "Vintage",     icon: "calendar",             current: currentVintage,          suggested: suggestion.vintage)
        add(id: "alcohol",          label: "Alcohol",     icon: "percent",              current: currentAlcohol,          suggested: suggestion.alcohol.map { "\($0)%" })
        add(id: "grapes",           label: "Grapes",      icon: "leaf.fill",            current: currentGrapes,           suggested: suggestion.grapes)
        add(id: "price",            label: "Price",       icon: "tag.fill",             current: currentPrice,            suggested: suggestion.price.map { "\($0) \(currencySymbol)" })
        add(id: "category",         label: "Category",    icon: "square.grid.2x2.fill",
            current: currentCategory == "Red" ? "" : currentCategory, suggested: suggestion.category)
        add(id: "country",          label: "Country",     icon: "globe",                current: currentCountry,          suggested: suggestion.country)
        add(id: "region",           label: "Region",      icon: "map.fill",             current: currentRegion,           suggested: suggestion.region)
        add(id: "subregion",        label: "Subregion",   icon: "mappin.and.ellipse",   current: currentSubregion,        suggested: suggestion.subregion)
        add(id: "type",             label: "Type",        icon: "list.bullet",          current: currentType,             suggested: suggestion.type)
        add(id: "readyToTrinkYear", label: "Drink from",  icon: "clock.fill",           current: currentReadyToTrinkYear, suggested: suggestion.readyToTrinkYear)
        add(id: "bestBeforeYear",   label: "Best before", icon: "hourglass",            current: currentBestBeforeYear,   suggested: suggestion.bestBeforeYear)
        add(id: "remarks",          label: "Remarks",     icon: "text.bubble.fill",     current: currentRemarks,          suggested: suggestion.remarks)

        return result
    }

    // MARK: - Helpers

    private var applyIsDisabled: Bool { candidates.isEmpty || checked.isEmpty }
    private var allSelected: Bool { !candidates.isEmpty && checked.count == candidates.count }

    private func initialiseChecked() {
        checked = Set(candidates.map(\.id))
    }

    private func filteredSuggestion() -> AIWineSuggestion {
        var s = AIWineSuggestion()
        if checked.contains("producer")         { s.producer         = suggestion.producer }
        if checked.contains("vintage")          { s.vintage          = suggestion.vintage }
        if checked.contains("alcohol")          { s.alcohol          = suggestion.alcohol }
        if checked.contains("grapes")           { s.grapes           = suggestion.grapes }
        if checked.contains("price")            { s.price            = suggestion.price }
        if checked.contains("category")         { s.category         = suggestion.category }
        if checked.contains("country")          { s.country          = suggestion.country }
        if checked.contains("region")           { s.region           = suggestion.region }
        if checked.contains("subregion")        { s.subregion        = suggestion.subregion }
        if checked.contains("type")             { s.type             = suggestion.type }
        if checked.contains("readyToTrinkYear") { s.readyToTrinkYear = suggestion.readyToTrinkYear }
        if checked.contains("bestBeforeYear")   { s.bestBeforeYear   = suggestion.bestBeforeYear }
        if checked.contains("remarks")          { s.remarks          = suggestion.remarks }
        s.sources = suggestion.sources
        return s
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if candidates.isEmpty {
                    emptyState
                } else {
                    suggestionList
                }
            }
            .navigationTitle("AI Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        onDismiss(nil)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onDismiss(filteredSuggestion())
                        dismiss()
                    }
                    .disabled(applyIsDisabled)
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear { initialiseChecked() }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            Text("Nothing new to fill in")
                .font(.headline)
            Text("All fields are already filled in. The AI did not find any additional information to add.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }

    private var suggestionList: some View {
        List {
            // Select / Deselect all
            Section {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if allSelected {
                            checked.removeAll()
                        } else {
                            checked = Set(candidates.map(\.id))
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(allSelected ? .purple : .secondary)
                            .font(.title3)
                        Text(allSelected ? "Deselect all" : "Select all")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(checked.count) of \(candidates.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            // Individual field rows
            Section(
                header: Text("Suggested values"),
                footer: Text("Tap a row to toggle it. Only checked fields will be applied.")
                    .font(.caption)
            ) {
                ForEach(candidates) { field in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if checked.contains(field.id) {
                                checked.remove(field.id)
                            } else {
                                checked.insert(field.id)
                            }
                        }
                    } label: {
                        fieldRow(field)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Web search sources
            if !suggestion.sources.isEmpty {
                Section(
                    header: HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                        Text("Web sources")
                    },
                    footer: Text("These pages were consulted by the AI to look up pricing and wine details.")
                        .font(.caption)
                ) {
                    ForEach(suggestion.sources) { source in
                        sourceRow(source)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func fieldRow(_ field: CandidateField) -> some View {
        let isOn = checked.contains(field.id)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isOn ? .purple : Color(.systemGray3))
                .font(.title3)
                .frame(width: 26)

            HStack(alignment: .center, spacing: 8) {
                Image(systemName: field.icon)
                    .foregroundColor(.purple.opacity(0.7))
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(field.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(field.value)
                        .font(.body)
                        .foregroundColor(isOn ? .primary : Color(.systemGray3))
                        .strikethrough(!isOn, color: Color(.systemGray3))
                }
            }
            Spacer()
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }

    private func sourceRow(_ source: AISearchSource) -> some View {
        Link(destination: URL(string: source.url) ?? URL(string: "https://example.com")!) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "safari.fill")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 3) {
                    Text(source.title)
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(source.url)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
    }
}
