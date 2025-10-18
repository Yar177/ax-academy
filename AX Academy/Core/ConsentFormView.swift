import SwiftUI

struct ConsentFormView: View {
    @ObservedObject var viewModel: AppShellViewModel
    @State private var analyticsAllowed: Bool
    @State private var recommendationsAllowed: Bool
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AppShellViewModel) {
        self.viewModel = viewModel
        _analyticsAllowed = State(initialValue: viewModel.consentState.analyticsAllowed)
        _recommendationsAllowed = State(initialValue: viewModel.consentState.personalizedRecommendationsAllowed)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L10n.text("consent_section_data"))) {
                    Toggle(isOn: $analyticsAllowed) {
                        Text(L10n.text("consent_analytics_toggle"))
                    }
                    Toggle(isOn: $recommendationsAllowed) {
                        Text(L10n.text("consent_recommendations_toggle"))
                    }
                    Text(L10n.text("consent_data_notice"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }

                Section(header: Text(L10n.text("consent_privacy_header"))) {
                    Text(L10n.text("consent_privacy_copy"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .navigationTitle(L10n.text("consent_title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("consent_cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("consent_save")) {
                        viewModel.updateConsent(analyticsAllowed: analyticsAllowed,
                                                recommendationsAllowed: recommendationsAllowed)
                        dismiss()
                    }
                }
            }
        }
    }
}
