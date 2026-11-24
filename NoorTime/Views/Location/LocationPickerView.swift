import SwiftUI

/// Sheet where the user chooses GPS or a city from the list.
struct LocationPickerView: View {
    @ObservedObject var location: LocationController

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                currentLocationSection
                citiesSection
            }
            .navigationTitle(Text("location.title"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: Text("location.search"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .onAppear { location.refreshAuthorization() }
            // The user may come back from iOS Settings after allowing location.
            .onChange(of: scenePhase) { phase in
                if phase == .active { location.refreshAuthorization() }
            }
        }
    }

    // MARK: - GPS

    private var isLocating: Bool {
        location.requestState == .locating
    }

    private var currentLocationSection: some View {
        Section {
            Button {
                Task {
                    await location.useCurrentLocation()
                    if location.requestState == .idle {
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    Label {
                        Text("location.useCurrent")
                    } icon: {
                        Image(systemName: "location.fill")
                    }
                    Spacer()
                    if isLocating {
                        ProgressView()
                    }
                }
            }
            .disabled(isLocating)

            if let message = statusMessageKey {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(NTColor.textSecondary)
            }

            if showsSettingsButton {
                Button("location.openSettings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
        } footer: {
            Text("location.hint")
        }
    }

    private var statusMessageKey: LocalizedStringKey? {
        if isLocating {
            return "location.locating"
        }
        if case .failed(let error) = location.requestState {
            switch error {
            case .permissionDenied: return "location.status.denied"
            case .permissionRestricted: return "location.status.restricted"
            case .unavailable, .timeout: return "location.status.failed"
            }
        }
        switch location.authorization {
        case .denied: return "location.status.denied"
        case .restricted: return "location.status.restricted"
        case .notDetermined, .authorized: return nil
        }
    }

    private var showsSettingsButton: Bool {
        if case .failed(.permissionDenied) = location.requestState { return true }
        return location.authorization == .denied
    }

    // MARK: - City list

    private var filteredCities: [City] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return location.cities }
        return location.cities.filter {
            $0.nameEn.localizedCaseInsensitiveContains(query) || $0.nameBn.contains(query)
        }
    }

    private var citiesSection: some View {
        Section(header: Text("location.chooseCity")) {
            ForEach(filteredCities) { city in
                Button {
                    location.select(city: city)
                    dismiss()
                } label: {
                    HStack {
                        Text(verbatim: city.displayName(languageCode: AppLanguage.code))
                            .foregroundStyle(NTColor.textPrimary)
                        Spacer()
                        if location.place.cityID == city.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(NTColor.emerald)
                        }
                    }
                }
            }
        }
    }
}
