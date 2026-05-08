import SwiftUI

struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var vm
    @State private var showsSettings = false

    var body: some View {
        if showsSettings {
            SettingsView(onDismiss: { showsSettings = false })
        } else {
            if !vm.hasAPIKey && !vm.isFirstLoad {
                onboardingView
            } else {
                mainContent
            }
        }
    }

    private var onboardingView: some View {
        ZStack {
            appBackground

            VStack(spacing: 18) {
                DeepSeekWhaleMark(animated: true)
                    .frame(width: 86, height: 86)
                    .padding(.top, 10)

                VStack(spacing: 6) {
                    Text("DeepSeek Monitor")
                        .font(.system(size: 22, weight: .bold))
                    Text("Let the little whale keep an eye on your balance.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    TextField("sk-...", text: Binding(
                        get: { vm.onboardingKey },
                        set: { vm.onboardingKey = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .onSubmit { Task { await vm.connectOnboarding() } }

                    Button {
                        Task { await vm.connectOnboarding() }
                    } label: {
                        HStack(spacing: 7) {
                            if vm.isLoading {
                                ProgressView()
                                    .scaleEffect(0.72)
                            } else {
                                Image(systemName: "sparkle.magnifyingglass")
                            }
                            Text("Connect")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(vm.onboardingKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.whaleStroke)
                )
                .padding(.horizontal, 22)

                if let error = vm.sectionErrors["_global"] {
                    errorMessage(error)
                }
            }
            .padding(.vertical, 18)
        }
    }

    private var mainContent: some View {
        ZStack {
            appBackground

            VStack(spacing: 0) {
                headerView

                if let error = vm.sectionErrors["_global"] {
                    errorBanner(error)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }

                VStack(spacing: 14) {
                    BalanceDisplay(
                        balance: vm.balance,
                        hasAPIKey: vm.hasAPIKey
                    )

                    if vm.isLoading {
                        HStack(spacing: 7) {
                            ProgressView()
                                .scaleEffect(0.72)
                            Text("Refreshing")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    statusStrip
                }
                .padding(14)

                Spacer(minLength: 0)
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 10) {
            DeepSeekWhaleMark(compact: true)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text("DeepSeek Monitor")
                    .font(.system(size: 13, weight: .bold))
                if let last = vm.lastUpdated {
                    Text("Updated \(last.relativeTimeString)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text(vm.hasAPIKey ? "Ready to refresh" : "Waiting for API key")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button {
                Task { await vm.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .disabled(vm.isLoading)
            .help("Refresh")

            Button {
                showsSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var statusStrip: some View {
        HStack(spacing: 0) {
            Label("Every \(vm.refreshIntervalText)", systemImage: "clock")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            if vm.hasAPIKey {
                HStack(spacing: 5) {
                    Circle()
                        .fill(.green)
                        .frame(width: 5, height: 5)
                    Text("Connected")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                }
            } else {
                Label("No key", systemImage: "key")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.whalePanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.whaleStroke)
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Button("Dismiss") {
                vm.sectionErrors["_global"] = nil
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.yellow.opacity(0.22))
        )
    }

    private func errorMessage(_ message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.caption)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
    }

    private var appBackground: some View {
        Color.whaleSurface
        .ignoresSafeArea()
    }
}
