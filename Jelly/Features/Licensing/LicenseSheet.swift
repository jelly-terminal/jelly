import AppKit
import SwiftUI

struct LicenseSheet: View {
    let license: LicenseService
    let title: String
    var message: String?
    let dismissTitle: String
    let onActivated: () -> Void
    let onDismiss: () -> Void

    @State private var key = ""
    @State private var error: String?
    @State private var isVerifying = false

    var body: some View {
        VStack(spacing: Metrics.dialogSpacing) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: Metrics.dialogIconSize, height: Metrics.dialogIconSize)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                if let message {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 6) {
                TextField("License key", text: $key)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.large)
                    .disableAutocorrection(true)
                    .onSubmit(activate)

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: Metrics.dialogButtonSpacing) {
                Button(action: activate) {
                    ZStack {
                        Text("Activate").opacity(isVerifying ? 0 : 1)
                        if isVerifying {
                            ProgressView().controlSize(.small)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.glassProminent)
                .disabled(isVerifying || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    NSWorkspace.shared.open(AppInfo.gumroadProductURL)
                } label: {
                    Text("Buy a License").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)

                Button(role: .cancel, action: onDismiss) {
                    Text(dismissTitle).frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.glass)
            }
            .controlSize(.large)
            .padding(.top, 4)
        }
        .padding(Metrics.dialogPadding)
        .frame(width: Metrics.dialogWidth)
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
