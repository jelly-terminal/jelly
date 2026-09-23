import AppKit
import JellyCore
import SwiftUI

struct LicenseSheet: View {
    let license: LicenseService
    var cancelTitle: String?
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
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
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
                    Text(cancelTitle ?? dismissTitle).frame(maxWidth: .infinity)
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

    private var title: String {
        license.status == .trialExpired ? "Your trial has ended" : "Activate \(AppInfo.name)"
    }

    private var message: String {
        switch license.status {
        case .trialExpired: "Buy a license to keep using \(AppInfo.name), then enter the key from your purchase email."
        default: "Enter the license key from your purchase email, or buy one to keep using \(AppInfo.name) after the trial."
        }
    }

    private var dismissTitle: String {
        switch license.status {
        case .trial(let daysRemaining): daysRemaining == 1 ? "Continue Trial (1 day)" : "Continue Trial (\(daysRemaining) days)"
        case .trialExpired: "Quit"
        case .licensed: "Cancel"
        }
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
