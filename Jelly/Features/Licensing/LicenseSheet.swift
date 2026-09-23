import AppKit
import SwiftUI

struct LicenseSheet: View {
    let license: LicenseService
    var reason: String?
    let dismissTitle: String
    let onActivated: () -> Void
    let onDismiss: () -> Void

    @State private var key = ""
    @State private var error: String?
    @State private var isVerifying = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activate \(AppInfo.name)")
                        .font(.headline)
                    if let reason {
                        Text(reason)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            TextField("License key", text: $key)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .onSubmit(activate)

            if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            HStack {
                Button("Buy a License") { NSWorkspace.shared.open(AppInfo.gumroadProductURL) }
                Spacer()
                Button(dismissTitle, role: .cancel, action: onDismiss)
                    .keyboardShortcut(.cancelAction)
                Button(action: activate) {
                    if isVerifying {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Activate")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.glassProminent)
                .disabled(isVerifying || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func activate() {
        guard !isVerifying else { return }
        isVerifying = true
        error = nil
        Task {
            let message = await license.activate(key: key)
            isVerifying = false
            if let message {
                error = message
            } else {
                onActivated()
            }
        }
    }
}
