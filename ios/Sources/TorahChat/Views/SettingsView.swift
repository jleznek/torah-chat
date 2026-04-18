import SwiftUI

struct SettingsView: View {
    @Environment(ChatViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProviderId: String = ""
    @State private var selectedModelId: String = ""
    @State private var apiKeyInput: String = ""
    @State private var showKey = false
    @State private var validating = false
    @State private var validationResult: ValidationResult? = nil
    @State private var responseLength: String = "balanced"

    private enum ValidationResult {
        case valid, invalid(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Provider picker
                Section("AI Provider") {
                    Picker("Provider", selection: $selectedProviderId) {
                        ForEach(vm.availableProviders) { provider in
                            Text(provider.name).tag(provider.id)
                        }
                    }
                    .onChange(of: selectedProviderId) {
                        updateModelToDefault()
                        loadExistingKey()
                    }

                    if let provider = currentProvider {
                        Picker("Model", selection: $selectedModelId) {
                            ForEach(provider.models) { model in
                                Text(model.name).tag(model.id)
                            }
                        }
                    }
                }

                // API Key
                if currentProvider?.requiresKey == true {
                    Section {
                        HStack {
                            if showKey {
                                TextField("API Key", text: $apiKeyInput)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("API Key", text: $apiKeyInput)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            Button {
                                showKey.toggle()
                            } label: {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if case .valid = validationResult {
                            Label("Key is valid", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if case .invalid(let msg) = validationResult {
                            Label(msg, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }

                        HStack {
                            Button("Validate Key") {
                                Task { await validateKey() }
                            }
                            .disabled(apiKeyInput.isEmpty || validating)

                            if validating {
                                Spacer()
                                ProgressView()
                            }
                        }

                        if let provider = currentProvider {
                            Link("Get an API key — \(provider.keyHelpLabel)",
                                 destination: URL(string: provider.keyHelpURL)!)
                                .font(.caption)
                        }
                    } header: {
                        Text("API Key")
                    } footer: {
                        Text("Keys are stored securely in the iOS Keychain and never leave your device.")
                    }

                    if vm.hasKey(forProvider: selectedProviderId) {
                        Section {
                            Button(role: .destructive) {
                                vm.removeProviderKey(providerId: selectedProviderId)
                                apiKeyInput = ""
                                validationResult = nil
                            } label: {
                                Label("Remove Saved Key", systemImage: "trash")
                            }
                        }
                    }
                }

                // Response length
                Section("Response Length") {
                    Picker("Length", selection: $responseLength) {
                        Text("Concise").tag("concise")
                        Text("Balanced").tag("balanced")
                        Text("Detailed").tag("detailed")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                }
            }
        }
        .onAppear { loadCurrentState() }
    }

    // MARK: - Helpers

    private var currentProvider: ProviderInfo? {
        vm.availableProviders.first { $0.id == selectedProviderId }
    }

    private func loadCurrentState() {
        selectedProviderId = vm.selectedProviderId
        selectedModelId    = vm.selectedModelId
        responseLength     = vm.settings.responseLength
        loadExistingKey()
    }

    private func loadExistingKey() {
        apiKeyInput = vm.apiKey(forProvider: selectedProviderId)
        validationResult = nil
    }

    private func updateModelToDefault() {
        selectedModelId = currentProvider?.defaultModel ?? ""
    }

    private func validateKey() async {
        validating = true
        validationResult = nil
        let key = apiKeyInput
        let pid = selectedProviderId
        let mid = selectedModelId
        guard let provider = createProvider(providerId: pid, apiKey: key, model: mid) else {
            validationResult = .invalid("Unknown provider")
            validating = false
            return
        }
        let ok = await provider.validateKey()
        validationResult = ok ? .valid : .invalid("Key rejected by provider")
        validating = false
    }

    private func save() {
        vm.settings.responseLength = responseLength
        vm.saveProviderConfig(
            providerId: selectedProviderId,
            modelId: selectedModelId,
            apiKey: apiKeyInput.isEmpty ? nil : apiKeyInput
        )
        dismiss()
    }
}
