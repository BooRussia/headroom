import SwiftUI

struct SettingsView: View {
    @ObservedObject var usageService: UsageService
    @State private var cookieInput = ""
    @State private var refreshSeconds = 60.0
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Section("Session Cookie") {
                Text("Copy your `sessionKey` from claude.ai (DevTools → Application → Cookies).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("sessionKey value or full cookie", text: $cookieInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save Cookie") {
                        usageService.saveCookie(cookieInput)
                        cookieInput = ""
                    }
                    .disabled(cookieInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Clear", role: .destructive) {
                        usageService.clearCookie()
                        cookieInput = ""
                    }
                    .disabled(!usageService.hasCookie)
                }
            }

            Section("Refresh") {
                Slider(value: $refreshSeconds, in: 30...300, step: 30) {
                    Text("Poll every \(Int(refreshSeconds))s")
                }
                .onChange(of: refreshSeconds) { newValue in
                    usageService.updateRefreshInterval(seconds: newValue)
                }
            }

            Section("Notifications") {
                Text("Warnings at 75%, 85%, 90%, and 95%. Exact reset alerts fire at the scheduled reset time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        LaunchAtLoginService.setEnabled(enabled)
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 360)
        .onAppear {
            refreshSeconds = usageService.refreshInterval
            launchAtLogin = LaunchAtLoginService.isEnabled()
        }
    }
}
